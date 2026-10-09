# now-services: A collection of now-compatible services
# Copyright (C) 2026 Eric Rodrigues Pires
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for
# more details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <https://www.gnu.org/licenses/>.

{
  promise,
  types,
  ...
}:
{
  options = {
    env = {
      type = types.attrs;
      default = { };
      description = "`now` environment for this step.";
    };
    package = {
      type = types.derivation;
      description = "The Redis package to use.";
    };
    serverBinary = {
      type = types.string;
      description = ''
        Name of the Redis server binary.

        If unspecified, it will be inferred from the package.
      '';
    };
    cliBinary = {
      type = types.string;
      description = ''
        Name of the Redis client binary (for healthcheck).

        If unspecified, it will be inferred from the package.
      '';
    };
  };

  result = promise (
    { options }:
    { pkgs, ... }:
    let
      package = if options ? package then options.package else pkgs.redis;
      serverBinary =
        if options ? serverBinary then options.serverBinary else package.serverBin or "redis-server";
      cliBinary =
        if options ? cliBinary then options.cliBinary else package.meta.mainProgram or "redis-cli";
    in
    {
      inherit (options) env;
      path = [ package ];
      sandbox.enable = false;
      run = ''
        set -eo pipefail
        source ${./lib.sh}

        if [ -z "$REDIS_DIR" ]; then
          now_start redis ${serverBinary} --port "''${REDIS_PORT:-6379}" --save "" --appendonly no
        else
          now_start redis ${serverBinary} --port "''${REDIS_PORT:-6379}" --dir "$REDIS_DIR"
        fi
        now_wait_for 30 ${cliBinary} -p "''${REDIS_PORT:-6379}" ping
        echo "Redis is running."
        now_wait_for_jobs
      '';
    }
  );

  meta = {
    description = ''
      Run [Redis](https://redis.io/), an in-memory key-value database, or a derivative.
    '';
  };
}
