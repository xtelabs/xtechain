#!/bin/bash

echo "prepare genesis: Run validate-genesis to ensure everything worked and that the genesis file is setup correctly"
./xted validate-genesis --home /xtechain

echo "starting xtechain node $ID in background ..."
./xted start \
--home /xtechain \
--keyring-backend test

echo "started xtechain node"
tail -f /dev/null