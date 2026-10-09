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
      description = "The Garage package to use.";
    };
    args = {
      type = types.listOf types.string;
      default = [ ];
      description = "Command-line arguments passed to Garage.";
    };
  };

  result = promise (
    { inputs, options }:
    let
      inherit (inputs.specialArgs.specialArgs) lib pkgs;
      package = if options ? package then options.package else pkgs.garage_2;
      inherit (lib) escapeShellArgs;
    in
    {
      inherit (options) env;
      path = [ package ];
      sandbox.enable = false;
      run = ''
        set -eo pipefail
        source ${./lib.sh}

        now_start garage garage server ${escapeShellArgs options.args}
        now_wait_for 30 garage status
        echo "Garage is running."
        now_wait_for_jobs
      '';
    }
  );

  meta = {
    description = ''
      Run [Garage](https://garagehq.deuxfleurs.fr/), an S3-compatible object store.
    '';
  };
}
