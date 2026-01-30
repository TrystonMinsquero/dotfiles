
TODAY=${TODAY:=$(date +%Y-%m-%d)}
TODO_DIR=${TODO_DIR:="$HOME/notes/todo"}

function today_todo() {
  local todo_file="$TODO_DIR/$TODAY.md"

  # Create directory if it doesn't exist
  mkdir -p "$TODO_DIR"

  # If file doesn't exist, create it with header
  if [ ! -f "$todo_file" ]; then
    local formatted_date=$(date +%m/%d/%Y)
    echo -e "# $formatted_date\n\n" > "$todo_file"

    # Find most recent previous todo file and append its content
    local prev_file=$(ls -1 "$TODO_DIR"/*.md 2>/dev/null | sort -r | head -n 1)
    if [ -n "$prev_file" ] && [ "$prev_file" != "$todo_file" ]; then
      tail -n +3 "$prev_file" >> "$todo_file"
    fi
  fi
  echo $todo_file
}

function t() {
  # Open in editor (uses $EDITOR or defaults to vim)
  ${EDITOR:-vim} +3 "$(today_todo)"
}

