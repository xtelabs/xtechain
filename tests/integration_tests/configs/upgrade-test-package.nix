let
  pkgs = import ../../../nix { };
  fetchXte = rev: builtins.fetchTarball "https://github.com/xtelabs/xtechain/archive/${rev}.tar.gz";
  released = pkgs.buildGo118Module rec {
    name = "xted";
    src = fetchXte "d29cdad6e667f6089dfecbedd36bb8d3a2a7d025";
    subPackages = [ "cmd/xted" ];
    vendorSha256 = "sha256-cQAol54b6hNzsA4Q3MP9mTqFWM1MvR5uMPrYpaoj3SY=";
    doCheck = false;
  };
  current = pkgs.callPackage ../../../. { };
in
pkgs.linkFarm "upgrade-test-package" [
  { name = "genesis"; path = released; }
  { name = "integration-test-upgrade"; path = current; }
]
