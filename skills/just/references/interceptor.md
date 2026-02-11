# Just Command Interceptor

A PreToolUse hook that intercepts raw CLI commands and redirects Claude to project-standard just recipes.

## How It Works

1. Claude Code fires a `PreToolUse` event before every Bash tool call
2. The hook reads the command from stdin JSON
3. Checks patterns in `.claude/just-interceptor.json`
4. **Match**: Returns deny with redirect message pointing to the just recipe
5. **No match**: Exits silently, command proceeds normally

## Project Configuration

Create `.claude/just-interceptor.json` in the project root:

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

## Pattern Writing Tips

Patterns are regex matched against the full Bash command string.

```
# Exact command prefix
"pattern": "^npm install"

# Any npm command
"pattern": "^npm "

# Multiple commands with alternation
"pattern": "^(npm install|npm ci|npm update)"

# With optional flags
"pattern": "^docker compose (-f .+ )?(up|down|restart)"

# Catch all variations
"pattern": "^go (build|test|run)"
```

## Common Redirect Patterns

### Node.js Projects

```json
{
  "redirects": [
    { "category": "npm", "enabled": true, "pattern": "^npm install", "just_command": "just npm::install", "reason": "Uses lockfile-aware install with correct cwd" },
    { "category": "npm", "enabled": true, "pattern": "^npm run build", "just_command": "just npm::build", "reason": "Build with project-standard environment" },
    { "category": "npm", "enabled": true, "pattern": "^npm test", "just_command": "just npm::test", "reason": "Test runner with coverage flags" }
  ]
}
```

### Go Projects

```json
{
  "redirects": [
    { "category": "go", "enabled": true, "pattern": "^go build", "just_command": "just go::build", "reason": "Build with standard ldflags and output dir" },
    { "category": "go", "enabled": true, "pattern": "^go test", "just_command": "just go::test", "reason": "Tests with race detection and coverage" },
    { "category": "go", "enabled": true, "pattern": "^golangci-lint", "just_command": "just go::lint", "reason": "Lint with project config" }
  ]
}
```

### Docker Projects

```json
{
  "redirects": [
    { "category": "docker", "enabled": true, "pattern": "^docker compose up", "just_command": "just docker::up", "reason": "Compose with correct env and profiles" },
    { "category": "docker", "enabled": true, "pattern": "^docker compose down", "just_command": "just docker::down", "reason": "Clean shutdown with volume handling" },
    { "category": "docker", "enabled": true, "pattern": "^docker build", "just_command": "just docker::build", "reason": "Build with standard tags and build args" }
  ]
}
```

## Setup Workflow

1. Create justfile with recipes for all project commands
2. Create `.claude/just-interceptor.json` with redirect patterns
3. Install the plugin: `/plugin marketplace add kettleofketchup/claude-just-interceptor`
4. Test by asking Claude to run a mapped command

## Requirements

- [just](https://github.com/casey/just) on PATH
- [jq](https://jqlang.github.io/jq/) on PATH
