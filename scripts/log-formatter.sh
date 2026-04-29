#!/usr/bin/env bash
# Formats Claude Code --output-format stream-json output for human readability.
# Reads newline-delimited JSON from stdin, prints human-friendly lines to stdout.

while IFS= read -r line; do
  type=$(printf '%s' "$line" | jq -r '.type // empty' 2>/dev/null)

  case "$type" in
    assistant)
      printf '%s' "$line" | jq -r '
        (.message.content // [])[] |
        if .type == "text" and (.text | length > 0) then
          .text
        elif .type == "tool_use" then
          "  ▶ \(.name): \(.input |
            if has("command")     then .command | split("\n")[0]
            elif has("file_path") then .file_path
            elif has("query")     then .query
            elif has("url")       then .url
            elif has("pattern")   then .pattern
            elif has("description") then .description
            elif has("prompt")    then (.prompt | split("\n")[0])
            else (to_entries[0] | "\(.key)=\(.value | tostring)" ) // ""
            end | .[0:120]
          )"
        else empty
        end
      ' 2>/dev/null
      ;;

    user)
      printf '%s' "$line" | jq -r '
        (.message.content // [])[] |
        select(.type == "tool_result") |
        (.content // "") |
        if type == "array" then map(select(.type == "text") | .text) | join("") | .[0:300]
        elif type == "string" then .[0:300]
        else empty
        end |
        select(length > 0) |
        split("\n") | map(select(length > 0)) | map("  ◀ " + .) | join("\n")
      ' 2>/dev/null
      ;;
  esac
done
