# Shared keymap: config/corne.keymap
# Per-board keymap: just overlay iris  then edit config/iris/corne.keymap
# Names: grace | iris | valentina

default:
    @just --list

# Build left+right UF2s into build/
build name="grace":
    nix build -L .#{{name}} --out-link result-{{name}}
    mkdir -p build
    cp -L result-{{name}}/zmk_left.uf2 build/{{name}}_left.uf2
    cp -L result-{{name}}/zmk_right.uf2 build/{{name}}_right.uf2
    ls -l build/{{name}}_left.uf2 build/{{name}}_right.uf2

# Build all three boards plus settings reset
all:
    nix build -L .#all --out-link result
    mkdir -p build
    cp -L result/*.uf2 build/
    ls -l build/

# Rebuild, then flash both halves (double-tap reset when prompted)
flash name="grace": (build name)
    nix run .#flash-{{name}}

# Build settings-reset UF2
reset:
    nix build -L .#reset --out-link result-reset
    mkdir -p build
    cp -L result-reset/zmk.uf2 build/settings_reset.uf2
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
