# nix-bonsai 🌳

A bonsai tree generator written in **100% pure Nix**, inspired by [cbonsai](https://gitlab.com/jallbrit/cbonsai).

## Features

- **Pure Nix Implementation**: Tree generation algorithm written entirely in Nix expressions
- **Live Animation Mode**: Watch your bonsai grow in real-time
- **Print Mode**: Generate a static tree for display in your terminal
- **Customizable**: Adjust seed, life, multiplier, and animation speed
- **ANSI Colors**: Beautiful colored output with trunk, branches, and leaves

## Installation

### Run directly with Nix Flakes

```bash
# Live animation mode (default)
nix run github:your-username/nix-bonsai

# With custom seed
nix run github:your-username/nix-bonsai -- --seed 12345

# Print mode (static output)
nix run github:your-username/nix-bonsai -- --print
```

### Local development

```bash
# Clone the repository
git clone https://github.com/your-username/nix-bonsai
cd nix-bonsai

# Run directly
nix run .

# Or build and run
nix build .
./result/bin/nix-bonsai
```

## Usage

```
nix-bonsai - A bonsai tree generator in pure Nix

Usage: nix-bonsai [OPTIONS]

Options:
  -s, --seed INT        Random seed (default: random)
  -L, --life INT        Tree life/growth amount (default: 32)
  -t, --time FLOAT      Animation delay in seconds (default: 0.08)
  -M, --multiplier INT  Branch multiplier (default: 5)
  -p, --print           Print mode: show final tree and exit
  -h, --help            Show this help
```

### Examples

```bash
# Grow a large tree slowly
nix run . -- --life 50 --time 0.1

# Quick small tree
nix run . -- --life 20 --time 0.01

# Static tree for .bashrc
nix run . -- --print --seed 42

# Reproducible tree with specific seed
nix run . -- --seed 12345 --life 40 --multiplier 7
```

### Add to your shell

Add a bonsai tree to your terminal startup:

```bash
# In your ~/.bashrc or ~/.zshrc
nix run github:your-username/nix-bonsai -- --print --seed $RANDOM
```

## How It Works

The entire tree generation algorithm is implemented in pure Nix:

1. **RNG Module** (`lib/rng.nix`): A Linear Congruential Generator for deterministic randomness
2. **Tree Module** (`lib/tree.nix`): Recursive growth algorithm that creates trunk, branches, and leaves
3. **Render Module** (`lib/render.nix`): Converts tree structure to ANSI escape sequences
4. **Base Module** (`lib/base.nix`): ASCII art pots/bases

The Nix code generates all animation frames at evaluation time. A thin shell wrapper handles:
- Terminal setup (hide cursor, clear screen)
- Frame timing for animation
- User input handling

## Architecture

```
┌─────────────────────────────────────────────┐
│              nix-bonsai                     │
├─────────────────────────────────────────────┤
│  flake.nix                                  │
│  ├── Defines packages and apps              │
│  └── Shell wrapper for animation            │
├─────────────────────────────────────────────┤
│  lib/                                       │
│  ├── default.nix  - Library entry point     │
│  ├── rng.nix      - Random number generator │
│  ├── tree.nix     - Tree growth algorithm   │
│  ├── render.nix   - ANSI frame renderer     │
│  └── base.nix     - Pot ASCII art           │
└─────────────────────────────────────────────┘
```

## Differences from cbonsai

| Feature | cbonsai | nix-bonsai |
|---------|---------|------------|
| Language | C + ncurses | Pure Nix |
| Runtime | Native binary | Nix evaluation |
| Dependencies | ncurses | Nix |
| Animation | Real-time | Pre-computed frames |
| Interactive | Yes | No (but animated) |

## License

MIT License - feel free to use, modify, and distribute!

## Credits

- Original [cbonsai](https://gitlab.com/jallbrit/cbonsai) by jallbrit
- Inspired by [bonsai.sh](https://github.com/thiderman/bonsai.sh) and the JavaScript bonsai generator

