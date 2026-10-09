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

let
  inherit (builtins) mapAttrs;
  inputs = import ./.tack;
  adios = import inputs.adios;
  services = adios.lib.importModules { directory = ./services; };
in

mapAttrs (
  name: value: args: specialArgs:
  (adios {
    modules = {
      specialArgs.options.specialArgs = {
        type = adios.types.attrs;
        default = specialArgs;
      };
      ${name} = value;
    };
  } { }).modules.${name}
    args
) services
