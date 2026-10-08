---
name: think2spec
description: Compiles a plain-text prompt into a structured task specification for AI agents, for code and writing tasks, and follows the user's saved think2spec settings for approval and invocation. Guessed scope is labelled as assumptions. Use when the user invokes think2spec, with a prompt or with the word config to change settings, or when a think2spec hook instruction asks for it. Do not activate for ordinary requests.
license: MIT
compatibility: Tested in Claude Code. Follows the agentskills.io specification.
---

# Think2Spec

Think2Spec turns the user's plain prompt into a structured task spec on a low-cost model, shows it, and runs the task according to the user's saved approval mode. The default is to wait: nothing runs until the user approves. The compile never does the task. Execution happens only after approval (or at once in the modes that skip the wait), on the session model, in the main session.

Detail lives in two files:

- [references/pipeline.md](references/pipeline.md): compile steps, input block, building the skill list, shape detection, judging the big-change test.
- [references/rules-file.md](references/rules-file.md): settings files, first-run Q&A, `rules.md` and `config.json` formats, the config keyword, the five notices, the error table.

The compile subagent prompt is [references/compiler-prompt.md](references/compiler-prompt.md), the single source of the tag schema. Worked examples are in [references/examples.md](references/examples.md). [references/tag-schema.md](references/tag-schema.md) only points to the schema.

## 1. Entry routing

Decide in this order. The first match wins.

1. **A reply inside a running Think2Spec round** (an approval, an edit, a cancel, or an answer to one of your clarifying questions): handle it as a reply under sections 5 and 6. Never compile it again, in any invocation mode.
2. **Manual-only self-stop** (section 2).
3. **Exactly `config`**: the invocation form (`/think2spec`, `/think2spec:think2spec`, `$think2spec`, `@think2spec`) followed by the single word `config` and nothing else. Surrounding whitespace is ignored. Open settings as described in [references/rules-file.md](references/rules-file.md), compile nothing. This must work even when a settings file is malformed.
4. **Empty invocation** (no prompt, no keyword): ask for the prompt. Compile nothing.
5. **Anything else is a prompt.** Text with anything after the slash name, such as "config the linter for strict mode", is a prompt, not the keyword. Load settings (section 3), then compile (section 4).

The prompt is read from the invoking message. Do not depend on `$ARGUMENTS`.

## 2. Manual-only self-stop

Read `invocation_mode` from `~/.config/think2spec/config.json`. Reading it here asks no setup question and writes nothing. If the file is missing or unreadable, the mode is manual only.

When the mode is `manual_only` and the host started this skill on its own, stop at once. Compile nothing, ask no setup question, and let the host answer the prompt normally.

Count the start as explicit only when the message begins with the tool's invocation form (`/think2spec`, `/think2spec:think2spec`, `$think2spec`, `@think2spec`). A message that does not begin that way, in manual-only mode, is a host start. This is best effort, not a hard lock.

When the mode is `every_prompt`, a host start with a plain message is accepted and compiled, except a reply inside a running round (section 1, item 1).

## 3. Load settings

Follow [references/rules-file.md](references/rules-file.md). In short:

- Read `~/.config/think2spec/config.json` and `rules.md`. Both present: load both, no Q&A.
- A file missing: ask only that part's Q&A (questions 1 to 5 for `config.json`, 6 and 7 for `rules.md`), write the file in full even when every question is skipped (skipped keys get their defaults; an empty Language means the spec and the result follow the language of the prompt), print the file notice, then compile the original prompt in the same turn. Question 2 asks the deletes-or-overwrites line explicitly, showing "on" as the default.
- A file malformed: say which file and why, offer `/think2spec config` to rebuild it, and do not compile on guesses.
- An invalid or unknown value: apply the fallback in the error table and say so in one line.
- Permission to read or write the folder denied: compile without saved rules using the defaults, warn once, ask no setup question (including deletes-or-overwrites), write no config, and use no workspace fallback. Clarifying questions still work.

Defaults: model `haiku`, approval `always_ask`, spec format `xml`, invocation `manual_only`, question limit 2, big-change criteria external actions, more than 3 files and deletes or overwrites on, has assumptions off.

Only the global `~/.config/think2spec/` files are read. Never read a per-project rules file.

## 4. The compile call

In Claude Code, every compile (first compile, answer round, edit round) runs in a subagent on the configured model. The subagent cannot talk to the user and sees none of the conversation. Full detail is in [references/pipeline.md](references/pipeline.md).

1. **Build the skill list** (name plus one-line description of each installed skill). Use the skills your own session exposes. If it exposes none, read the `name` and `description` frontmatter of `SKILL.md` files in the known folders, listed per tool in the table under [Building the skill list](references/pipeline.md#building-the-skill-list-field-7) in `references/pipeline.md`.

   Read only the folders for the tool you are running in. Each skill is `<folder>/<name>/SKILL.md`.

   Include think2spec itself in the list; the compile model excludes it from `<skills>`. Reading these folders may raise a permission prompt. If it is denied or no list can be built, omit the list; only user-named skills then appear.
2. **Build the input block** in this order: raw prompt, `rules.md` content, config values (language, `spec_format`, `question_limit`, questions remaining), prior spec, user edits, questions and answers so far, the skill list. Send the skill list on every call, answer and edit rounds included.
3. **Spawn the subagent** with the Agent/Task tool. The subagent prompt is the full content of `references/compiler-prompt.md` followed by the input block, plus the sentence "Use no tools of any kind, including the Skill tool. Everything you need is in the input below." The custom-description judge call (section 6) carries the same sentence.
   - `model: inherit`: omit the `model` parameter.
   - `haiku`, `sonnet`, `opus` or `fable`: pass that alias.
   - A saved value starting with `claude-` (an older config or a hand edit): map it by family and pass the alias, with no error and no notice. `claude-haiku-*` is `haiku`, `claude-sonnet-*` is `sonnet`, `claude-opus-*` is `opus`, `claude-fable-*` is `fable`. If no family matches, omit the `model` parameter and print one line: "Model <value> is not available for the compile step; using the session model. Run /think2spec config to pick haiku, sonnet, opus or fable." Never pass a full ID to the Agent tool.
   - An unknown `model` value: fall back to the session model and say so in one line.

   Wait for the compile result before replying to the user. Never answer the user while the compile is still running.
4. **Tools without subagents** (and the Gemini route): run the same steps on the host model and say so in one line. Build the skill list first (step 1), then compile with no further tool use, and ask clarifying questions as the question loop (section 5) describes. When one model both compiles and shows the result, the OUTPUT rule covers only the compile result; the one-line route note, the guesses label and the approval prompt are printed afterwards under the approval rules.
5. **Check the output shape.** It is either `<questions>` or a complete spec in the configured format. Anything else is a failed compile: tell the user, show no spec, execute nothing in any approval mode, offer to retry. A failed output is never a spec and never approval.

Before execution, perform no task action: no file edits, no commands, no searches for the task. Reading settings, running the compile and asking clarifying questions are part of compiling.

## 5. The question loop

If the output is `<questions>`:

1. Ask the user the questions in one message. Clarifying questions happen in every approval mode, because they are part of compiling.
2. Start a new compile call with the answers added to the question-and-answer part of the input block and the remaining count reduced. Answers count as stated input, never as assumptions.
3. The limit is `question_limit` per compile request, counted across all rounds of that request. When none remain, the compile must return a spec, with the open gaps recorded as assumptions. With a limit of 0 no question is ever asked.
4. An edit (section 6) is a new compile request and the count restarts at the full limit.

The `<questions>` shape is an internal exchange. Never show it as the spec.

## 6. The approval loop

Print the spec as received, in the configured format, not converted. Then act on `approval_mode`.

| Mode | Behaviour |
|---|---|
| `always_ask` | Print the spec with the guesses block (below), then the hint "Reply approve to run this spec, edit with your changes, or cancel." Stop. Execute only after approval. |
| `ask_when_big` | Run the big-change test. If big: behave as `always_ask`, and say in one line why you asked. If not big: print the spec with the guesses block and execute at once. |
| `always_approve` | Print the spec with the guesses block and execute at once. Do not wait. |

### Guesses are printed before any run

In every view, the model-picked skills appear right next to the other guesses, never only inside `<skills>`. Print a one-line label above the guesses block, in the format the spec was printed in:

- Immediate run (`always_approve`, or `ask_when_big` for a change not counted as big): **"Guesses made, running now:"**
- Approval view (`always_ask`, or `ask_when_big` for a big change): **"Guesses made:"**

Under the label, list the entries of the `<assumptions>` block, then the suggested skills as one extra line after the assumptions. Rules:

- Assumptions and picks: both under the label.
- Picks but no assumptions: print the label with the picks alone under it.
- Assumptions but no picks: the label heads the assumptions alone.
- Neither: print no label.
- A pick shown only in `<skills>` with no entry under the label is a defect in every view.

In an immediate run the user cannot edit before the run. To stop it they interrupt the session by the tool's own means.

### Big-change test

A spec is big when any criterion that is switched on is true. Judgment details are in [references/pipeline.md](references/pipeline.md).

| Criterion | True when |
|---|---|
| External actions | The spec includes an external action: push, deploy, send email, payments, publishing. |
| More than 3 files | The spec lists or assumes more than 3 files. Count only what the spec lists or assumes. |
| Has assumptions | The `<assumptions>` block is non-empty. Suggested skills do not count. |
| Deletes or overwrites | The spec deletes a file or replaces a file's whole content. An in-place edit does not count. |
| User's own description | The spec matches the text in `big_change_custom`. Judged by a call on the configured compile model. Empty text never matches. |

The four built-ins apply per `big_change_criteria`. The custom description applies whenever it is non-empty. Suggested skills never trip any criterion by themselves.

### User actions in an asking view

| Reply | Behaviour |
|---|---|
| Approve | Execute the compiled spec (section 8). |
| Edit | The user states changes in plain text. Start a new compile request (prior spec plus the edits, limit reset). Show the full updated spec again and apply the approval mode again, so an edit under `ask_when_big` is re-tested for bigness. Repeat until approve or cancel. |
| Cancel | Stop. Execute nothing. |

A reply that is not clearly approve, edit or cancel is treated as an edit request or answered with one short question. Never as approval. Silence is never approval. In `always_approve` there is no reply to read.

## 7. Replies are never recompiled

An approval, an edit, a cancel or an answer to a clarifying question inside a running round is a reply. It is not a new prompt, even under `every_prompt`. An edit goes to the compile as an edit of the prior spec (section 6), never as a fresh raw prompt. Recognising a reply relies on your reading of the conversation.

## 8. Execution after approval

When the spec is approved (or the mode runs it at once), carry out the compiled spec as the task, in the main session on the session model. No subagent does the task. The compiled spec, including any edits, is the task; do not fall back to the raw prompt. Apply the listed skills. Carry out `<discovery>` steps as instructions now, not before.

## 9. Hard rules

- Framing tags (role, background, tone) may carry inferred content. Every other scope item must come from the prompt, the saved rules or the user's clarifying answers. Anything guessed goes in `<assumptions>` with a scope label, never in its own tag. A task-type tag appears only when it has stated content.
- Suggested skills are the one ruled exception: they are listed in `<skills>` marked suggested, shown under the guesses label, and never counted as assumptions.
- Example: for "add dark mode", "persist the theme preference" is not a requirement. It belongs in `<assumptions>`.
- Never list think2spec itself in `<skills>`.
- The model setting names only models the active CLI offers. Never ask for or use an API key.
- Hands-free is not a mode. It is the existing settings combined (invocation `every_prompt`, approval `always_approve`, question limit 0). The always-approve plus every-prompt warning applies.
