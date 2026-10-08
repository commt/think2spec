# Examples

Three compiled specs, in XML (the default format). The schema they follow is in `compiler-prompt.md`.

## Example A: a blog prompt, no skills named

Raw prompt:

> Write a blog post about how small teams can set up a self-hosted password manager, and compare the main options. Keep it clear and readable, friendly to search engines, short enough to read but long enough to explain the steps. Use a professional tone.

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

`<role>`, `<background>` and `<tone>` are framing, so they may be inferred. Length, format, audience, the option set and the done-criteria are scope, so they sit in `<assumptions>`. `<tone>` has stated content ("professional") and appears. SEO and length have stated content, which sits in `<requirements>`, so they get no tag of their own; their guessed parts sit in `<assumptions>`. No `<verification>` tag appears because every verification item is a guess. This example has no skill list passed in, so it carries no `<skills>` tag.

### Example A in JSON and Markdown

The same spec in the other two formats, shortened to the `task`, `requirements` and `assumptions` tags. The other tags map the same way: a key per tag in JSON, a `##` heading per tag in Markdown.

JSON:

```json
{
  "spec": {
    "version": 1,
    "role": "blog author",
    "tone": "professional",
    "task": "Write a blog post on how small teams can set up a self-hosted password manager, comparing the main options.",
    "requirements": [
      "Compare the main options.",
      "Clear and readable."
    ],
    "assumptions": [
      "Length: roughly 1,000 to 1,500 words. The prompt gave no number.",
      "Deliverable format: one Markdown document with a title, headings and a short summary at the top."
    ]
  }
}
```

Markdown:

```
# Spec v1

## role
blog author

## tone
professional

## task
Write a blog post on how small teams can set up a self-hosted password manager, comparing the main options.

## requirements
- Compare the main options.
- Clear and readable.

## assumptions
- Length: roughly 1,000 to 1,500 words. The prompt gave no number.
- Deliverable format: one Markdown document with a title, headings and a short summary at the top.
```

## Example B: skills named, plus model picks

Raw prompt: Example A's prompt with this sentence added at the end.

> Use the seo-content and copywriting skills.

Assumed installed skills passed in with the call: `seo-content`, `copywriting`, `copy-editing`, `database-schema-designer`, `think2spec`. The compile model keeps the two named skills, adds `copy-editing` as a suggested pick because it suits a finished article, leaves out `database-schema-designer` because it does not fit the task, and never lists `think2spec`. If the host passes no list, only the two named skills appear.

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
    <item>Use the seo-content and copywriting skills.</item>
  </requirements>
  <constraints>
    <item>Never use em dashes. (saved rule)</item>
  </constraints>
  <skills>
    <item source="user">seo-content</item>
    <item source="user">copywriting</item>
    <item source="suggested">copy-editing</item>
  </skills>
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

The `source` attribute tells the user's own choices from the model's picks. The suggested pick is not an assumption, so it stays out of `<assumptions>`. In JSON the skills tag is an array of objects such as `{ "name": "copy-editing", "source": "suggested" }`. In Markdown each skill is a bullet with a `(user)` or `(suggested)` suffix.

## Example C: a code prompt, nearly everything guessed

Raw prompt:

> Add dark mode to the settings page.

No skills named, none installed.

```xml
<spec version="1">
  <task>Add dark mode to the settings page.</task>
  <requirements>
    <item>Add dark mode to the settings page.</item>
  </requirements>
  <assumptions>
    <item>Persistence: the theme preference is kept across reloads.</item>
    <item>Default: follow the system preference on first visit.</item>
    <item>Toggle: a switch on the settings page itself.</item>
    <item>Files: the settings page component and the shared theme styles are the files touched.</item>
    <item>Discovery: read the settings page component and the current theme styles before editing.</item>
    <item>Verification: build and lint pass, and the page renders correctly in both themes.</item>
  </assumptions>
</spec>
```

The user stated nothing about files, discovery or verification, so no `<files>`, `<discovery>` or `<verification>` tag appears. Each of those would hold only guesses, so all of them sit in `<assumptions>` with a scope label. Counter-example: "persist the theme preference" is not a requirement here, because the user did not ask for it.
