# just-interceptor

Claude Code plugin that intercepts raw CLI commands and redirects to project-standard [just](https://github.com/casey/just) recipes.

When Claude tries to run `npm install`, `docker compose up`, or any command you've mapped, the hook denies it and tells Claude to use the corresponding `just` recipe instead.

## Install

```
/plugin install https://github.com/kettleofketchup/claude-just-interceptor.git
```

## Project Setup

Create `.claude/just-interceptor.json` in your project root with command mappings:

```json
{
  "redirects": [
    {
      "category": "npm",
      "enabled": true,
      "pattern": "^npm install",
      "just_command": "just npm::install",
      "reason": "Project-standard npm install with correct working directory"
    },
    {
      "category": "docker",
      "enabled": true,
      "pattern": "^docker compose up",
      "just_command": "just docker::up",
      "reason": "Uses project-specific compose configuration"
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
3. Checks patterns in the project's `.claude/just-interceptor.json`
4. **Match**: Returns deny with redirect message pointing to the just recipe
5. **No match**: Exits silently, command proceeds normally

## Requirements

- [jq](https://jqlang.github.io/jq/) must be available on PATH

## License

MIT
