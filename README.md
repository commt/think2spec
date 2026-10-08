# Think2Spec

Prompt to structured task spec for AI coding agents.

Think2Spec turns a loose prompt into a reviewed, structured task for your AI coding agent. You type a plain prompt. A low-cost model compiles it into a task specification, and by default nothing runs until you approve it. Any scope the model had to guess is listed as an assumption, so you see it before the work starts.

Manual by default, automatic if you want it.

## What it does

A prompt such as "add dark mode" leaves the agent to guess the audience, the deliverable, the limits and what "done" means. It then builds the wrong thing, or quietly adds things you never asked for, such as saving the theme preference.

Think2Spec compiles the prompt first:

1. It extracts intent, audience and deliverable from your plain text.
2. It asks clarifying questions only where the answer would change what gets built (2 by default, configurable, 0 allowed).
3. It writes a spec with open-ended tags chosen from your prompt.
4. It puts everything it guessed under `<assumptions>`, never into requirements.
5. It applies your saved writing rules, such as "never use em dashes".
6. It shows the spec and, depending on your approval mode, waits for you to approve, edit or cancel.

After approval the agent does the work in your normal session, on your session model. The spec, including your edits, is the task.

What sets it apart:

- Approval modes, with a gate by default.
- Open-ended tags chosen from the prompt, not a fixed template.
- Guessed scope marked as assumed.
- A low-cost compile model, chosen by you.
- Spec output in XML (recommended default), JSON or Markdown.
- One portable skill across agents.

## Before and after

With the rule "never use em dashes" saved in your settings, you type:

> Write a blog post about how small teams can set up a self-hosted password manager, and compare the main options. Keep it clear and readable, friendly to search engines, short enough to read but long enough to explain the steps. Use a professional tone.

Think2Spec prints (XML shown, the default):

```xml
<spec version="1">
  <role>blog author</role>
  <background>You are an experienced technology writer who explains security tools to non-specialist readers.</background>
  <tone>professional</tone>
  <task>Write a blog post on how small teams can set up a self-hosted password manager, comparing the main options.</task>
  <requirements>
    <item>Compare the main options.</item>
    <item>Clear and readable.</item>
    <item>Friendly to search engines.</item>
    <item>Short enough to read, long enough to explain the steps.</item>
  </requirements>
  <constraints>
    <item>Never use em dashes. (saved rule)</item>
  </constraints>
  <assumptions>
    <item>Length: roughly 1,000 to 1,500 words. The prompt gave no number.</item>
    <item>Deliverable format: one Markdown document with a title, headings and a short summary at the top.</item>
    <item>Options: "main options" means three or four well-known self-hosted password managers chosen by the agent.</item>
    <item>Audience: team leads with some technical comfort, not specialists.</item>
    <item>SEO: descriptive headings and a direct answer near the top of each section.</item>
    <item>Done when: length is within range, every requirement above is visibly met, and each comparison claim is one the agent can support.</item>
  </assumptions>
</spec>
```

Role, background and tone are framing, so the model may infer them. Everything else is scope. Length, format, audience, the option set and the done-criteria were not in your prompt, so they sit in `<assumptions>`, where you can approve or strike each one. See [`skills/think2spec/references/examples.md`](skills/think2spec/references/examples.md) for more examples, including JSON and Markdown output.

## Install

Pick one install route per tool. In Claude Code, use the plugin or npx, not both.

| Tool | Install | Invoke | Status |
|---|---|---|---|
| Claude Code, plugin (recommended) | `/plugin marketplace add commt/think2spec`, then `/plugin install think2spec@commt` | `/think2spec` or `/think2spec:think2spec`, then your prompt | Tested |
| Claude Code, npx | `npx skills add commt/think2spec -g` | `/think2spec` | Tested |
| Codex | `npx skills add commt/think2spec -g` | `$think2spec` | Awaiting community testing |
| Copilot in VS Code | `npx skills add commt/think2spec -g` | `/think2spec` | Awaiting community testing |
| Cursor | `npx skills add commt/think2spec -g` | `/think2spec` | Awaiting community testing |
| Cline | `npx skills add commt/think2spec -g` | `/think2spec` | Awaiting community testing |
| Windsurf | `npx skills add commt/think2spec -g` | `@think2spec` | Awaiting community testing |
| Gemini CLI | Copy `adapters/gemini/think2spec.toml` to `~/.gemini/commands/` | `/think2spec <prompt>` | Awaiting community testing |
| OpenCode | `npx skills add commt/think2spec -g` | The agent invokes it | Awaiting community testing |

Tried Think2Spec in another tool? Open an issue with what worked and what didn't.

The npx command installs the skill globally: to `~/.claude/skills/` for Claude Code and `~/.agents/skills/` for Codex. The every-prompt hook (see [Invocation modes](#invocation-modes)) does not ship on the npx route.

### Install in Claude Code

Run the two plugin commands from the table inside Claude Code. In a session, the install opens the plugin panel so you can choose a scope. From a shell, `claude plugin install think2spec@commt` installs directly. The plugin gives you both `/think2spec:think2spec` and the bare `/think2spec`. The repository is both the plugin and its marketplace.

### Install in Codex

Use the npx command, then call `$think2spec` followed by your prompt. `agents/openai.yaml` asks Codex not to start the skill on its own, by setting `allow_implicit_invocation: false`.

### Install in Gemini CLI

Gemini CLI uses the command file, not the skill. Copy `adapters/gemini/think2spec.toml` to `~/.gemini/commands/`, then run `/think2spec <prompt>`.

Note: `npx skills add commt/think2spec -g` also installs the skill into `~/.gemini/skills/`, and Gemini CLI activates installed skills on its own when a task matches, so you cannot invoke them by hand. The command file is the manual route, and the one this README documents for Gemini. If you want Think2Spec to run only when you type it, install the command file and skip the npx route for Gemini.

The Gemini route does compile and approval only, with fixed defaults: always ask, XML, manual only. It has no saved rules, no `config` keyword and no first-run questions. One model plays both roles, compiler and executor, and the output says so. If Gemini CLI exposes no skills, the model reads the Gemini skill folders. If none are found, only the skills you name appear. Reading skill folders may raise a permission prompt.

## Settings and the config keyword

The first time you run Think2Spec it asks seven questions in one message. Every question can be skipped, and a skipped question uses its default.

| # | Setting | Default |
|---|---|---|
| 1 | Compile model | haiku |
| 2 | Approval mode, big-change criteria and an optional custom description | always ask |
| 3 | Spec format | XML |
| 4 | Invocation mode | manual only |
| 5 | Clarifying-question limit | 2 |
| 6 | Language | not set |
| 7 | Writing rules (em dashes, default length, deliverable format, tone) | none |

Settings live in two global files, with no per-project override:

- `~/.config/think2spec/config.json` holds settings 1 to 5. The skill writes it, one key per line. Do not edit it by hand: the hook reads it line by line, and hand edits are unsupported.
- `~/.config/think2spec/rules.md` holds settings 6 and 7 as plain Markdown that you can edit.

On Windows the folder is `%USERPROFILE%\.config\think2spec\`.

Change any setting later with `/think2spec config`. It is a keyword of the one skill, not a second skill. In Codex the form is `$think2spec config`, and in Windsurf `@think2spec config`. Only the exact text `/think2spec config` opens settings. Anything with more text after it, such as `/think2spec config the linter for strict mode`, is compiled as a prompt.

### Permission prompts

The first read or write of `~/.config/think2spec/` may raise a permission prompt in Claude Code and in Codex. Accept it. There is no workspace fallback. If you deny it, Think2Spec compiles without your saved rules, using the defaults, and warns once. It asks no setting questions and writes no config. Clarifying questions still work.

### Which model compiles

In Claude Code, every compile step (first pass, clarifying rounds, edit rounds) runs in a subagent on the model you set: haiku (default), sonnet, opus, fable or "same as session". In other tools the host tool's model compiles, and the output says so.

### No API keys

Think2Spec never takes an API key and never calls a model API itself. It uses only models your active CLI offers.

## Approval modes

Set the approval mode at config time.

| Mode | What happens |
|---|---|
| Always ask (default) | Prints the spec and its guesses, then waits. You reply approve, edit or cancel. Nothing runs before approval. |
| Ask when the change is big | Waits only when the change counts as big, and says why. Otherwise it prints the spec with guesses highlighted and runs at once. |
| Always approve | Prints the spec with guesses highlighted and runs at once, with no wait. |

In the asking modes, an edit compiles the spec again and shows it in full. A reply that is not clearly approve, edit or cancel is never treated as approval. Clarifying questions are asked in every mode, because they are part of compiling.

### What counts as big

A change is big when any criterion you have switched on is true:

| Criterion | Default | Meaning |
|---|---|---|
| External actions | on | The spec includes a push, deploy, sent email, payment or publishing step. |
| More than 3 files | on | The spec lists or assumes more than 3 files. |
| Has assumptions | off | The spec contains any guessed scope. Switching this on makes "ask when big" behave much like "always ask". |
| Deletes or overwrites files | on | The spec deletes a file or replaces its whole content. A normal in-place edit does not count. |

You can also describe in your own words what you count as big, for example "anything that touches the billing module". The compile model judges that description against each spec, so a match can be missed. Config asks about the deletes-or-overwrites criterion explicitly, showing "on" as the default, and never applies it silently. If you switch every criterion off and leave the description empty, config warns that "ask when big" then behaves like "always approve".

## Skills

The `<skills>` tag lists the skills you named in your prompt, always, plus installed skills the compile model judges useful for the task, even if you named none. The model's picks are marked `source="suggested"` in XML (a `source` key in JSON, a `(suggested)` suffix in Markdown). Your own are marked as user. Think2Spec never lists itself.

Picks are listed right next to the other guesses in every view that shows guesses, both when a run starts at once and when the spec waits for approval. They do not count as assumptions for the big-change test.

The agent running Think2Spec builds the list of installed skills from its host session, or from the skill folders when the host provides no list. Reading skill folders can raise a permission prompt. When no list can be built, only the skills you named appear. Each compile call receives every skill's name and one-line description.

## Spec formats

XML is the recommended default. JSON and Markdown are also available. The same tags, the same stated-content rule and the same assumptions labelling apply in all three. The XML root is `<spec version="1">`, the JSON root is a top-level `"spec"` object with `"version": 1`, and the Markdown spec starts with `# Spec v1`.

## Invocation modes

**Manual only (default).** You call Think2Spec by name. This is best effort, not a hard lock. If the host starts the skill on its own, it stops at once and lets the host answer normally, and the description tells the host not to activate it for ordinary requests. Only Codex has an extra file, `agents/openai.yaml`, that forbids implicit invocation. Do not read manual only as a guarantee in any other tool.

`disable-model-invocation` is an optional SKILL.md setting that forbids a tool from starting a skill on its own. Claude Code, Copilot and Cursor support it, but other tools may refuse a file that contains it, so Think2Spec leaves it out everywhere.

**Every prompt (opt-in).** Think2Spec runs on every message you send, except replies inside a running round (an approval, an edit, a cancel or an answer to a question) and messages that start with `/think2spec`.

- **Claude Code, plugin route:** a `UserPromptSubmit` hook adds an instruction telling Claude to run the skill first. The hook ships only with the plugin, not with npx installs. It needs a POSIX shell, so every prompt is unsupported on native Windows in v1 (Git Bash is untested). If `config.json` is missing or broken, the hook stays silent and your prompt goes through untouched.
- **Claude Code, npx route, and other tools:** add this line to your `CLAUDE.md`, `AGENTS.md` or the tool's rules file: "For every message I send, run the think2spec skill on it first, unless my message starts with the think2spec command or is a reply to a think2spec question, approval or edit." Hook support in other tools is untested.
- **Codex:** every prompt is not available in v1. Codex needs an explicit `$think2spec`.
- **Gemini CLI:** manual only.

Warning: approval "always approve" plus invocation "every prompt" compiles and runs every prompt with no pause. Config prints a warning when you pick that combination. It does not block it.

## Hands-free setup

For a fully hands-free setup, set invocation to every prompt, approval to always approve (or ask when big with every criterion off and no custom description), and the question limit to 0. This is a combination of existing settings, not a separate mode. Think2Spec then compiles and runs every prompt with no pause and no questions, records gaps as assumptions, and prints the guesses before each run. It inherits the every-prompt limits above: not available on Codex, unsupported on native Windows, and the hook ships only in the Claude Code plugin route.

## Repository layout

```
.claude-plugin/      plugin.json and marketplace.json
hooks/               every-prompt hook (plugin route only)
skills/think2spec/   SKILL.md, references/, agents/openai.yaml (Codex)
adapters/gemini/     think2spec.toml for Gemini CLI
```

## Releasing

For maintainers. The `version` field in `.claude-plugin/plugin.json` pins what users receive, so every release must bump it. Per the [manifest reference](https://code.claude.com/docs/en/plugins/manifest-reference), setting it pins the plugin to that version until you change it. Regenerate `adapters/gemini/think2spec.toml` by hand from `skills/think2spec/references/compiler-prompt.md` on each release, so the two do not drift.

## Credits and license

Author: Mesut Kilincaslan. Organisation: [commt](https://github.com/commt). Repository: https://github.com/commt/think2spec.

Released under the MIT license. See [LICENSE](LICENSE).
