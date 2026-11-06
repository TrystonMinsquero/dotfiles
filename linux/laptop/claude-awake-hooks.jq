# Adds the claude-awake hooks to ~/.claude/settings.json.
# Lock on each prompt, and again after each tool runs (in case a permission
# prompt released it); unlock when Claude finishes, waits for permission,
# or exits. Old claude-awake hooks are replaced, other hooks are kept.
# Usage: jq --arg cmd ~/.local/bin/claude-awake -f claude-awake-hooks.jq settings.json

def hook(m; a):
    {hooks: [{type: "command", command: "\($cmd) \(a)"}]}
    + (if m then {matcher: m} else {} end);

def add(ev; h):
    .hooks[ev] = ([(.hooks[ev] // [])[]
        | select(any(.hooks[]?; .command | contains("claude-awake")) | not)]
        + [h]);

add("UserPromptSubmit"; hook(null; "start"))
| add("PostToolUse"; hook("*"; "start"))
| add("Notification"; hook("permission_prompt"; "stop"))
| add("Stop"; hook(null; "stop"))
| add("SessionEnd"; hook(null; "stop"))
