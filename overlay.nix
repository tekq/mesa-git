{mesa-src}: final: prev: let
  gitVersion = "0-unstable-${builtins.substring 0 8 (mesa-src.rev or "0000000000000000")}";
  patchFn = pkgs: (import ./patches {inherit (pkgs) fetchpatch;});

  subprojectsDir = "${mesa-src}/subprojects";
  wrapFiles = builtins.filter (name: prev.lib.hasSuffix "-rs.wrap" name) (builtins.attrNames (builtins.readDir subprojectsDir));
  parseWrap = name:
    let
      content = builtins.readFile "${subprojectsDir}/${name}";
      lines = prev.lib.splitString "\n" content;
      findVal = prefix:
        let
          m = builtins.filter (l: prev.lib.hasPrefix prefix l) lines;
        in
          if m != []
          then prev.lib.removePrefix prefix (builtins.head m)
          else null;
      url = findVal "source_url = ";
      filename = findVal "source_filename = ";
      hash = findVal "source_hash = ";
    in
      if url != null && filename != null && hash != null
      then prev.fetchurl {
        inherit url;
        name = filename;
        sha256 = hash;
      }
      else null;
  crates = builtins.filter (x: x != null) (map parseWrap wrapFiles);
  packageCache = prev.runCommand "mesa-git-rust-package-cache" {} ''
    mkdir -p $out
    ${prev.lib.concatMapStringsSep "\n" (crate: "ln -s ${crate} $out/${crate.name}") crates}
  '';

  buildGit = mesaPkg:
    (mesaPkg.override {
      # drop virtio (don't use this as a guest)
      vulkanDrivers = builtins.filter (d: d != "virtio") mesaPkg.vulkanDrivers;
    }).overrideAttrs (old: {
      pname = "mesa-git";
      version = gitVersion;
      src = mesa-src;
      env = (old.env or {}) // {
        MESON_PACKAGE_CACHE_DIR = packageCache;
      };
      mesonFlags = builtins.map (
        flag:
          if builtins.match "^-Dvulkan-layers=.*" flag != null
          then builtins.replaceStrings [",anti-lag" "anti-lag,"] ["" ""] flag
          else if flag == "-Damdgpu-virtio=true"
          then "-Damd-options=use-llvm,virtio"
          else flag
      ) (old.mesonFlags or []);
      patches = (old.patches or []) ++ patchFn final;
    });
in {
  mesa_git = buildGit prev.mesa;
  mesa32_git = buildGit prev.pkgsi686Linux.mesa;
}
