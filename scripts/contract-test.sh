#!/bin/bash

KEY="mykey"
CHAINID="xtechain_9527-1"
MONIKER="localtestnet"

# stop and remove existing daemon and client data and process(es)
rm -rf ~/.xtechain*
pkill -f "xte*"

make build-xtechain

# if $KEY exists it should be override
"$PWD"/build/xted keys add $KEY --keyring-backend test --algo "eth_secp256k1"

# Set moniker and chain-id for xtechain (Moniker can be anything, chain-id must be an integer)
"$PWD"/build/xted init $MONIKER --chain-id $CHAINID

# Change parameter token denominations to axte
cat $HOME/.xtechain/config/genesis.json | jq '.app_state["staking"]["params"]["bond_denom"]="axte"' > $HOME/.xtechain/config/tmp_genesis.json && mv $HOME/.xtechain/config/tmp_genesis.json $HOME/.xtechain/config/genesis.json
cat $HOME/.xtechain/config/genesis.json | jq '.app_state["crisis"]["constant_fee"]["denom"]="axte"' > $HOME/.xtechain/config/tmp_genesis.json && mv $HOME/.xtechain/config/tmp_genesis.json $HOME/.xtechain/config/genesis.json
cat $HOME/.xtechain/config/genesis.json | jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="axte"' > $HOME/.xtechain/config/tmp_genesis.json && mv $HOME/.xtechain/config/tmp_genesis.json $HOME/.xtechain/config/genesis.json
cat $HOME/.xtechain/config/genesis.json | jq '.app_state["mint"]["params"]["mint_denom"]="axte"' > $HOME/.xtechain/config/tmp_genesis.json && mv $HOME/.xtechain/config/tmp_genesis.json $HOME/.xtechain/config/genesis.json

# Allocate genesis accounts (cosmos formatted addresses)
"$PWD"/build/xted add-genesis-account "$("$PWD"/build/xted keys show "$KEY" -a --keyring-backend test)" 100000000000000000000axte --keyring-backend test

# Sign genesis transaction
"$PWD"/build/xted gentx $KEY --amount=100000000000000000000axte --keyring-backend test --chain-id $CHAINID

# Collect genesis tx
"$PWD"/build/xted collect-gentxs

# Run this to ensure everything worked and that the genesis file is setup correctly
"$PWD"/build/xted validate-genesis

# Start the node (remove the --pruning=nothing flag if historical queries are not needed) in background and log to file
"$PWD"/build/xted start --pruning=nothing --rpc.unsafe --json-rpc.address="127.0.0.1:8545" --keyring-backend test > xted.log 2>&1 &

# Give xted node enough time to launch
sleep 5

solcjs --abi "$PWD"/tests/solidity/suites/basic/contracts/Counter.sol --bin -o "$PWD"/tests/solidity/suites/basic/counter
mv "$PWD"/tests/solidity/suites/basic/counter/*.abi "$PWD"/tests/solidity/suites/basic/counter/counter_sol.abi 2> /dev/null
mv "$PWD"/tests/solidity/suites/basic/counter/*.bin "$PWD"/tests/solidity/suites/basic/counter/counter_sol.bin 2> /dev/null

# Query for the account
ACCT=$(curl --fail --silent -X POST --data '{"jsonrpc":"2.0","method":"eth_accounts","params":[],"id":1}' -H "Content-Type: application/json" http://localhost:8545 | grep -o '\0x[^"]*')
echo "$ACCT"

# Start testcases (not supported)
# curl -X POST --data '{"jsonrpc":"2.0","method":"personal_unlockAccount","params":["'$ACCT'", ""],"id":1}' -H "Content-Type: application/json" http://localhost:8545

#PRIVKEY="$("$PWD"/build/xted keys export $KEY)"

## need to get the private key from the account in order to check this functionality.
cd tests/solidity/suites/basic/ && go get && go run main.go $ACCT

# After tests
# kill test xted
echo "going to shutdown xted in 3 seconds..."
sleep 3
pkill -f "xte*"