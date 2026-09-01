{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zmk-nix }: let
    inherit (nixpkgs) lib;
    forAllSystems = lib.genAttrs (lib.attrNames zmk-nix.packages);

    src = lib.sourceFilesBySuffices self [
      ".board" ".cmake" ".conf" ".defconfig" ".dts" ".dtsi"
      ".json" ".keymap" ".overlay" ".shield" ".yml" "_defconfig"
    ];

    # Bumped by `nix run .#update`
    zephyrDepsHash = "sha256-777sDty25V5VbWgXjYKpy1NEW/rWJEihU7DRdqfk30I=";

    keyboards = [
      { name = "grace"; displayName = "Grace"; }
      { name = "iris"; displayName = "Iris"; }
      { name = "valentina"; displayName = "Valentina"; }
    ];

    meta = {
      description = "ZMK firmware for Grace, Iris, and Valentina";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };

    mkPackages = system: let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (zmk-nix.legacyPackages.${system}) buildSplitKeyboard buildKeyboard;

      mkCorne = { name, displayName, westDeps ? null }:
        let
          overlayKeymap = ./config + "/${name}/corne.keymap";
          overlayConf = ./config + "/${name}/corne.conf";
        in buildSplitKeyboard ({
          name = "${name}-firmware";
          inherit src meta zephyrDepsHash;
          board = "nice_nano//zmk";
          shield = "corne_%PART% nice_view_adapter nice_view";
          extraCmakeFlags = [
            ''-DCONFIG_ZMK_KEYBOARD_NAME="${displayName}"''
            ''-DCONFIG_BT_DEVICE_NAME="${displayName}"''
          ];
          # Per-keyboard layout: add config/<name>/corne.keymap (optional corne.conf).
          postPatch = lib.optionalString (builtins.pathExists overlayKeymap) ''
            cp ${overlayKeymap} config/corne.keymap
          '' + lib.optionalString (builtins.pathExists overlayConf) ''
            cat ${overlayConf} >> config/corne.conf
          '';
        } // lib.optionalAttrs (westDeps != null) { inherit westDeps; });

      first = builtins.head keyboards;
      seed = mkCorne first;
      cornePkgs = lib.listToAttrs (
        [{ inherit (first) name; value = seed; }]
        ++ map (kb: {
          inherit (kb) name;
          value = mkCorne (kb // { westDeps = seed.westDeps; });
        }) (builtins.tail keyboards)
      );

      reset = buildKeyboard {
        name = "settings-reset";
        inherit src meta zephyrDepsHash;
        westDeps = seed.westDeps;
        board = "nice_nano//zmk";
        shield = "settings_reset";
      };

      all = pkgs.linkFarm "zmk-firmware" (
        lib.concatMap (kb: [
          { name = "${kb.name}_left.uf2"; path = "${cornePkgs.${kb.name}}/zmk_left.uf2"; }
          { name = "${kb.name}_right.uf2"; path = "${cornePkgs.${kb.name}}/zmk_right.uf2"; }
        ]) keyboards
        ++ [{ name = "settings_reset.uf2"; path = "${reset}/zmk.uf2"; }]
      );

      flashPkgs = lib.listToAttrs (map (kb: {
        name = "flash-${kb.name}";
        value = zmk-nix.packages.${system}.flash.override { firmware = cornePkgs.${kb.name}; };
      }) keyboards);
    in cornePkgs // flashPkgs // {
      inherit all reset;
      default = all;
      firmware = seed;
      flash = flashPkgs."flash-${first.name}";
      update = zmk-nix.packages.${system}.update;
    };
  in {
    packages = forAllSystems mkPackages;

    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = zmk-nix.devShells.${system}.default.override {
        extraPackages = [ pkgs.just ];
      };
    });
  };
}
