# Usage

Edit `config/corne.keymap`, then run `just build grace`. UF2s land in `build/` in about 1 minute.

Boards: **grace**, **iris**, **valentina**. Swap the name in any command.

## First time

1. `cd` into this repo
2. `direnv allow` (or `nix develop`) so `just` is on `PATH`
3. `just build grace`

First Nix fetch is 10–20 minutes. After that, a keymap-only rebuild is about 1 minute.

## Change a keymap

1. Edit `config/corne.keymap` (shared by all three boards)
2. `just build grace`
3. `just flash grace` — double-tap reset on each half when prompted

Flash copies `build/grace_left.uf2` then `build/grace_right.uf2` onto the nice!nano.

Rebuild automatically while you edit:

```
just watch grace
```

## Commands

| Command | What it does |
|---|---|
| `just build grace` | left+right UF2s → `build/` |
| `just build all` | Grace, Iris, Valentina, plus settings reset |
| `just flash iris` | rebuild, then flash both halves |
| `just watch valentina` | rebuild when `config/` changes |
| `just overlay iris` | give Iris its own keymap copy |
| `just reset` | settings-reset UF2 → `build/settings_reset.uf2` |
| `just update` | bump ZMK / west and `zephyrDepsHash` |

`just` with no arguments lists the same recipes.

## Different layout on one board

Today all three share `config/corne.keymap`. To diverge Iris:

1. `just overlay iris`
2. Edit `config/iris/corne.keymap`
3. `just build iris`

Optional extra Kconfig: `config/iris/corne.conf` (appended to the shared `config/corne.conf`).

Nix flakes only see git-tracked files. `just overlay` runs `git add -N` so the new keymap is visible to the build. Commit it before pushing.

## GitHub CI

Push to `main` (or open a PR). The **CI** workflow runs `nix build .#all` and uploads a `zmk_firmware` artefact with:

- `grace_left.uf2` / `grace_right.uf2`
- `iris_left.uf2` / `iris_right.uf2`
- `valentina_left.uf2` / `valentina_right.uf2`
- `settings_reset.uf2`

Weekly workflows bump flake inputs and ZMK west pins.

## BLE names

Names are set in `flake.nix`, not `config/corne.conf`: Grace, Iris, Valentina.
