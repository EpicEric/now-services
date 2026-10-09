{ types, ... }: {
  options = {
    lib = {
      type = types.attrs;
    };
    pkgs = {
      type = types.attrs;
    };
  };

  meta.generateDocs = false;
}
