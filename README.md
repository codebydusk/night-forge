# ⚑ Night Forge

**The dark-themed, high-contrast blueprint for a unified multi-editor ecosystem.**

Night Forge is the centralized configuration vault for my development environments. It maintains absolute consistency in aesthetics, formatting, and keybindings across a hybrid Windows and openSUSE WSL architecture.

It is specifically tuned for building heavy frontend architectures (React, Redux, Micro-frontends) alongside robust backend and systems work (Rust, NodeJS, TypeScript, C/C++).

---

## ⚙️ The Ecosystem

This repository acts as the single source of truth for the following environments:

* **VS Code:** Highly customized theme block, strict JSONC/TypeScript formatting, and optimized syntax token targeting.
* **Antigravity IDE 2.0:** Native Gemini 3.5 Flash integration settings, custom agent configurations, and Roaming-path setups.
* **Neovim:** Lua-based configurations geared for speed inside WSL (Zsh).
* **Zed:** Minimalist keymaps and high-performance settings.
* **JetBrains (WebStorm & Android Studio):** Centralized `.ideavimrc`, code styles, and custom keymaps.

---

## 📂 Repository Structure

```text
night-forge/
├── backup.ps1              # The automated fetch & sync engine
├── vscode/                 # VS Code settings & keybindings
├── antigravity/            # Antigravity IDE 2.0 configurations
├── nvim/                   # Neovim init.lua and plugin configs
├── zed/                    # Zed keymaps and environment settings
├── webstorm/               # Shared JetBrains configurations (.ideavimrc)
└── android-studio/         # Dynamic codestyles and keymaps
