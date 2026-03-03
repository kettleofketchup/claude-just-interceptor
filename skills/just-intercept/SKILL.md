---
name: just-intercept
description: Add a new command redirect to .claude/just-interceptor.json. Use when the user wants to intercept a raw CLI command and redirect it to a just recipe. Walks through category, pattern, just command, and reason via guided questions.
---

# Add Just Interceptor Redirect

Guide the user through adding a new redirect entry to `.claude/just-interceptor.json`.

## Entry Modes

- **With args:** `/just-intercept <command>` — the argument is the example command to intercept. Pre-fill suggestions from it.
- **Without args:** `/just-intercept` — ask the user what command to intercept first.

## Flow

Follow these steps **sequentially**, one question at a time using `AskUserQuestion`.

### Step 0: Get the command (only if no args)

If the user provided no arguments, ask:

> "What command should be intercepted?"

Use a free-text question. Once you have the command, proceed.

### Step 1: Category

Infer the category from the **first token** of the command (e.g., `docker` from `docker compose up`, `npm` from `npm install`).

Ask with `AskUserQuestion`:
- Suggest the inferred category as the first option marked "(Recommended)"
- Add 1-2 other reasonable options if applicable
- Let user pick or type custom

### Step 2: Pattern

Generate a regex pattern anchored with `^` from the command. Strip trailing arguments/flags that look dynamic. Examples:
- `docker compose up -d` → `^docker compose up`
- `npm install --save foo` → `^npm install`
- `go test ./...` → `^go test`
- `kubectl apply -f deployment.yaml` → `^kubectl apply`

Ask with `AskUserQuestion`:
- First option: the suggested pattern with "(Recommended)"
- Second option: a broader pattern (e.g., `^docker compose` to catch up/down/restart)
- Let user describe what they want if neither fits — then refine into a regex for them

### Step 3: Just command

Run `just --list --list-submodules --unsorted 2>/dev/null` and scan the output for recipes that relate to the intercepted command. Match by:
- Category + action (e.g., `docker::up` for `docker compose up`)
- Category alone (e.g., any `docker::*` recipes)

Ask with `AskUserQuestion`:
- If matching recipes found: suggest the best match as "(Recommended)", list other related recipes as options
- If no matches found: offer to **create the recipe** as the recommended option, with a second option to type a custom command
- Always allow custom input

**Creating a missing recipe:**

If the user chooses to create the recipe:

1. Determine the module file: `just/<category>.just` (e.g., `just/docker.just`)
2. Derive the recipe name from the command action (e.g., `up` from `docker compose up`, `install` from `npm install`)
3. If the module file **exists**, append the new recipe to it
4. If the module file **does not exist**, create it with the recipe and add a `mod` line to the root `justfile`
5. Use the `/just` skill's conventions: `[group('<category>')]` attribute, `[no-cd]` if the command needs project root context
6. The recipe body should run the original command — the user can refine it later
7. Set the just_command to `just <category>::<action>` and continue the flow

Example generated recipe for `docker compose up`:

```just
# just/docker.just
[group('docker')]
up *args:
    docker compose up {{args}}
```

Example generated recipe for `npm install`:

```just
# just/npm.just
[group('npm')]
[no-cd]
install *args:
    npm install {{args}}
```

### Step 4: Reason

Suggest a short reason — **under 10 words, no period, lowercase start**. Describe WHY the just recipe is better than the raw command. Examples:
- "project-standard compose config"
- "build with correct ldflags and output dir"
- "tests with race detection and coverage"
- "install with lockfile and correct cwd"

Ask with `AskUserQuestion`:
- First option: your suggested reason "(Recommended)"
- Second option: an alternative short reason
- Let user type custom

### Step 5: Write the config

After collecting all 4 fields:

1. **Read** `.claude/just-interceptor.json` if it exists
2. If it **does not exist**, create it with this structure:
   ```json
   {
     "redirects": []
   }
   ```
3. **Append** the new entry to the `redirects` array:
   ```json
   {
     "category": "<category>",
     "enabled": true,
     "pattern": "<pattern>",
     "just_command": "<just_command>",
     "reason": "<reason>"
   }
   ```
4. Write the file back

### Step 6: Confirm

Show the user what was added:

```
Added redirect to .claude/just-interceptor.json:

  <pattern>  →  <just_command>
  Category: <category>
  Reason: <reason>
```
