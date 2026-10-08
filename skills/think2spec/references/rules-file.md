# Settings files, first-run Q&A and config

Detail for `SKILL.md`. Two global files live under `~/.config/think2spec/` (on Windows `%USERPROFILE%\.config\think2spec\`). There is no per-project file and no workspace fallback: no per-project rules file is ever read.

- `config.json`: machine settings, written by the skill.
- `rules.md`: human-editable writing rules and language.

## Loading

On every invocation, read both files.

- Both exist and are valid: skip the Q&A, load both.
- One or both missing: run first-run setup for the missing file only. `config.json` missing means questions 1 to 5; `rules.md` missing means questions 6 and 7. Then compile the original prompt in the same turn so the first run loses nothing. Print the file notice (below) after setup.
- Malformed: see the error table.
- Permission denied: see the error table. Nothing is asked and nothing is written.

The first read or write may raise a permission prompt in Claude Code and Codex. That is expected.

## The Q&A

Ask all questions in one message, each skippable. A skipped question gets its default, and setup still writes the whole file. The deletes-or-overwrites line states its default "on" in the question text, and skipping it counts as accepting that shown default, which is written to `big_change_criteria`.

| # | Question | Stored in |
|---|---|---|
| 1 | Compile model. Claude Code offers haiku (default), sonnet, opus, fable, or "same as session" (stored as `inherit`). Setup and config always save one of those five values. In other tools offer a choice only where the tool lets a skill pick a model; otherwise say the host's current model is used. | `config.json`, `model` |
| 2 | Approval mode: always approve, ask when the change is big, always ask. If "ask when the change is big": switch each built-in criterion on or off (external actions, more than 3 files, has assumptions, deletes or overwrites files; defaults on, on, off, on) and offer an optional free-text description of what the user counts as big (for example "anything that touches the billing module"). The deletes-or-overwrites criterion is asked as its own explicit line, showing "on" as the default and defining it as deleting a file or replacing its whole content. Ask it in every case, on first run and in `config`, even when the chosen mode is not "ask when the change is big". Never apply its default silently. | `config.json`, `approval_mode`, `big_change_criteria`, `big_change_custom` |
| 3 | Spec format: XML (recommended, Anthropic recommends XML tags for Claude), JSON, or Markdown. | `config.json`, `spec_format` |
| 4 | Invocation mode: manual only (default), or every prompt (opt-in; not available on Codex or native Windows in v1). | `config.json`, `invocation_mode` |
| 5 | Maximum clarifying questions per compile request (default 2; 0 means none, gaps become assumptions). | `config.json`, `question_limit` |
| 6 | Language of specs and results. | `rules.md`, heading Language |
| 7 | Writing rules: (a) are em dashes allowed, (b) default length for written deliverables, (c) default deliverable format (the format of what the agent produces, for example Markdown, plain text), (d) default tone. | `rules.md`, a rule line for each answered part |

Defaults (equal to the fallbacks in the error table): model `haiku`, approval `always_ask`, big-change criteria `external_actions`, `files_over_3` and `deletes_or_overwrites` on and `has_assumptions` off, spec format `xml`, invocation `manual_only`, question limit 2.

Not asked and not configurable: how guesses are marked, the tag rules, error handling.

## Setup always writes both files

Setup always creates `config.json` with every key: a skipped key gets its default, and the deletes-or-overwrites line is written on as the shown default. Setup always creates `rules.md` too. If questions 6 and 7 are skipped, it holds the `# Think2Spec rules` heading, an empty `## Language` with no line under it, and an empty `## Rules`. When Language is empty, the spec and the result follow the language of the user's prompt.

## rules.md format

Plain Markdown, one list of rules under headings.

```
# Think2Spec rules

## Language
English

## Rules
- Never use em dashes.
- Use Markdown for prose deliverables.
```

- Each line under "Rules" is applied to every compiled spec, typically as an entry in `<constraints>` (or the equivalent in the chosen format).
- "Language" sets the language of the spec and of the result. When it is empty, they follow the language of the user's prompt.
- A rule that conflicts with the current prompt: the prompt wins for that spec and the override is shown in `<assumptions>`.

## config.json

Flat, written by the skill, one key per line, arrays on a single line. Write valid JSON. Escape double quotes and backslashes in string values, for example in `big_change_custom`. Keep one key per line. Write it exactly in this shape (shown with the defaults):

```
{
"model": "haiku",
"approval_mode": "always_ask",
"big_change_criteria": ["external_actions", "files_over_3", "deletes_or_overwrites"],
"big_change_custom": "",
"spec_format": "xml",
"invocation_mode": "manual_only",
"question_limit": 2
}
```

| Key | Values | Default |
|---|---|---|
| `model` | `sonnet`, `opus`, `haiku`, `fable` or `inherit` ("same as session") | `haiku` |
| `approval_mode` | `always_approve`, `ask_when_big`, `always_ask` | `always_ask` |
| `big_change_criteria` | array of the built-in criteria switched on: `external_actions`, `files_over_3`, `has_assumptions`, `deletes_or_overwrites` | `external_actions`, `files_over_3`, `deletes_or_overwrites` |
| `big_change_custom` | free text on one line, may be empty; judged by the configured compile model | empty |
| `spec_format` | `xml`, `json`, `markdown` | `xml` |
| `invocation_mode` | `manual_only`, `every_prompt` | `manual_only` |
| `question_limit` | whole number, 0 or more; 0 means no questions | `2` |

## The config keyword

Only the exact `/think2spec config` with no further text opens settings. Surrounding whitespace is ignored. The same rule applies to each tool's invocation form (`$think2spec config`, `@think2spec config`). Anything with more text is compiled as a prompt.

Behaviour: print the current values, ask what to change in one message (the seven settings above, with question 2 including the deletes-or-overwrites line), write the files, compile nothing. Write valid JSON, as in the config.json section. After writing, print the notices that apply.

`config` must work when a file is malformed, because it is the rebuild path. If `~/.config/think2spec/` cannot be written, config reports that settings cannot be saved.

### The five notices

1. **Safety warning.** When the saved combination is approval `always_approve` and invocation `every_prompt`, print one line: "Warning: every prompt will be compiled and executed with no pause." Do not block it.
2. **Codex notice.** When `every_prompt` is chosen in Codex, say that every prompt is not available on Codex in v1, because `agents/openai.yaml` forbids implicit invocation. Codex still needs explicit `$think2spec`. The setting is saved but has no effect there.
3. **Route notice.** When `every_prompt` is chosen, say the hook that powers it ships only with the Claude Code plugin route, not with npx installs, and needs a POSIX shell, so native Windows is unsupported in v1.
4. **File notice.** Say that `config.json` is written by the skill with one key per line and that hand edits are unsupported, because the hook reads the file line by line. Print it after first-run setup too.
5. **Big-change notice.** When all four built-in criteria are switched off and `big_change_custom` is empty, warn that "ask when big" will behave like "always approve", because nothing can count as big. Do not block it.

## Error table

Definitions. **Malformed:** `config.json` is not valid JSON, or `rules.md` is unreadable. **Unknown model:** a `model` value that is not sonnet, opus, haiku, fable or inherit and does not start with `claude-`. **Invalid value:** an `approval_mode`, `spec_format` or `invocation_mode` that is not one of the values in the table above.

| Case | Behaviour |
|---|---|
| `rules.md` or `config.json` missing | Run first-run setup for the missing file only. Questions whose file exists are skipped. |
| `rules.md` or `config.json` malformed | Tell the user which file and why. Offer `/think2spec config` to rebuild it. Do not compile on guesses. |
| `model` holds an unknown value | Fall back to the session model and say so in one line. |
| `model` starts with `claude-` | Map by family and pass the alias, with no notice: `claude-haiku-*` to `haiku`, `claude-sonnet-*` to `sonnet`, `claude-opus-*` to `opus`, `claude-fable-*` to `fable`. No family match: use the session model (omit the parameter) and print one line: "Model <value> is not available for the compile step; using the session model. Run /think2spec config to pick haiku, sonnet, opus or fable." Never pass a full ID to the Agent tool. |
| `approval_mode` invalid | Fall back to `always_ask` and say so in one line. |
| `spec_format` invalid | Fall back to `xml` and say so in one line. |
| `invocation_mode` invalid | Fall back to `manual_only` and say so in one line. |
| `question_limit` not a whole number, or below 0 | Fall back to 2 and say so in one line. A value of 0 is valid: no notice, no questions. |
| Permission to read or write `~/.config/think2spec/` denied | Compile without saved rules, using the defaults, and warn once per invocation. No setup Q&A, no setting question (including deletes-or-overwrites), no config written, no workspace fallback. The default approval mode `always_ask` ignores the criteria, so nothing runs unseen. Clarifying questions are unaffected. |
| Empty invocation (no prompt, no keyword) | Ask for the prompt. Compile nothing. |
| Windows | Files live in `%USERPROFILE%\.config\think2spec\`. Every-prompt mode is unsupported on native Windows in v1. |

A `big_change_criteria` entry that is not one of the four built-ins is not specified in v1: do not guess its meaning.
