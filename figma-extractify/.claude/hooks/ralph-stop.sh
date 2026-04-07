#!/usr/bin/env bash
# Ralph Loop stop hook
# Intercepts Claude's exit and re-injects the prompt if the loop is still active.
# Exit code 2 = block exit and provide feedback message
# Exit code 0 = allow exit

set -euo pipefail

STATE_FILE=".ralph-loop-state.json"

# If no state file, loop is not active — allow exit
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Read state using jq for safe JSON parsing
ACTIVE=$(jq -r '.active' "$STATE_FILE")
CURRENT=$(jq -r '.current_iteration' "$STATE_FILE")
MAX=$(jq -r '.max_iterations' "$STATE_FILE")
PROMISE=$(jq -r '.completion_promise' "$STATE_FILE")

# If loop is not active, allow exit
if [ "$ACTIVE" != "true" ]; then
  exit 0
fi

# Check if the transcript/output contains the completion promise
# Read the stop hook input from stdin (contains the transcript reason)
STOP_INPUT=$(cat)

# Check if completion promise was found in the stop reason or recent output
if echo "$STOP_INPUT" | grep -qF "$PROMISE" 2>/dev/null; then
  # Completion promise found — deactivate loop and allow exit
  tmpfile=$(mktemp "${STATE_FILE}.XXXXXX")
  jq '.active = false' "$STATE_FILE" > "$tmpfile" && mv "$tmpfile" "$STATE_FILE"
  echo "Ralph Loop complete. Completion promise \"$PROMISE\" detected after $CURRENT iterations."
  exit 0
fi

# Check if max iterations reached
if [ "$CURRENT" -ge "$MAX" ]; then
  tmpfile=$(mktemp "${STATE_FILE}.XXXXXX")
  jq '.active = false' "$STATE_FILE" > "$tmpfile" && mv "$tmpfile" "$STATE_FILE"
  echo "Ralph Loop stopped — max iterations ($MAX) reached without completion promise."
  exit 0
fi

# Increment iteration counter
NEXT=$((CURRENT + 1))
tmpfile=$(mktemp "${STATE_FILE}.XXXXXX")
jq ".current_iteration = $NEXT" "$STATE_FILE" > "$tmpfile" && mv "$tmpfile" "$STATE_FILE"

# Read the original prompt
PROMPT=$(jq -r '.prompt' "$STATE_FILE")

# Block exit and re-inject the prompt
echo "Ralph Loop — iteration $NEXT/$MAX. Continue working on the task. Do not stop until the completion promise \"$PROMISE\" is achieved."
echo ""
echo "Original task: $PROMPT"
echo ""
echo "Review your progress so far and continue. When ALL exit criteria are met, output exactly: $PROMISE"
exit 2
