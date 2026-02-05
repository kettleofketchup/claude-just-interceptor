# just-interceptor

Claude Code hook that intercepts raw CLI commands and redirects to project-standard `just` recipes.

## Setup

1. Add the hook to your project's `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/home/kettle/git_repos/claude/just-interceptor/intercept.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

2. Create `.claude/hooks/just.json` in your project with command mappings:

```json
{
  "redirects": [
    {
      "category": "npm",
      "enabled": true,
      "pattern": "^npm install",
      "just_command": "just npm::install",
      "reason": "Project-standard npm install with correct working directory"
    }
  ]
}
```

## Config Fields

| Field | Type | Description |
|-------|------|-------------|
| `category` | string | Grouping label shown in the redirect message |
| `enabled` | boolean | Set `false` to disable without removing |
| `pattern` | string | Regex matched against the full command string |
| `just_command` | string | The just recipe to suggest |
| `reason` | string | Explanation shown to Claude |

## How It Works

1. Claude Code fires a `PreToolUse` event before every Bash tool call
2. The hook reads the command from stdin JSON
3. Checks patterns in the project's `.claude/hooks/just.json`
4. **Match**: Returns deny with redirect message
5. **No match**: Exits silently, command proceeds
