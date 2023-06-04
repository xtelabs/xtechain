{ pkgs
, config
, xtechain ? (import ../. { inherit pkgs; })
}: rec {
  start-xtechain = pkgs.writeShellScriptBin "start-xtechain" ''
    # rely on environment to provide xted
    export PATH=${pkgs.test-env}/bin:$PATH
    ${../scripts/start-xtechain.sh} ${config.xtechain-config} ${config.dotenv} $@
  '';
  start-geth = pkgs.writeShellScriptBin "start-geth" ''
    export PATH=${pkgs.test-env}/bin:${pkgs.go-ethereum}/bin:$PATH
    source ${config.dotenv}
    ${../scripts/start-geth.sh} ${config.geth-genesis} $@
  '';
  start-scripts = pkgs.symlinkJoin {
    name = "start-scripts";
    paths = [ start-xtechain start-geth ];
  };
}
