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
  inputs.specialArgs.from = { parent }: parent.specialArgs;

  options = {
    env = {
      type = types.attrs;
      default = { };
      description = "`now` environment for this step.";
    };
    package = {
      type = types.derivation;
      description = "The PostgreSQL package to use.";
    };
    unixSocket = {
      type = types.string;
      description = ''
        Where to bind the Unix socket for PostgreSQL.

        If unspecified, a random directory will be used.
      '';
    };
  };

  result = promise (
    { inputs, options }:
    let
      inherit (inputs.specialArgs.specialArgs) lib pkgs;
      package' = if options ? package then options.package else pkgs.postgresql;
      inherit (lib) escapeShellArg;
    in
    {
      inherit (options) env;
      path = [
        package'
        pkgs.mktemp
      ];
      sandbox.enable = false;
      run = ''
        set -eo pipefail
        source ${./lib.sh}

        if [ -z "$PGDATA" ]; then
          echo "Missing PGDATA environment variable"
          exit 1
        fi
        if [ ! -f "$PGDATA/PG_VERSION" ]; then
          initdb -D "$PGDATA" --auth=trust
        fi

        ${
          if options ? unixSocket then
            let
              unixSocket = escapeShellArg options.unixSocket;
            in
            ''
              now_start postgresql postgres -D "$PGDATA" -k ${unixSocket} -c listen_addresses=""
              now_wait_for 30 pg_isready -h ${unixSocket}
            ''
          else
            ''
              sockdir=$(mktemp -d)
              trap 'rm -rf "$sockdir"' EXIT
              now_start postgresql postgres -D "$PGDATA" -k "$sockdir"
              now_wait_for 30 pg_isready -h "$sockdir"
            ''
        }
        echo "PostgreSQL is running."
        now_wait_for_jobs
      '';
    }
  );

  meta = {
    description = ''
      Run [PostgreSQL](https://www.postgresql.org/), a relational database.
    '';
  };
}
