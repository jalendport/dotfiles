<h1 align="center">dotfiles</h1>

These are my personal dotfiles for macOS, linked into place by [Dotbot](https://github.com/anishathalye/dotbot). They cover the shell and terminal (zsh, [Ghostty](https://ghostty.org), [Starship](https://starship.rs)), a few global git and macOS bits, and the shared configuration for the AI coding agents I use day to day.

## What's inside

- **`zshrc`, `zprofile`, `zsh/`** - the shell setup, with plugins and the prompt split into their own files
- **`ghostty/`** - Ghostty terminal config
- **`starship/`** - the Starship prompt
- **`gitignore-global`** - a global gitignore, wired in through `core.excludesfile`
- **`hushlogin`** - silences the login banner
- **`bettermouse.plist`** - BetterMouse settings
- **`ai/`** - one shared `AGENTS.md` that gets linked into [Claude Code](https://code.claude.com), [Codex](https://developers.openai.com/codex), [Grok](https://docs.x.ai), and [Antigravity](https://antigravity.google), plus per-tool settings, status lines, and hooks, and a `skills/` directory that is linked into each tool's own skills folder so every agent sees the same set

## Installation

Clone the repo wherever you keep code (the installer links `~/.dotfiles` to it for you), then run the install script:

```sh
git clone --recursive https://github.com/jalendport/dotfiles.git
cd dotfiles
./install
```

The script syncs the Dotbot submodule and runs `install.conf.yaml`, which creates the symlinks, sets the global gitignore, and writes the agent configs. Re-running it is safe, and a tracked git hook re-runs Dotbot after every `git pull`, so the links stay current without you thinking about it.

These are mine, so they're opinionated and a tad specific to my machine; fork it and strip out whatever you don't need. Everything here is licensed [0BSD](LICENSE.md), so you can lift any piece without attribution.

<hr>

<p align="center">Made by <a href="https://jalendport.com">Jalen Davenport</a></p>
