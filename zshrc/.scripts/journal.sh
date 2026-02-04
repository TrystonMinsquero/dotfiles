
# Create today's journal if it doesn't exist
function journal_today() {
  TODAY=$(date +%Y-%m-%d)
  JOURNAL_DIR="$HOME/notes/journal"
  local journal_file="$JOURNAL_DIR/$TODAY.md"

  # Create directory if it doesn't exist
  mkdir -p "$JOURNAL_DIR"

  # If file doesn't exist, create it with header
  if [ ! -f "$journal_file" ]; then
      local date=$(date +%m/%d/%Y)
      echo -e "# $date\n\n" > "$journal_file"
  fi
  ${EDITOR:-vim} +3 -c 'startinsert' "$journal_file"
}
