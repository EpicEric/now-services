{
  env ? { },
  package ? null,
  unixSocket ? null,
  ...
}:
{ pkgs, ... }:
let
  package' = if package == null then pkgs.postgresql else package;
  inherit (pkgs.lib) escapeShellArg;
in
{
  inherit env;
  path = [
    package'
    pkgs.mktemp
  ];
  sandbox.enable = false;
  run = ''
    set -e
    source ${./lib.sh}

    if [ -z "$PGDATA" ]; then
      echo "Missing PGDATA environment variable"
      exit 1
    fi
    if [ ! -f "$PGDATA/PG_VERSION" ]; then
      initdb -D "$PGDATA" --auth=trust
    fi

    ${
      if unixSocket == null then
        ''
          sockdir=$(mktemp -d)
          trap 'rm -rf "$sockdir"' EXIT
          start postgres postgres -D "$PGDATA" -k "$sockdir"
          wait_for 30 pg_isready -h "$sockdir"
        ''
      else
        let
          unixSocket' = escapeShellArg unixSocket;
        in
        ''
          start postgres postgres -D "$PGDATA" -k ${unixSocket'} -c listen_addresses=""
          wait_for 30 pg_isready -h ${unixSocket'}
        ''
    }
    echo "PostgreSQL is running."
    wait_for_jobs
  '';
}
