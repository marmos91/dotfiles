- Don't mention Claude Code in commits or PRs
- Keep commit messages concise
- Never hardcode secrets in commands, settings, or allow-lists. AWS, kube, git-identity and Mimir credentials live in sops (`~/.config/nix-darwin/home/secrets/secrets.yaml`, rendered under `~/.config` and `~/.aws`) and in 1Password. Read them from the environment or the rendered files; never paste a key value.

@RTK.md

# graphify
Any input → knowledge graph. When the user types `/graphify`, use the installed graphify skill (`~/.claude/skills/graphify/SKILL.md`) before anything else.
