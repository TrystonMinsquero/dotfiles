# Openable targets

When a message mentions a file, URL, or a command for me to run, wrap it in
`⟫` and `⟪` so I can open it with MOD+e in WezTerm:

- File: `⟫path/to/file.lua:42⟪` (`:line` and `:line:col` are optional; relative
  paths are resolved against the pane's directory)
- URL: `⟫https://example.com⟪`
- Command: `⟫$ ./install.sh⟪` (the `$ ` prefix marks it as a command)

Put nothing else between the markers, and no backticks inside them.
