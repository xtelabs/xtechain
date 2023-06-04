#!/bin/bash

# "stable" mode tests assume data is static
# "live" mode tests assume data dynamic

SCRIPT=$(basename ${BASH_SOURCE[0]})
TEST=""
QTD=1
SLEEP_TIMEOUT=5
TEST_QTD=1

#PORT AND RPC_PORT 3 initial digits, to be concat with a suffix later when node is initialized
RPC_PORT="854"
IP_ADDR="127.0.0.1"
MODE="rpc"

KEY="mykey"
CHAINID="xtechain_9527-1"
MONIKER="mymoniker"

## default port prefixes for xted
NODE_P2P_PORT="2660"
NODE_PORT="2663"
NODE_RPC_PORT="2666"

usage() {
    echo "Usage: $SCRIPT"
    echo "Optional command line arguments"
    echo "-t <string>  -- Test to run. eg: rpc"
    echo "-q <number>  -- Quantity of nodes to run. eg: 3"
    echo "-z <number>  -- Quantity of nodes to run tests against eg: 3"
    echo "-s <number>  -- Sleep between operations in secs. eg: 5"
    exit 1
}

while getopts "h?t:q:z:s:" args; do
    case $args in
        h|\?)
            usage;
        exit;;
        t ) TEST=${OPTARG};;
        q ) QTD=${OPTARG};;
        z ) TEST_QTD=${OPTARG};;
        s ) SLEEP_TIMEOUT=${OPTARG};;
    esac
done

set -euxo pipefail

DATA_DIR=$(mktemp -d -t xtechain_9527-datadir.XXXXX)

if [[ ! "$DATA_DIR" ]]; then
    echo "Could not create $DATA_DIR"
    exit 1
fi

DATA_CLI_DIR=$(mktemp -d -t xtechain_9527-cli-datadir.XXXXX)

if [[ ! "$DATA_CLI_DIR" ]]; then
    echo "Could not create $DATA_CLI_DIR"
    exit 1
fi

# Compile xtechain
echo "compiling xtechain"
make build-xtechain

# PID array declaration
arr=()

# PID arraycli declaration
arrcli=()

init_func() {
    echo "create and add new keys"
    "$PWD"/build/xted keys add $KEY"$i" --home "$DATA_DIR$i" --no-backup --chain-id $CHAINID --algo "eth_secp256k1" --keyring-backend test
    echo "init xtechain with moniker=$MONIKER and chain-id=$CHAINID"
    "$PWD"/build/xted init $MONIKER --chain-id $CHAINID --home "$DATA_DIR$i"
    echo "prepare genesis: Allocate genesis accounts"
    "$PWD"/build/xted add-genesis-account \
    "$("$PWD"/build/xted keys show "$KEY$i" -a --home "$DATA_DIR$i" --keyring-backend test)" 1000000000000000000axte \
    --home "$DATA_DIR$i" --keyring-backend test
    echo "prepare genesis: Sign genesis transaction"
    "$PWD"/build/xted gentx $KEY"$i" 1000000000000000000axte --keyring-backend test --home "$DATA_DIR$i" --keyring-backend test --chain-id $CHAINID
    echo "prepare genesis: Collect genesis tx"
    "$PWD"/build/xted collect-gentxs --home "$DATA_DIR$i"
    echo "prepare genesis: Run validate-genesis to ensure everything worked and that the genesis file is setup correctly"
    "$PWD"/build/xted validate-genesis --home "$DATA_DIR$i"
}

start_func() {
    echo "starting xtechain node $i in background ..."
    "$PWD"/build/xted start --pruning=nothing --rpc.unsafe \
    --p2p.laddr tcp://$IP_ADDR:$NODE_P2P_PORT"$i" --address tcp://$IP_ADDR:$NODE_PORT"$i" --rpc.laddr tcp://$IP_ADDR:$NODE_RPC_PORT"$i" \
    --json-rpc.address=$IP_ADDR:$RPC_PORT"$i" \
    --keyring-backend test --home "$DATA_DIR$i" \
    >"$DATA_DIR"/node"$i".log 2>&1 & disown
    
    XTE_PID=$!
    echo "started xtechain node, pid=$XTE_PID"
    # add PID to array
    arr+=("$XTE_PID")
}

# Run node with static blockchain database
# For loop N times
for i in $(seq 1 "$QTD"); do
    init_func "$i"
    start_func "$i"
    sleep 1
    echo "sleeping $SLEEP_TIMEOUT seconds for startup"
    sleep "$SLEEP_TIMEOUT"
    echo "done sleeping"
done

echo "sleeping $SLEEP_TIMEOUT seconds before running tests ... "
sleep "$SLEEP_TIMEOUT"
echo "done sleeping"

set +e

if [[ -z $TEST || $TEST == "rpc" ]]; then
    
    for i in $(seq 1 "$TEST_QTD"); do
        HOST_RPC=http://$IP_ADDR:$RPC_PORT"$i"
        echo "going to test xtechain node $HOST_RPC ..."
        MODE=$MODE HOST=$HOST_RPC go test ./tests/e2e/... -timeout=300s -v -short
        MODE=$MODE HOST=$HOST_RPC go test ./tests/rpc/... -timeout=300s -v -short

        TEST_FAIL=$?
    done
    
fi

stop_func() {
    XTE_PID=$i
    echo "shutting down node, pid=$XTE_PID ..."
    
    # Shutdown xtechain node
    kill -9 "$XTE_PID"
    wait "$XTE_PID"
}


for i in "${arrcli[@]}"; do
    stop_func "$i"
done

for i in "${arr[@]}"; do
    stop_func "$i"
done

if [[ (-z $TEST || $TEST == "rpc") && $TEST_FAIL -ne 0 ]]; then
    exit $TEST_FAIL
else
    exit 0
fi
