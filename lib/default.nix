# Main library entry point for nix-bonsai
{ lib }:

let
  rng = import ./rng.nix { inherit lib; };
  base = import ./base.nix { inherit lib; };
  tree = import ./tree.nix { inherit lib rng; };
  render = import ./render.nix { inherit lib base; };
in
{
  inherit rng base tree render;

  # Generate a complete bonsai with the given parameters
  generateBonsai = seed: life: multiplier:
    let
      treeResult = tree.growTree seed life multiplier;
    in
    render.renderTree treeResult;

  # Generate animation frames for the tree growth
  generateFrames = seed: life: multiplier:
    let
      treeResult = tree.growTree seed life multiplier;
    in
    render.generateFrames treeResult;

  # Generate a shell script fragment that outputs frames (for live mode)
  generateScript = seed: life: multiplier:
    let
      treeResult = tree.growTree seed life multiplier;
      frames = render.generateFrames treeResult;
      # Add frame separator after each frame
      frameStrings = map (frame: frame + "\n---FRAME---") frames;
    in
    lib.concatStringsSep "\n" frameStrings;

  # Generate static output (print mode, no animation)
  generateStatic = seed: life: multiplier:
    let
      treeResult = tree.growTree seed life multiplier;
    in
    render.renderTree treeResult;
}

