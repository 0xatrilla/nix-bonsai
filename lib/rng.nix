# Linear Congruential Generator (LCG) implemented in pure Nix
# Uses the same constants as glibc for reasonable randomness
{ lib }:

let
  # LCG constants (glibc values)
  a = 1103515245;
  c = 12345;
  m = 2147483648; # 2^31

  # Nix doesn't have modulo for large numbers built-in nicely,
  # so we implement it carefully
  mod = x: n:
    let
      result = x - (x / n) * n;
    in
    if result < 0 then result + n else result;

  # Generate next random state
  nextState = state:
    mod (a * state + c) m;

  # Generate a random integer in range [0, max)
  randInt = state: max:
    let
      newState = nextState state;
      value = mod newState max;
    in
    { inherit value; state = newState; };

  # Generate a random integer in range [min, max]
  randRange = state: min: max:
    let
      range = max - min + 1;
      result = randInt state range;
    in
    { value = result.value + min; state = result.state; };

  # Generate a random float in range [0, 1)
  randFloat = state:
    let
      newState = nextState state;
      value = (newState * 1.0) / (m * 1.0);
    in
    { inherit value; state = newState; };

  # Generate a list of n random integers in range [0, max)
  randIntList = state: n: max:
    if n <= 0 then { values = []; inherit state; }
    else
      let
        first = randInt state max;
        rest = randIntList first.state (n - 1) max;
      in
      { values = [ first.value ] ++ rest.values; state = rest.state; };

  # Random boolean with given probability (0.0 to 1.0)
  randBool = state: probability:
    let
      r = randFloat state;
    in
    { value = r.value < probability; state = r.state; };

  # Pick a random element from a list
  randChoice = state: list:
    let
      result = randInt state (builtins.length list);
    in
    { value = builtins.elemAt list result.value; state = result.state; };

  # Create an initial RNG state from a seed
  mkRng = seed:
    let
      # Ensure seed is positive and within bounds
      normalizedSeed = mod (if seed < 0 then -seed else seed) m;
    in
    if normalizedSeed == 0 then 1 else normalizedSeed;

in
{
  inherit
    mkRng
    nextState
    randInt
    randRange
    randFloat
    randIntList
    randBool
    randChoice
    mod;
}

