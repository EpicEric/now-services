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
      type = types.nullOr types.derivation;
      description = ''
        `now` package to use.

        By default, `now` in your PATH is used.
      '';
    };
    strategy = {
      type = types.enum "strategy" [
        "ignore"
        "restart"
        "terminate"
      ];
      default = "terminate";
      description = "How to handle any failing job.";
    };
    jobs = {
      type = types.listOf types.string;
      description = "List of `now` job IDs to run concurrently.";
    };
    nowArgs = {
      type = types.listOf types.string;
      default = [ ];
      description = "List of common arguments to pass to each invocation of `now run`.";
    };
  };

  assertions = [
    {
      verify = { options }: builtins.length options.jobs > 0;
      explain = _: "'options.jobs' cannot be empty";
    }
  ];

  result = promise (
    { options }:
    { lib, ... }:
    let
      inherit (builtins) concatStringsSep;
      inherit (lib) optionals escapeShellArg escapeShellArgs;
      nowArgs = escapeShellArgs options.nowArgs;
    in
    {
      inherit (options) env;
      path = optionals (options.package != null) [ options.package ];
      sandbox.enable = false;
      run = ''
        set -euo pipefail
        source ${./lib.sh}

        ${concatStringsSep "\n" (
          map (
            job':
            let
              job = escapeShellArg job';
            in
            "now_start ${job} now run ${job} ${nowArgs}"
          ) options.jobs
        )}

        ${
          if options.strategy == "terminate" then
            "now_wait_for_jobs"
          else if options.strategy == "restart" then
            "now_wait_and_restart"
          else
            "wait"
        }
      '';
    }
  );

  meta = {
    description = ''
      Orchestrate multiple `now` jobs, allowing you to run several services at once.
    '';
  };
}
