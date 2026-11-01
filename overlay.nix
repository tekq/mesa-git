{mesa-src}: final: prev: let
  gitVersion = "0-unstable-${builtins.substring 0 8 (mesa-src.rev or "0000000000000000")}";
  patchFn = pkgs: (import ./patches {inherit (pkgs) fetchpatch;});
  mesonOptionsPath =
    if builtins.pathExists "${mesa-src}/meson.options"
    then "${mesa-src}/meson.options"
    else "${mesa-src}/meson_options.txt";
  hasAmdOptions =
    builtins.pathExists mesonOptionsPath
    && builtins.any (
      line: builtins.match ".*option\\(['\"]amd-options['\"].*" line != null
    ) (builtins.filter builtins.isString (builtins.split "\n" (builtins.readFile mesonOptionsPath)));
  buildGit = mesaPkg:
    (mesaPkg.override {
      # drop virtio (don't use this as a guest)
      vulkanDrivers = builtins.filter (d: d != "virtio") mesaPkg.vulkanDrivers;
    }).overrideAttrs (old: {
      pname = "mesa-git";
      version = gitVersion;
      src = mesa-src;
      mesonFlags = builtins.map (
        flag:
          if builtins.match "^-Dvulkan-layers=.*" flag != null
          then builtins.replaceStrings [",anti-lag" "anti-lag,"] ["" ""] flag
          else if flag == "-Damdgpu-virtio=true"
          then if hasAmdOptions then "-Damd-options=use-llvm,virtio" else flag
          else flag
      ) (old.mesonFlags or []);
      patches = (old.patches or []) ++ patchFn final;
    });
in {
  mesa_git = buildGit prev.mesa;
  mesa32_git = buildGit prev.pkgsi686Linux.mesa;
}
