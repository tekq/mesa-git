{ mesa-src }:
final: prev:
let
  gitVersion = "0-unstable-${builtins.substring 0 8 (mesa-src.rev or "0000000000000000")}";
  patchFn = pkgs: (import ./patches { inherit (pkgs) fetchpatch; });
  buildGit = mesaPkg: mesaPkg.overrideAttrs (old: {
    pname = "mesa-git";
    version = gitVersion;
    src = mesa-src;
    patches = (old.patches or [ ]) ++ patchFn final;
  });
in
{
  mesa_git = (buildGit prev.mesa);
  mesa32_git = (buildGit prev.pkgsi686Linux.mesa);
}
