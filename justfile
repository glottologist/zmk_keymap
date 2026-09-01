# Shared keymap: config/corne.keymap
# Per-board keymap: just overlay iris  then edit config/iris/corne.keymap
# Names: grace | iris | valentina

default:
    @just --list

# Build UF2s into build/. Name: grace | iris | valentina | all
build name="grace":
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p build
    if [ "{{name}}" = "all" ]; then
      nix build -L .#all --out-link result
      for f in result/*.uf2; do install -D -m 0644 "$f" "build/$(basename "$f")"; done
      ls -l build/
      exit 0
    fi
    nix build -L .#{{name}} --out-link result-{{name}}
    install -D -m 0644 result-{{name}}/zmk_left.uf2 build/{{name}}_left.uf2
    install -D -m 0644 result-{{name}}/zmk_right.uf2 build/{{name}}_right.uf2
    ls -l build/{{name}}_left.uf2 build/{{name}}_right.uf2

# Same as `just build all`
all:
    just build all

# Rebuild, then flash both halves (double-tap reset when prompted)
flash name="grace": (build name)
    nix run .#flash-{{name}}

# Build settings-reset UF2
reset:
    nix build -L .#reset --out-link result-reset
    mkdir -p build
    install -D -m 0644 result-reset/zmk.uf2 build/settings_reset.uf2
    ls -l build/settings_reset.uf2

# Copy the shared keymap so this board can diverge
overlay name:
    mkdir -p config/{{name}}
    if [ ! -f config/{{name}}/corne.keymap ]; then cp config/corne.keymap config/{{name}}/corne.keymap; fi
    git add -N config/{{name}}/corne.keymap
    @echo "Edit config/{{name}}/corne.keymap  then: just build {{name}}"

# Rebuild on keymap/conf edits
watch name="grace":
    watchexec -e keymap,conf,json -w config -- just build {{name}}

# Bump west / ZMK and zephyrDepsHash
update:
    nix run .#update
