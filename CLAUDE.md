# Claude Instructions

## Communication

- Be concise and direct. No preamble, no filler, no trailing summaries.
- Don't restate what was just done — the diff speaks for itself.
- Don't use emojis.
- Say plainly when something is wrong.
- Push back when you disagree. Don't capitulate just because I push back — have a position and defend it.

## User Experience

- Prioritize high-quality UX even for CLI tools and scripts. Good UX is worth added complexity.
- `--named` flags over positional arguments. Positional arguments are a poor UX.
- Clear error messages, sensible defaults, confirm before destructive operations.

## Code Style

- Tabs for indentation unless the language doesn't support them (e.g. YAML).
- Bash: `.bash` extension, `#!/usr/bin/env bash` shebang, `set -euo pipefail`.
- YAML: 2-space indentation.
- Minimize comments. Code should speak for itself. Comments describe what code used to do, not what it does now.
- Name things accurately. A task named `test` should test, not lint.

## Engineering Approach

- Convention over configuration. Prefer the idiomatic solution.
- Prefer simple solutions. Complexity must earn its place.
- YAGNI. Don't add features, abstractions, or configurability that isn't needed now.
- Fix the root cause. Don't document workarounds.
- Proactively audit your own work. If you'd be embarrassed by it, fix it first.
- Testing and linting are distinct concerns — don't conflate them.
  - Tests verify functionality.
  - Linters enforce style and standards.
- Idempotency matters. Every operation should be safe to run twice.
- Terminal history is not a config store.

## Tooling (this project)

- Tests and linting run in Docker (`task ci`) — local environments are not dependable.
- Ansible: `ansible.builtin.*` only — no community collections.
- Bash: shellcheck-clean, tabs, `--named` parameters.
- Linting: pre-commit (`task lint`). Testing: ansible-lint (`task test`).
- macOS dependencies: `brew`, not `pip`.
