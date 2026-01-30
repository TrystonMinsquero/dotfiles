
TODAY=${TODAY:=$(date +%Y-%m-%d)}
JOURNAL_DIR=${JOURNAL_DIR:="$HOME/notes/journal"}

# Create today's journal if it doesn't exist
function today_journal() {
  local journal_file="$JOURNAL_DIR/$TODAY.md"

  # Create directory if it doesn't exist
  mkdir -p "$JOURNAL_DIR"

  # If file doesn't exist, create it with header
  if [ ! -f "$journal_file" ]; then
      local date=$(date +%m/%d/%Y)
      echo -e "# $date\n\n" > "$journal_file"
  fi
  echo $journal_file
}

# Edit today's journal 
function j() {
  # Open in editor (uses $EDITOR or defaults to vim)
  ${EDITOR:-vim} +3 -c 'startinsert' "$(today_journal)"
}
