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
  inputs.specialArgs.from = { self }: self.specialArgs;

  options = {
    env = {
      type = types.attrs;
      description = "`now` environment for this step.";
    };
    package = {
      type = types.derivation;
      description = ''
        `now` package to use.

        By default, the one in your PATH is used.
      '';
    };
    strategy = {
      type = types.enum "strategyEnum" [
        "ignore"
        "restart"
        "terminate"
      ];
      default = "terminate";
      description = ''
        How to handle any failing job.

        Possible options:

        - `"terminate"`: Terminate all other jobs.
        - `"restart"`: Restart any failing jobs.
        - `"ignore"`: Ignore the failing job and keep going.
      '';
    };
    jobs = {
      type = types.listOf types.string;
      description = "List of `now` job IDs to run concurrently.";
    };
    nowArgs = {
      type = types.listOf types.string;
      description = "List of common arguments to pass to each invocation of `now run`.";
    };
  };

  modules.specialArgs.options.specialArgs.type =
    (types.struct "specialArgs" {
      lib = types.attrs;
    }).override
      { unknown = true; };

  assertions = [
    {
      verify = { options }: builtins.length options.jobs > 0;
      explain = _: "'options.jobs' cannot be empty";
    }
  ];

  result = promise (
    { inputs, options }:
    let
      inherit (inputs.specialArgs.specialArgs) lib;
      inherit (builtins) concatStringsSep;
      inherit (lib)
        optionals
        optionalAttrs
        escapeShellArg
        escapeShellArgs
        ;
      nowArgs = escapeShellArgs (optionals (options ? nowArgs) options.nowArgs);
    in
    {
      env = optionalAttrs (options ? env) options.env;
      path = optionals (options ? package) [ options.package ];
      sandbox.enable = false;
      run = ''
        set -eo pipefail
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
          else if options.strategy == "ignore" then
            "wait"
          else
            ""
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
