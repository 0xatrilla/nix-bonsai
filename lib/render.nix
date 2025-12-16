# ANSI renderer and frame generator for bonsai tree
{ lib, base }:

let
  # Use actual escape character (ASCII 27 / 0x1B) via JSON unicode escape
  # This embeds the real ESC character, no interpretation needed by shell
  esc = builtins.fromJSON ''"\u001b"'';
  
  ansi = {
    reset = "${esc}[0m";
    clear = "${esc}[2J";
    home = "${esc}[H";
    
    # Move cursor to position (1-indexed)
    moveTo = x: y: "${esc}[${toString y};${toString x}H";
    
    # Colors
    colors = {
      brown = "${esc}[38;5;94m";      # Trunk
      darkBrown = "${esc}[38;5;52m";  # Old trunk
      green = "${esc}[38;5;34m";      # Leaves
      lightGreen = "${esc}[38;5;82m"; # Young leaves
      yellow = "${esc}[38;5;226m";    # Autumn leaves
      red = "${esc}[38;5;196m";       # Berries
      white = "${esc}[38;5;255m";     # Flowers
    };
    
    # Bold
    bold = "${esc}[1m";
  };
  
  # Choose color based on segment type and properties
  getSegmentColor = segment:
    if segment.isLeaf or false then
      # Leaves get various colors
      if segment.char == "&" then ansi.colors.green
      else if segment.char == "*" then ansi.colors.lightGreen
      else if segment.char == "%" then ansi.colors.yellow
      else if segment.char == "#" then ansi.colors.red
      else if segment.char == "@" then ansi.colors.white
      else ansi.colors.green
    else if segment.type == 0 then  # trunk
      ansi.colors.brown
    else if segment.type == 1 || segment.type == 2 then  # shoots
      ansi.colors.darkBrown
    else if segment.type == 3 then  # dying
      ansi.colors.brown
    else
      ansi.colors.green;
  
  # Render a single segment with ANSI codes
  renderSegment = segment: xOffset: yOffset:
    let
      x = segment.x + xOffset + 1;  # ANSI is 1-indexed
      y = segment.y + yOffset + 1;
      color = getSegmentColor segment;
    in
    "${ansi.moveTo x y}${color}${segment.char}${ansi.reset}";
  
  # Create a 2D grid representation
  createGrid = width: height: defaultChar:
    let
      row = lib.genList (_: defaultChar) width;
    in
    lib.genList (_: row) height;
  
  # Place a character in the grid
  placeChar = grid: x: y: char:
    let
      height = builtins.length grid;
      width = if height > 0 then builtins.length (builtins.head grid) else 0;
    in
    if x >= 0 && x < width && y >= 0 && y < height then
      lib.imap0 (rowIdx: row:
        if rowIdx == y then
          lib.imap0 (colIdx: c:
            if colIdx == x then char else c
          ) row
        else row
      ) grid
    else grid;
  
  # Convert grid to string with ANSI colors
  gridToString = grid: segments: xOffset: yOffset:
    let
      # Create a map of position -> segment for efficient lookup
      segmentMap = lib.foldl' (acc: seg:
        acc // { "${toString seg.x},${toString seg.y}" = seg; }
      ) {} segments;
      
      renderRow = rowIdx: row:
        let
          renderCell = colIdx: char:
            let
              key = "${toString (colIdx - xOffset)},${toString (rowIdx - yOffset)}";
              segment = segmentMap.${key} or null;
              color = if segment != null then getSegmentColor segment else "";
            in
            if segment != null then "${color}${char}${ansi.reset}"
            else char;
        in
        lib.concatStrings (lib.imap0 renderCell row);
    in
    lib.concatStringsSep "\n" (lib.imap0 renderRow grid);
  
  # Generate animation frames
  # Each frame shows one more segment than the previous
  generateFrames = treeResult:
    let
      segments = treeResult.segments;
      width = treeResult.width + 10;  # Add padding
      height = treeResult.height + 8;  # Space for pot
      xOffset = 5;
      yOffset = 2;
      
      # Get the pot
      pot = base.default;
      potX = (width / 2) - (pot.width / 2);
      potY = treeResult.height + yOffset + 1;
      
      # Create base grid
      emptyGrid = createGrid width height " ";
      
      # Add pot to grid
      addPotToGrid = grid:
        lib.foldl' (g: lineData:
          let
            y = potY + lineData.idx;
            chars = lib.stringToCharacters lineData.line;
          in
          lib.foldl' (g2: charData:
            placeChar g2 (potX + charData.idx) y charData.char
          ) g (lib.imap0 (i: c: { idx = i; char = c; }) chars)
        ) grid (lib.imap0 (i: l: { idx = i; line = l; }) pot.art);
      
      gridWithPot = addPotToGrid emptyGrid;
      
      # Generate progressive frames
      makeFrame = numSegments:
        let
          visibleSegments = lib.take numSegments segments;
          gridWithTree = lib.foldl' (g: seg:
            placeChar g (seg.x + xOffset) (seg.y + yOffset) seg.char
          ) gridWithPot visibleSegments;
        in
        "${ansi.clear}${ansi.home}" + gridToString gridWithTree visibleSegments xOffset yOffset;
      
      # Generate a frame for every segment for detailed animation
      totalSegments = builtins.length segments;
      
      # Show every individual segment for smooth, detailed growth
      frameIndices = lib.genList (n: n + 1) totalSegments;
    in
    map makeFrame frameIndices;
  
  # Render complete tree (static, no animation)
  renderTree = treeResult:
    let
      frames = generateFrames treeResult;
    in
    lib.last frames;

in
{
  inherit
    ansi
    renderSegment
    renderTree
    generateFrames
    createGrid
    placeChar
    gridToString
    getSegmentColor;
}

