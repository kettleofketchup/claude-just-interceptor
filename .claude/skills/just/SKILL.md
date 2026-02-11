---
name: just
description: Bootstrap repos with just command runner and enforce recipe usage with the just-interceptor hook. Use when setting up new projects, creating justfiles, adding task automation, organizing recipes with groups and modules, or configuring command interception to redirect raw CLI commands to project-standard just recipes. Provides ./dev bootstrap script, modular justfile structure in just/ directory, recipe conventions, intelligent grouping strategies for fzf-tab completion, and PreToolUse hook configuration for command redirection.
---

# Just Command Runner

Task automation using [just](https://github.com/casey/just) with a standardized project structure and optional command interception.

## Project Structure

```
project/
├── dev                 # Bootstrap script (installs just, runs `just dev`)
├── justfile            # Root: settings, imports, and modules
├── just/
│   ├── dev.just        # Development recipes (imported, no namespace)
│   ├── go.just         # Go module (go::build, go::test)
│   ├── docker.just     # Docker module (docker::build, docker::push)
│   └── lua.just        # Lua module (lua::install, lua::check)
└── .claude/
    └── just-interceptor.json  # Command interception config (optional)
```

## Bootstrapping a New Repo

1. Copy `assets/dev` to project root, make executable: `chmod +x dev`
2. Copy `assets/just/` directory to project root
3. Edit `just/dev.just` with project-specific setup commands
4. Add additional `.just` modules as needed
5. Optionally configure command interception (see `references/interceptor.md`)

## Quick Reference

### Root Justfile Pattern

**Put everything in root justfile** for tab completion to work:

```just
# justfile (root)
set quiet
set dotenv-load

# Imports: merged into root namespace
import 'just/dev.just'

# Modules: namespaced with :: syntax (specify path)
mod go 'just/go.just'           # go::build, go::test
mod docker 'just/docker.just'   # docker::build, docker::push
mod lua 'just/lua.just'         # lua::install, lua::check

default:
    just --list
```

### Module Example

```just
# just/go.just - called as go::build, go::test, etc.
VERSION := `git describe --tags --always 2>/dev/null || echo "dev"`
BIN_DIR := env_var("PWD") / "bin"

[group('go')]
build tool:
    @mkdir -p {{BIN_DIR}}
    go build -o {{BIN_DIR}}/{{tool}} .

[group('go')]
test tool:
    go test -race -cover ./...

[group('go')]
lint:
    golangci-lint run
```

### Import vs Module

| Feature | `import 'just/file.just'` | `mod name 'just/name.just'` |
|---------|---------------------------|----------------------------|
| Namespace | Merged into parent | Separate (`name::*`) |
| Calling | `just recipe` | `just name::recipe` |
| Working dir | Parent justfile's dir | Module's directory |
| Best for | dev.just only | All other modules |

**Rule:** Use `import` only for `dev.just`. Use `mod` for everything else.

### Module Working Directory

**Critical:** Module recipes run from the module's directory, not the invoking justfile's directory.

Add `[no-cd]` to recipes that need to run from the invocation directory:

```just
# just/git.just
[no-cd]
status:
    git submodule status

[no-cd]
update:
    git submodule update --remote --merge
```

**When to use `[no-cd]`:** Git operations, commands operating on project root, commands expecting files relative to where `just` was invoked.

Use `{{invocation_directory()}}` as an alternative for specific paths.

### Listing Recipes

```bash
just --list                    # Shows modules collapsed
just --list --list-submodules  # Shows all module recipes expanded
just --groups                  # List all recipe groups
just lua::                     # Tab-complete shows lua recipes
```

## Organizing Recipes

Use **modules** for namespacing (separate files) and **groups** for cross-cutting organization (tags).

```just
[group('dev')]
dev: setup
    ./run-dev.sh

[group('dev')]
[group('ci')]         # Recipe in multiple groups
test:
    cargo test
```

### Intelligent Grouping Strategy

| Group | Purpose |
|-------|---------|
| `dev` | Local development (watch, run, setup) |
| `build` | Compilation, bundling |
| `test` | Testing (unit, integration, e2e) |
| `ci` | CI pipeline tasks (often overlaps) |
| `deploy` | Deployment to environments |
| `maintenance` | Cleanup, dependency updates |

See `references/groups.md` for detailed patterns and fzf-tab integration.

## Command Interception

The just-interceptor hook blocks raw CLI commands and redirects Claude to project-standard just recipes. When Claude tries to run `npm install` or `docker compose up`, the hook denies it and suggests the mapped just recipe instead.

To set up interception for a project, create `.claude/just-interceptor.json` with command-to-recipe mappings. See `references/interceptor.md` for full configuration guide and examples.

## Shell Completions

Check if completions exist: `type _just &>/dev/null`

If missing, generate and source them:

```bash
just --completions zsh > "${XDG_CONFIG_HOME:-$HOME/.config}/just/completions.zsh"
# Add to ~/.zshrc: source "${XDG_CONFIG_HOME:-$HOME/.config}/just/completions.zsh"
```

For fzf-tab preview integration, see `references/groups.md`.

## References

Detailed syntax and patterns in `references/`:

| File | Contents |
|------|----------|
| `interceptor.md` | Command interception setup, config format, redirect patterns |
| `groups.md` | Recipe groups, intelligent grouping strategy, fzf-tab integration |
| `modules.md` | Module system (`mod`), namespacing with `::`, import vs mod |
| `settings.md` | All justfile settings (`set quiet`, `set dotenv-load`, etc.) |
| `recipes.md` | Recipe syntax, parameters, dependencies, shebang recipes |
| `attributes.md` | Recipe attributes (`[group]`, `[confirm]`, `[private]`, etc.) |
| `functions.md` | Built-in functions (`env()`, `os()`, `join()`, etc.) |
| `syntax.md` | Variables, strings, conditionals, imports |
