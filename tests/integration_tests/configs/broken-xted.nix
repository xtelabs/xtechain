{ pkgs ? import ../../../nix { } }:
let xted = (pkgs.callPackage ../../../. { });
in
xted.overrideAttrs (oldAttrs: {
  patches = oldAttrs.patches or [ ] ++ [
    ./broken-xted.patch
  ];
})
