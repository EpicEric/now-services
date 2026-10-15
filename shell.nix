{
  system ? builtins.currentSystem,
  inputs ? import ./.tack,
  pkgs ? import <nixpkgs> { inherit system; },
  now ? import inputs.now { inherit system; },
}:
pkgs.mkShellNoCC {
  packages = [ now ];
}
