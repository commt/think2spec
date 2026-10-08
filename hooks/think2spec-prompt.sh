#!/bin/sh
# Think2Spec UserPromptSubmit hook. Prints context only when invocation_mode is every_prompt.
# Every failure path prints nothing and exits 0. Never writes anything.

input=$(cat 2>/dev/null) || exit 0

# Prefix of the "prompt" field. The prompt is data: only quoted, only matched with case patterns.
prompt=$(printf '%s\n' "$input" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\(.*\)/\1/p' | head -n 1)
[ -n "$prompt" ] || exit 0

# JSON may carry leading whitespace as literal \n, \t or \r escapes; drop them with real whitespace.
prompt=$(printf '%s\n' "$prompt" | sed -E 's/^(\\[ntr]|[[:space:]])*//')

# One skip rule: /think2spec followed by end of text, whitespace or a colon.
# In the raw JSON, end of text shows as a closing quote, and whitespace may show as a backslash escape.
case $prompt in
  /think2spec) exit 0 ;;
  /think2spec[\"\\:\ ]*) exit 0 ;;
  /think2spec"	"*) exit 0 ;;
esac

config="${HOME:-}/.config/think2spec/config.json"
[ -n "${HOME:-}" ] && [ -r "$config" ] || exit 0

mode=$(grep '"invocation_mode"' "$config" 2>/dev/null | head -n 1 | sed -E 's/.*"invocation_mode"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/')
[ "$mode" = "every_prompt" ] || exit 0

printf '%s\n' "Think2Spec is set to every prompt. Run the think2spec skill on the user's message before doing anything else, unless the message is a reply inside a running think2spec round (an approval, an edit, a cancel, or an answer to one of its questions)."
exit 0
