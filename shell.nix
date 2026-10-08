{
  system ? builtins.currentSystem,
  inputs ? import ./.tack,
  pkgs ? import inputs.nixpkgs { inherit system; },
  now ? import inputs.now { inherit system; },
}:
pkgs.mkShellNoCC {
  packages = [ now ];
}
