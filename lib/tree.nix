# Tree growth algorithm for bonsai generation
# Enhanced version with more detailed branching and foliage
{ lib, rng }:

let
  # Branch types
  branchTypes = {
    trunk = 0;
    shootLeft = 1;
    shootRight = 2;
    branchLeft = 3;   # Secondary branches
    branchRight = 4;
    dying = 5;
    dead = 6;
  };

  # Direction vectors for growth
  # Format: { dx, dy } where positive y is down (screen coordinates)
  directions = {
    up = { dx = 0; dy = -1; };
    upLeft = { dx = -1; dy = -1; };
    upRight = { dx = 1; dy = -1; };
    left = { dx = -2; dy = 0; };
    right = { dx = 2; dy = 0; };
    farLeft = { dx = -3; dy = 0; };
    farRight = { dx = 3; dy = 0; };
    gentleLeft = { dx = -1; dy = 0; };
    gentleRight = { dx = 1; dy = 0; };
  };

  # Rich set of characters for detailed tree rendering
  branchChars = {
    # Trunk characters - thicker appearance
    trunk = [ "|" "│" "┃" ];
    trunkLeft = [ "/" "╱" ];
    trunkRight = [ "\\" "╲" ];
    
    # Branch characters
    branch = [ "~" "─" "━" "╌" ];
    branchUp = [ "╱" "/" "╲" "\\" ];
    
    # Leaf characters - variety for visual interest
    leaves = [ 
      "&" "♣" "♠" "✿" "❀" "❁" "✾" 
      "※" "☘" "🌿" "🍃" "✦" "❧"
      "*" "%" "@" "#" "○" "●"
    ];
    
    # Dense foliage characters
    foliage = [ "█" "▓" "▒" "░" "❋" "✺" ];
  };

  # Grow a single branch segment with enhanced detail
  growBranch = { x, y, life, branchType, rngState, multiplier, age, depth ? 0 }:
    if life <= 0 then
      # Branch dies - add leaf cluster
      let
        # More leaves for main branches, fewer for sub-branches
        baseLeaves = if depth == 0 then 8 else if depth == 1 then 5 else 3;
        numLeaves = rng.randRange rngState baseLeaves (baseLeaves + 4);
        leafResult = generateLeafCluster { 
          inherit x y depth; 
          rngState = numLeaves.state; 
          count = numLeaves.value; 
        };
      in
      {
        segments = leafResult.segments;
        rngState = leafResult.rngState;
        branches = [];
      }
    else
      let
        # Decide direction based on branch type and randomness
        dirResult = chooseDirection { inherit branchType rngState age depth; };
        dir = dirResult.direction;
        newRngState = dirResult.rngState;

        # Calculate new position
        newX = x + dir.dx;
        newY = y + dir.dy;

        # Choose character for this segment
        charResult = chooseBranchChar branchType dir age newRngState;

        # Current segment
        currentSegment = {
          x = x;
          y = y;
          char = charResult.char;
          type = branchType;
        };

        # Maybe add thickness to trunk
        thicknessSegments = 
          if branchType == branchTypes.trunk && age < 3 then
            # Add adjacent characters for thick trunk base
            let
              leftSeg = { x = x - 1; y = y; char = "("; type = branchType; };
              rightSeg = { x = x + 1; y = y; char = ")"; type = branchType; };
            in
            [ leftSeg rightSeg ]
          else [];

        # Check if we should spawn new branches
        spawnResult = maybeSpawnBranches {
          x = newX;
          y = newY;
          life = life - 1;
          inherit branchType multiplier age depth;
          rngState = charResult.rngState;
        };

        # Determine next branch type
        nextBranchType =
          if branchType == branchTypes.trunk && life < 4
          then branchTypes.dying
          else if (branchType == branchTypes.shootLeft || branchType == branchTypes.shootRight) && life < 3
          then branchTypes.dying
          else branchType;

        # Continue growing this branch
        continuedGrowth = growBranch {
          x = newX;
          y = newY;
          life = life - 1;
          branchType = nextBranchType;
          rngState = spawnResult.rngState;
          inherit multiplier depth;
          age = age + 1;
        };
      in
      {
        segments = [ currentSegment ] ++ thicknessSegments ++ continuedGrowth.segments;
        rngState = continuedGrowth.rngState;
        branches = spawnResult.branches ++ continuedGrowth.branches;
      };

  # Choose direction based on branch type with more variety
  chooseDirection = { branchType, rngState, age, depth }:
    let
      r = rng.randInt rngState 100;
    in
    if branchType == branchTypes.trunk then
      # Trunk mostly goes up with occasional wobble
      if r.value < 70 then { direction = directions.up; rngState = r.state; }
      else if r.value < 85 then { direction = directions.upLeft; rngState = r.state; }
      else { direction = directions.upRight; rngState = r.state; }
    
    else if branchType == branchTypes.shootLeft || branchType == branchTypes.branchLeft then
      # Left-going branches
      if r.value < 30 then { direction = directions.upLeft; rngState = r.state; }
      else if r.value < 50 then { direction = directions.left; rngState = r.state; }
      else if r.value < 70 then { direction = directions.gentleLeft; rngState = r.state; }
      else if r.value < 85 then { direction = directions.up; rngState = r.state; }
      else { direction = directions.farLeft; rngState = r.state; }
    
    else if branchType == branchTypes.shootRight || branchType == branchTypes.branchRight then
      # Right-going branches
      if r.value < 30 then { direction = directions.upRight; rngState = r.state; }
      else if r.value < 50 then { direction = directions.right; rngState = r.state; }
      else if r.value < 70 then { direction = directions.gentleRight; rngState = r.state; }
      else if r.value < 85 then { direction = directions.up; rngState = r.state; }
      else { direction = directions.farRight; rngState = r.state; }
    
    else
      # Dying branches spread out more
      if r.value < 20 then { direction = directions.upLeft; rngState = r.state; }
      else if r.value < 40 then { direction = directions.upRight; rngState = r.state; }
      else if r.value < 55 then { direction = directions.left; rngState = r.state; }
      else if r.value < 70 then { direction = directions.right; rngState = r.state; }
      else if r.value < 85 then { direction = directions.up; rngState = r.state; }
      else { direction = directions.gentleLeft; rngState = r.state; };

  # Choose the character for a branch segment with variety
  chooseBranchChar = branchType: dir: age: rngState:
    let
      r = rng.randInt rngState (builtins.length branchChars.trunk);
    in
    if branchType == branchTypes.trunk then
      if dir == directions.up then 
        { char = builtins.elemAt branchChars.trunk (rng.mod r.value 3); rngState = r.state; }
      else if dir == directions.upLeft then 
        { char = builtins.elemAt branchChars.trunkLeft (rng.mod r.value 2); rngState = r.state; }
      else if dir == directions.upRight then 
        { char = builtins.elemAt branchChars.trunkRight (rng.mod r.value 2); rngState = r.state; }
      else 
        { char = "|"; rngState = r.state; }
    
    else if branchType == branchTypes.shootLeft || branchType == branchTypes.branchLeft then
      if dir == directions.left || dir == directions.farLeft || dir == directions.gentleLeft then 
        { char = builtins.elemAt branchChars.branch (rng.mod r.value 4); rngState = r.state; }
      else if dir == directions.upLeft then 
        { char = "\\"; rngState = r.state; }
      else 
        { char = "~"; rngState = r.state; }
    
    else if branchType == branchTypes.shootRight || branchType == branchTypes.branchRight then
      if dir == directions.right || dir == directions.farRight || dir == directions.gentleRight then 
        { char = builtins.elemAt branchChars.branch (rng.mod r.value 4); rngState = r.state; }
      else if dir == directions.upRight then 
        { char = "/"; rngState = r.state; }
      else 
        { char = "~"; rngState = r.state; }
    
    else if branchType == branchTypes.dying then
      { char = builtins.elemAt [ "~" "─" "'" "`" ] (rng.mod r.value 4); rngState = r.state; }
    
    else
      { char = "|"; rngState = r.state; };

  # Enhanced branch spawning - more branches, sub-branches allowed
  maybeSpawnBranches = { x, y, life, branchType, multiplier, age, depth, rngState }:
    let
      # Higher spawn chance, and allow from shoots too
      baseChance = multiplier * 6;
      spawnChance = 
        if branchType == branchTypes.trunk then baseChance
        else if depth < 2 && (branchType == branchTypes.shootLeft || branchType == branchTypes.shootRight) then baseChance / 2
        else 0;
      
      r = rng.randInt rngState 100;
      shouldSpawn = r.value < spawnChance && life > 2;
      
      # Decide which side to spawn (or both!)
      sideR = rng.randInt r.state 100;
      spawnBoth = sideR.value < (multiplier * 2);  # Chance to spawn both sides
      spawnLeft = sideR.value < 50 || spawnBoth;
      spawnRight = sideR.value >= 50 || spawnBoth;
      
      r2 = rng.randInt sideR.state 100;
      
      # Calculate branch life based on depth
      branchLife = 
        if depth == 0 then life / 2 + (rng.mod age 4)
        else life / 2;
      
      leftBranch = {
        inherit x y;
        life = branchLife;
        branchType = if depth == 0 then branchTypes.shootLeft else branchTypes.branchLeft;
        age = 0;
        depth = depth + 1;
      };
      
      rightBranch = {
        inherit x y;
        life = branchLife;
        branchType = if depth == 0 then branchTypes.shootRight else branchTypes.branchRight;
        age = 0;
        depth = depth + 1;
      };
      
      newBranches = 
        if spawnLeft && spawnRight then [ leftBranch rightBranch ]
        else if spawnLeft then [ leftBranch ]
        else if spawnRight then [ rightBranch ]
        else [];
    in
    if shouldSpawn then
      { branches = newBranches; rngState = r2.state; }
    else
      { branches = []; rngState = r.state; };

  # Generate dense leaf clusters at branch ends
  generateLeafCluster = { x, y, rngState, count, depth }:
    let
      # Spread increases with count
      spread = if count > 6 then 3 else 2;
      
      makeLeaf = { state, n, segments }:
        if n <= 0 then { inherit segments; rngState = state; }
        else
          let
            # Random offset for leaf position - wider spread
            dxR = rng.randRange state (-spread) spread;
            dyR = rng.randRange dxR.state (-2) 1;
            charR = rng.randChoice dyR.state branchChars.leaves;
            
            # Sometimes add extra density
            extraR = rng.randInt charR.state 100;
            addExtra = extraR.value < 30;
            
            leaf = {
              x = x + dxR.value;
              y = y + dyR.value;
              char = charR.value;
              type = branchTypes.dead;
              isLeaf = true;
            };
            
            # Extra foliage nearby
            extraLeaf = {
              x = x + dxR.value + (if dxR.value >= 0 then 1 else -1);
              y = y + dyR.value;
              char = builtins.elemAt branchChars.leaves (rng.mod extraR.value 8);
              type = branchTypes.dead;
              isLeaf = true;
            };
            
            newSegments = 
              if addExtra then segments ++ [ leaf extraLeaf ]
              else segments ++ [ leaf ];
          in
          makeLeaf { 
            state = extraR.state; 
            n = n - 1; 
            segments = newSegments; 
          };
    in
    makeLeaf { state = rngState; n = count; segments = []; };

  # Main tree growing function
  growTree = seed: life: multiplier:
    let
      initialRng = rng.mkRng seed;
      
      # Start position (will be normalized later)
      startX = 50;
      startY = 60;
      
      # Grow the main trunk
      trunkResult = growBranch {
        x = startX;
        y = startY;
        inherit life multiplier;
        branchType = branchTypes.trunk;
        rngState = initialRng;
        age = 0;
        depth = 0;
      };
      
      # Grow all spawned branches recursively
      growAllBranches = { segments, branches, rngState }:
        if builtins.length branches == 0 then
          { inherit segments rngState; }
        else
          let
            branch = builtins.head branches;
            restBranches = builtins.tail branches;
            
            branchResult = growBranch {
              inherit (branch) x y life branchType age depth;
              inherit multiplier rngState;
            };
            
            allSegments = segments ++ branchResult.segments;
            allBranches = restBranches ++ branchResult.branches;
          in
          growAllBranches {
            segments = allSegments;
            branches = allBranches;
            rngState = branchResult.rngState;
          };
      
      allGrowth = growAllBranches {
        segments = trunkResult.segments;
        branches = trunkResult.branches;
        rngState = trunkResult.rngState;
      };
      
      # Calculate bounds
      allX = map (s: s.x) allGrowth.segments;
      allY = map (s: s.y) allGrowth.segments;
      minX = lib.foldl' lib.min (builtins.head allX) allX;
      maxX = lib.foldl' lib.max (builtins.head allX) allX;
      minY = lib.foldl' lib.min (builtins.head allY) allY;
      maxY = lib.foldl' lib.max (builtins.head allY) allY;
      
      # Normalize positions
      normalizedSegments = map (s: s // {
        x = s.x - minX;
        y = s.y - minY;
      }) allGrowth.segments;
      
    in
    {
      segments = normalizedSegments;
      width = maxX - minX + 1;
      height = maxY - minY + 1;
      baseY = startY - minY;
    };

in
{
  inherit growTree growBranch branchTypes branchChars directions;
}
