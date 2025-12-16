# Pot/base ASCII art for the bonsai tree
{ lib }:

let
  # ANSI color codes
  colors = {
    reset = "\\033[0m";
    brown = "\\033[38;5;94m";
    darkBrown = "\\033[38;5;52m";
    soil = "\\033[38;5;95m";
    pot = "\\033[38;5;130m";
    potDark = "\\033[38;5;88m";
    potLight = "\\033[38;5;166m";
  };

  # Base style 1 - Classic rectangular pot
  base1 = {
    width = 15;
    height = 4;
    trunkX = 7; # X position where trunk connects
    art = [
      "───────────────"
      "\\             /"
      " \\___________/ "
      "  \\_________/  "
    ];
    coloredArt = [
      "${colors.potDark}───────────────${colors.reset}"
      "${colors.pot}\\${colors.soil}#############${colors.pot}/${colors.reset}"
      "${colors.pot} \\${colors.potDark}___________${colors.pot}/ ${colors.reset}"
      "${colors.pot}  \\${colors.potDark}_________${colors.pot}/  ${colors.reset}"
    ];
  };

  # Base style 2 - Round pot
  base2 = {
    width = 11;
    height = 3;
    trunkX = 5;
    art = [
      "───────────"
      "(_________)"
      " \\_______/ "
    ];
    coloredArt = [
      "${colors.potDark}───────────${colors.reset}"
      "${colors.pot}(${colors.soil}#########${colors.pot})${colors.reset}"
      "${colors.pot} \\_______/ ${colors.reset}"
    ];
  };

  # Base style 3 - Wide shallow pot
  base3 = {
    width = 21;
    height = 3;
    trunkX = 10;
    art = [
      "─────────────────────"
      "\\                   /"
      " \\_________________/ "
    ];
    coloredArt = [
      "${colors.potDark}─────────────────────${colors.reset}"
      "${colors.pot}\\${colors.soil}###################${colors.pot}/${colors.reset}"
      "${colors.pot} \\_________________/ ${colors.reset}"
    ];
  };

  # Base style 0 - No pot (for printing mode)
  base0 = {
    width = 1;
    height = 0;
    trunkX = 0;
    art = [];
    coloredArt = [];
  };

  bases = [ base0 base1 base2 base3 ];

  # Get a base by index (default to base1 if out of range)
  getBase = index:
    if index >= 0 && index < builtins.length bases
    then builtins.elemAt bases index
    else base1;

  # Calculate the position for the base given tree dimensions
  getBasePosition = base: treeWidth: treeHeight:
    {
      x = (treeWidth / 2) - (base.width / 2);
      y = treeHeight;
    };

in
{
  inherit bases getBase getBasePosition colors;
  
  # Default base (classic pot)
  default = base1;
  
  # Number of available base styles
  numBases = builtins.length bases;
}

