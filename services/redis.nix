{
  env ? { },
  package ? null,
  serverBinary ? null,
  cliBinary ? null,
  ...
}:
{ pkgs, ... }:
let
  package' = if package == null then pkgs.redis else package;
  serverBinary' = if serverBinary == null then package'.serverBin or "redis-server" else serverBinary;
  cliBinary' = if cliBinary == null then package'.meta.mainProgram or "redis-cli" else cliBinary;
in
{
  inherit env;
  path = [ package' ];
  sandbox.enable = false;
  run = ''
    set -e
    source ${./lib.sh}

    if [ -z "$REDIS_DIR" ]; then
      start redis ${serverBinary'} --port "''${REDIS_PORT:-6379}" --save "" --appendonly no
    else
      start redis ${serverBinary'} --port "''${REDIS_PORT:-6379}" --dir "$REDIS_DIR"
    fi
    wait_for 30 ${cliBinary'} -p "''${REDIS_PORT:-6379}" ping
    echo "Redis is running."
    wait_for_jobs
  '';
}
