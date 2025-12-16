{
  description = "A bonsai tree generator written in pure Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = import ./lib { inherit (pkgs) lib; };
      in
      {
        packages.default = self.packages.${system}.nix-bonsai;

        packages.nix-bonsai = pkgs.writeShellApplication {
          name = "nix-bonsai";
          runtimeInputs = [ pkgs.coreutils pkgs.ncurses ];
          text = ''
            # Default configuration
            SEED="''${BONSAI_SEED:-$RANDOM}"
            LIFE="''${BONSAI_LIFE:-32}"
            TIME="''${BONSAI_TIME:-0.08}"
            MULTIPLIER="''${BONSAI_MULTIPLIER:-5}"
            PRINT_MODE=false

            # Parse command line arguments
            while [[ $# -gt 0 ]]; do
              case $1 in
                -s|--seed) SEED="$2"; shift 2 ;;
                -L|--life) LIFE="$2"; shift 2 ;;
                -t|--time) TIME="$2"; shift 2 ;;
                -M|--multiplier) MULTIPLIER="$2"; shift 2 ;;
                -p|--print) PRINT_MODE=true; shift ;;
                -h|--help)
                  echo "nix-bonsai - A bonsai tree generator in pure Nix"
                  echo ""
                  echo "Usage: nix-bonsai [OPTIONS]"
                  echo ""
                  echo "Options:"
                  echo "  -s, --seed INT        Random seed (default: random)"
                  echo "  -L, --life INT        Tree life/growth amount (default: 32)"
                  echo "  -t, --time FLOAT      Animation delay in seconds (default: 0.08)"
                  echo "  -M, --multiplier INT  Branch multiplier (default: 5)"
                  echo "  -p, --print           Print mode: show final tree and exit"
                  echo "  -h, --help            Show this help"
                  exit 0
                  ;;
                *) echo "Unknown option: $1"; exit 1 ;;
              esac
            done

            if $PRINT_MODE; then
              # Static print mode - just output the final tree
              # shellcheck disable=SC2086
              ${pkgs.nix}/bin/nix eval --raw --impure \
                --expr "let lib = import ${self}/lib { lib = (import ${nixpkgs} {}).lib; }; in lib.generateStatic $SEED $LIFE $MULTIPLIER" \
                | while IFS= read -r line; do
                    # Output directly - escape chars are already embedded
                    printf '%s\n' "$line"
                  done
              echo ""
              echo "Seed: $SEED"
            else
              # Live animation mode
              cleanup() {
                tput cnorm  # Show cursor
                tput sgr0   # Reset colors
                echo ""
              }
              trap cleanup EXIT INT TERM

              tput civis  # Hide cursor
              clear

              # Generate and display frames
              # shellcheck disable=SC2086
              ${pkgs.nix}/bin/nix eval --raw --impure \
                --expr "let lib = import ${self}/lib { lib = (import ${nixpkgs} {}).lib; }; in lib.generateScript $SEED $LIFE $MULTIPLIER" \
                | while IFS= read -r line; do
                    if [[ "$line" == "---FRAME---" ]]; then
                      sleep "$TIME"
                    else
                      # Output directly - escape chars are already embedded
                      printf '%s\n' "$line"
                    fi
                  done
              
              # Keep final frame visible
              echo ""
              echo "Tree grown with seed: $SEED"
              read -r -p "Press Enter to exit..."
            fi
          '';
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.nix-bonsai}/bin/nix-bonsai";
        };

        devShells.default = pkgs.mkShell {
          packages = [ pkgs.nix ];
        };
      }
    );
}

