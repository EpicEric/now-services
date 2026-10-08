# Adapted from:
# <https://github.com/llakala/lladios/blob/4a5e900239bc2248cd7620954090df5b4fe52b4b/adios/lib/importModules.nix>
# SPDX: LGPL-3.0-or-later

let
  inherit (builtins)
    attrNames
    concatMap
    head
    listToAttrs
    match
    pathExists
    readDir
    ;

  importModules =
    dir:
    let
      matchNixFile = match "(.+)\\.nix$";

      files = readDir dir;

      result = listToAttrs (
        concatMap (
          name:
          if files.${name} == "directory" then
            if pathExists (dir + "/${name}/default.nix") then
              [
                {
                  inherit name;
                  value = import (dir + "/${name}");
                }
              ]
            else
              [ ]
          else
            let
              m = matchNixFile name;
              moduleName = head m;
            in
            if m != null && name != "default.nix" then
              [
                {
                  name =
                    if files ? ${moduleName} then
                      throw ''
                        Module ${moduleName} was provided by both:
                        - ${dir}/${moduleName}/default.nix
                        - ${name}

                        This is ambigious. Restructure your code to not have ambigious module names.
                      ''
                    else
                      moduleName;
                  value = import (dir + "/${name}");
                }
              ]
            else
              [ ]
        ) (attrNames files)
      );
    in
    result;
in

importModules ./services
