# Tree growth algorithm for bonsai generation
# Implements recursive branching similar to cbonsai
{ lib, rng }:

let
  # Branch types
  branchTypes = {
    trunk = 0;
    shootLeft = 1;
    shootRight = 2;
    dying = 3;
    dead = 4;
  };

  # Direction vectors for growth
  # Format: { dx, dy } where positive y is down (screen coordinates)
  directions = {
    up = { dx = 0; dy = -1; };
    upLeft = { dx = -1; dy = -1; };
    upRight = { dx = 1; dy = -1; };
    left = { dx = -2; dy = 0; };
    right = { dx = 2; dy = 0; };
    downLeft = { dx = -1; dy = 1; };
    downRight = { dx = 1; dy = 1; };
  };

  # Characters for different branch types and directions
  branchChars = {
    trunk = {
      up = "/~\\";
      upLeft = "/~";
      upRight = "~\\";
    };
    shootLeft = "\\~";
    shootRight = "~/";
    dying = "&";
    leaves = [ "&" "*" "%" "#" "@" ];
  };

  # Grow a single branch segment
  # Returns: { segments, rngState, branches }
  # where branches is a list of new branches to grow
  growBranch = { x, y, life, branchType, rngState, multiplier, age }:
    if life <= 0 then
      # Branch dies - add leaves
      let
        numLeaves = rng.randRange rngState 2 5;
        leafResult = generateLeaves { inherit x y; rngState = numLeaves.state; count = numLeaves.value; };
      in
      {
        segments = leafResult.segments;
        rngState = leafResult.rngState;
        branches = [];
      }
    else
      let
        # Decide direction based on branch type and randomness
        dirResult = chooseDirection { inherit branchType rngState age; };
        dir = dirResult.direction;
        newRngState = dirResult.rngState;

        # Calculate new position
        newX = x + dir.dx;
        newY = y + dir.dy;

        # Choose character for this segment
        char = chooseBranchChar branchType dir age;

        # Current segment
        currentSegment = {
          inherit x y char;
          type = branchType;
        };

        # Check if we should spawn new branches
        spawnResult = maybeSpawnBranches {
          x = newX;
          y = newY;
          life = life - 1;
          inherit branchType multiplier age;
          rngState = newRngState;
        };

        # Continue growing this branch
        continuedGrowth = growBranch {
          x = newX;
          y = newY;
          life = life - 1;
          branchType =
            if branchType == branchTypes.trunk && life < 5
            then branchTypes.dying
            else branchType;
          rngState = spawnResult.rngState;
          inherit multiplier;
          age = age + 1;
        };
      in
      {
        segments = [ currentSegment ] ++ continuedGrowth.segments;
        rngState = continuedGrowth.rngState;
        branches = spawnResult.branches ++ continuedGrowth.branches;
      };

  # Choose direction based on branch type
  chooseDirection = { branchType, rngState, age }:
    let
      r = rng.randInt rngState 100;
    in
    if branchType == branchTypes.trunk then
      # Trunk mostly goes up with slight wobble
      if r.value < 60 then { direction = directions.up; rngState = r.state; }
      else if r.value < 80 then { direction = directions.upLeft; rngState = r.state; }
      else { direction = directions.upRight; rngState = r.state; }
    else if branchType == branchTypes.shootLeft then
      if r.value < 40 then { direction = directions.upLeft; rngState = r.state; }
      else if r.value < 70 then { direction = directions.left; rngState = r.state; }
      else { direction = directions.up; rngState = r.state; }
    else if branchType == branchTypes.shootRight then
      if r.value < 40 then { direction = directions.upRight; rngState = r.state; }
      else if r.value < 70 then { direction = directions.right; rngState = r.state; }
      else { direction = directions.up; rngState = r.state; }
    else
      # Dying branches spread out
      if r.value < 25 then { direction = directions.upLeft; rngState = r.state; }
      else if r.value < 50 then { direction = directions.upRight; rngState = r.state; }
      else if r.value < 75 then { direction = directions.left; rngState = r.state; }
      else { direction = directions.right; rngState = r.state; };

  # Choose the character for a branch segment
  chooseBranchChar = branchType: dir: age:
    if branchType == branchTypes.trunk then
      if dir == directions.up then "|"
      else if dir == directions.upLeft then "/"
      else if dir == directions.upRight then "\\"
      else "|"
    else if branchType == branchTypes.shootLeft then
      if dir == directions.left || dir == directions.upLeft then "~"
      else "\\"
    else if branchType == branchTypes.shootRight then
      if dir == directions.right || dir == directions.upRight then "~"
      else "/"
    else if branchType == branchTypes.dying then
      if dir == directions.left || dir == directions.upLeft then "~"
      else if dir == directions.right || dir == directions.upRight then "~"
      else "|"
    else "|";

  # Maybe spawn new branches based on multiplier
  maybeSpawnBranches = { x, y, life, branchType, multiplier, age, rngState }:
    let
      # Probability of spawning increases with multiplier
      spawnChance = multiplier * 5;
      r = rng.randInt rngState 100;
      shouldSpawn = r.value < spawnChance && life > 3 && branchType == branchTypes.trunk;
      
      # Decide which side to spawn
      sideR = rng.randInt r.state 100;
      spawnLeft = sideR.value < 50;
      
      newBranch = {
        inherit x y;
        life = life / 2 + rng.mod age 3;
        branchType = if spawnLeft then branchTypes.shootLeft else branchTypes.shootRight;
        age = 0;
      };
    in
    if shouldSpawn then
      { branches = [ newBranch ]; rngState = sideR.state; }
    else
      { branches = []; rngState = r.state; };

  # Generate leaves at the end of a branch
  generateLeaves = { x, y, rngState, count }:
    let
      makeLeaf = { state, n, segments }:
        if n <= 0 then { inherit segments; rngState = state; }
        else
          let
            # Random offset for leaf position
            dxR = rng.randRange state (-2) 2;
            dyR = rng.randRange dxR.state (-1) 1;
            charR = rng.randChoice dyR.state branchChars.leaves;
            
            leaf = {
              x = x + dxR.value;
              y = y + dyR.value;
              char = charR.value;
              type = branchTypes.dead;
              isLeaf = true;
            };
          in
          makeLeaf { 
            state = charR.state; 
            n = n - 1; 
            segments = segments ++ [ leaf ]; 
          };
    in
    makeLeaf { state = rngState; n = count; segments = []; };

  # Main tree growing function
  # Returns: { segments, width, height, baseY }
  growTree = seed: life: multiplier:
    let
      initialRng = rng.mkRng seed;
      
      # Start position (will be normalized later)
      startX = 40;
      startY = 50;
      
      # Grow the main trunk
      trunkResult = growBranch {
        x = startX;
        y = startY;
        inherit life multiplier;
        branchType = branchTypes.trunk;
        rngState = initialRng;
        age = 0;
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
              inherit (branch) x y life branchType age;
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

