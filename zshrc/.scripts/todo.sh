
TODAY=${TODAY:=$(date +%Y-%m-%d)}
TODO_DIR=${TODO_DIR:="$HOME/notes/todo"}

function today_todo() {
  local yesterday=$(date -d "yesterday" +%Y-%m-%d)
  local todo_file="$TODO_DIR/$TODAY.md"
  local yesterday_file="$TODO_DIR/$yesterday.md"

  # Create directory if it doesn't exist
  mkdir -p "$TODO_DIR"

  # If file doesn't exist, create it with header
  if [ ! -f "$todo_file" ]; then
    local formatted_date=$(date +%m/%d/%Y)
    echo -e "# $formatted_date\n\n" > "$todo_file"

    # Append previous day's content if it exists
    if [ -f "$yesterday_file" ]; then
      tail -n +3 "$yesterday_file" >> "$todo_file"
    fi
  fi
  echo $todo_file
}

function t() {
  # Open in editor (uses $EDITOR or defaults to vim)
  ${EDITOR:-vim} +3 "$(today_todo)"
}

