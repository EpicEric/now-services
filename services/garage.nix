{
  env ? { },
  package ? null,
  args ? [ ],
  ...
}:
{ pkgs, ... }:
let
  package' = if package == null then pkgs.garage_2 else package;
  inherit (pkgs.lib) escapeShellArgs;
in
{
  inherit env;
  path = [ package' ];
  sandbox.enable = false;
  run = ''
    set -e
    source ${./lib.sh}

    start garage garage server ${escapeShellArgs args}
    wait_for 30 garage status
    echo "Garage is running."
    wait_for_jobs
  '';
}
