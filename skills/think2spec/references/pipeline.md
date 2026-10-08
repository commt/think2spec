# Compile pipeline

Detail for `SKILL.md`. The compile step turns the plain prompt into a spec. It never does the task and never reads files or searches for the task.

## Steps

1. **Extract** intent, audience and deliverable from the plain prompt.
2. **Detect ambiguity.** For each gap, ask: would the answer change what gets built?
3. **Resolve.** If yes, ask the user, up to the configured `question_limit` (default 2) per compile request. With a limit of 0 nothing is asked and every gap is recorded as an assumption. More gaps than the limit: ask the ones that change the work most, record the rest as assumptions. If the answer would not change the work, record an explicit guess in `<assumptions>`. Each edit round is a new compile request and the limit resets.
4. **Extract stated requirements and constraints.** Only what the user stated or answered when asked. Answers to clarifying questions count as stated, not as assumed.
5. **Add task-type sections** the prompt calls for. For code: files, discovery, verification. For copy: tone, SEO, length, keywords. A task-type tag appears as its own tag only when it has stated content. When every item in it would be a guess, the tag is omitted and the guesses go in `<assumptions>` with a scope label.
6. **Apply saved rules.** Saved rules land in `<constraints>` (or the equivalent in the chosen format). A rule that conflicts with the prompt loses, and the override is shown in `<assumptions>`.
7. **Choose skills.** List every skill the user named. Add installed skills from the passed-in list that the compile model judges useful, each marked as suggested. Never list think2spec itself.
8. **Render** the spec in the configured format. The stated-content and assumptions rules are identical in XML, JSON and Markdown.
9. **Show the spec** and apply the approval mode (`SKILL.md`).

`<discovery>` is an instruction to the agent, carried out after approval. The compile step never searches the repository itself. A discovery step the user did not state is a guess and goes in `<assumptions>`.

## Who runs the compile

- Claude Code: a subagent, on the model from `config.json` (`model`). The subagent cannot talk to the user and sees none of the conversation, so the main session passes it everything through the input block.
- Model parameter: for `inherit`, omit the `model` parameter of the Agent/Task call. For `haiku`, `sonnet`, `opus` or `fable`, pass that alias. For a saved value starting with `claude-` (an older config or a hand edit), map it by family and pass the alias, with no error and no notice: `claude-haiku-*` to `haiku`, `claude-sonnet-*` to `sonnet`, `claude-opus-*` to `opus`, `claude-fable-*` to `fable`. If no family matches, omit the parameter (session model) and print one line: "Model <value> is not available for the compile step; using the session model. Run /think2spec config to pick haiku, sonnet, opus or fable." Never pass a full ID to the Agent tool.
- The subagent prompt is the full content of `references/compiler-prompt.md`, followed by the input block. Append the sentence "Use no tools of any kind, including the Skill tool. Everything you need is in the input below." (the compiler prompt already carries it).
- Tools without subagents (and the Gemini route): run the same steps on the host model and say so in one line. When one model both compiles and shows the result, the OUTPUT rule covers only the compile result; the one-line route note, the guesses label and the approval prompt are printed afterwards under the approval rules.

## Input block

Built by the main session on every call (first compile, answer round, edit round), in this order. Use the tags that `compiler-prompt.md` names.

1. `<raw_prompt>`: the raw prompt.
2. `<rules>`: the `rules.md` content (omit when no rules were loaded).
3. `<config>`: language, `spec_format`, `question_limit`, and `questions_remaining` (the limit minus the questions already asked in this compile request).
4. `<prior_spec>`: the prior spec, if one exists (answer and edit rounds).
5. `<user_edits>`: the user's edits, if any.
6. `<qa>`: the clarifying questions and answers so far.
7. `<available_skills>`: every installed skill, name plus one-line description, on every call. Omit the block when no list could be built; then only user-named skills appear.

### Building the skill list (field 7)

The main agent builds it, because the subagent has no tools.

1. Use the skills the host session already exposes (name plus one-line description).
2. If the session exposes none, read the `name` and `description` frontmatter of the `SKILL.md` files in the tool's known skill folders:
   Read only the folders for the tool you are running in. Each skill is `<folder>/<name>/SKILL.md`. Folders verified 2026-10-08 from each vendor's docs.

   | Tool | Project skill folders | Personal skill folders |
   |---|---|---|
   | Claude Code | `.claude/skills/` | `~/.claude/skills/` |
   | Codex | `.agents/skills/` | `~/.agents/skills/` |
   | Gemini CLI | `.gemini/skills/`, `.agents/skills/` | `~/.gemini/skills/`, `~/.agents/skills/` |
   | Copilot in VS Code | `.github/skills/`, `.claude/skills/`, `.agents/skills/` | `~/.copilot/skills/`, `~/.claude/skills/`, `~/.agents/skills/` |
   | Cursor | `.agents/skills/`, `.cursor/skills/` | `~/.agents/skills/`, `~/.cursor/skills/` |
   | Cline | `.cline/skills/`, `.clinerules/skills/`, `.claude/skills/` | `~/.cline/skills/` |
   | Windsurf | `.devin/skills/`, `.windsurf/skills/` | `~/.codeium/windsurf/skills/`, `~/.config/devin/skills/` |
   | OpenCode | `.opencode/skills/`, `.claude/skills/`, `.agents/skills/` | `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.agents/skills/` |
3. Include think2spec itself in the list. The compile model excludes it from `<skills>`.
4. Reading these folders may raise a permission prompt. If it is denied, or nothing can be listed, omit the block.

## Output and shape detection

The compile returns exactly one of two shapes:

- `<questions>` holding 1 to N `<question>` items, N being `questions_remaining`. This shape is XML in every spec format, an internal exchange only, never shown as the spec. It is not allowed when `questions_remaining` is 0.
- A complete spec in the configured format.

Detect the shape from the start of the output:

| Output starts with | Meaning |
|---|---|
| `<questions>` | Question shape. Ask the user, then start a new compile call with the answers added to `<qa>` and `questions_remaining` reduced. |
| `<spec version="1">` (xml), a JSON object with a top-level `"spec"` holding `"version": 1` (json), first line `# Spec v1` (markdown) | A valid spec, checked against the configured format. Print it as received, not converted, and apply the approval mode. |
| Anything else, or a root shape that does not match the configured format | Failed compile. Tell the user, show no spec, execute nothing in any approval mode, offer to retry. Never treat it as a spec or as approval. |

Stray text before or after the spec makes the output invalid. Do not trim and accept it.

The question limit counts per compile request across all clarifying rounds. When no questions remain, the next call must return a spec.

## Judging the big-change test

Used by `ask_when_big` (see `SKILL.md`).

- Built-in criteria: the main session judges them on the compiled spec, for the criteria switched on in `big_change_criteria`. Files are counted from what the spec lists or assumes. "Overwrites" means deleting a file or replacing its whole content; an in-place edit does not count.
- Suggested skills never trip any criterion and never count as assumptions.
- Custom description (`big_change_custom`, non-empty only): a separate call on the configured compile model (same model rules as above), given the spec and the description, asking whether the spec matches it, answer yes or no. The judge call carries the same no-tools sentence. Its prompt, exactly:

```
Use no tools of any kind, including the Skill tool. Everything you need is in the input below.
Answer with the single word yes or no, and nothing else.
Does the spec match the description?
<description>
(the big_change_custom text)
</description>
<spec>
(the compiled spec)
</spec>
```

An answer that starts with "yes" (ignoring case and surrounding whitespace) counts as big. Anything else counts as not big. A failed or empty judge call counts as not big for the custom description only, and the main session says so in one line. The built-in criteria are still applied.

When `model` is `inherit` the session model judges. Empty text never matches.
