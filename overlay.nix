{mesa-src}: final: prev: let
  gitVersion = "0-unstable-${builtins.substring 0 8 (mesa-src.rev or "0000000000000000")}";
  patchFn = pkgs: (import ./patches {inherit (pkgs) fetchpatch;});
  buildGit = pkgs: mesaPkg:
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
          then "-Damd-options=use-llvm,virtio"
          else flag
      ) (old.mesonFlags or []);
      buildInputs = (old.buildInputs or []) ++ [pkgs.libxml2];
      patches = (old.patches or []) ++ patchFn final;
    });
in {
  mesa_git = buildGit prev prev.mesa;
  mesa32_git = buildGit prev.pkgsi686Linux prev.pkgsi686Linux.mesa;
}
