import pytest

from .utils import (
    ADDRS,
    CONTRACTS,
    KEYS,
    deploy_contract,
    send_transaction,
    w3_wait_for_new_blocks,
)


def test_gas_eth_tx(geth, xtechain):
    tx_value = 10

    # send a transaction with geth
    geth_gas_price = geth.w3.eth.gas_price
    tx = {"to": ADDRS["community"], "value": tx_value, "gasPrice": geth_gas_price}
    geth_receipt = send_transaction(geth.w3, tx, KEYS["validator"])

    # send an equivalent transaction with xtechain
    xtechain_gas_price = xtechain.w3.eth.gas_price
    tx = {"to": ADDRS["community"], "value": tx_value, "gasPrice": xtechain_gas_price}
    xtechain_receipt = send_transaction(xtechain.w3, tx, KEYS["validator"])

    # ensure that the gasUsed is equivalent
    assert geth_receipt.gasUsed == xtechain_receipt.gasUsed


def test_gas_deployment(geth, xtechain):
    # deploy an identical contract on geth and xtechain
    # ensure that the gasUsed is equivalent
    _, geth_contract_receipt = deploy_contract(geth.w3, CONTRACTS["TestERC20A"])
    _, xtechain_contract_receipt = deploy_contract(
        xtechain.w3, CONTRACTS["TestERC20A"]
    )
    assert geth_contract_receipt.gasUsed == xtechain_contract_receipt.gasUsed


def test_gas_call(geth, xtechain):
    function_input = 10

    # deploy an identical contract on geth and xtechain
    # ensure that the contract has a function which consumes non-trivial gas
    geth_contract, _ = deploy_contract(geth.w3, CONTRACTS["BurnGas"])
    xtechain_contract, _ = deploy_contract(xtechain.w3, CONTRACTS["BurnGas"])

    # call the contract and get tx receipt for geth
    geth_gas_price = geth.w3.eth.gas_price
    geth_txhash = geth_contract.functions.burnGas(function_input).transact(
        {"from": ADDRS["validator"], "gasPrice": geth_gas_price}
    )
    geth_call_receipt = geth.w3.eth.wait_for_transaction_receipt(geth_txhash)

    # repeat the above for xtechain
    xtechain_gas_price = xtechain.w3.eth.gas_price
    xtechain_txhash = xtechain_contract.functions.burnGas(function_input).transact(
        {"from": ADDRS["validator"], "gasPrice": xtechain_gas_price}
    )
    xtechain_call_receipt = xtechain.w3.eth.wait_for_transaction_receipt(
        xtechain_txhash
    )

    # ensure that the gasUsed is equivalent
    assert geth_call_receipt.gasUsed == xtechain_call_receipt.gasUsed


def test_block_gas_limit(xtechain):
    tx_value = 10

    # get the block gas limit from the latest block
    w3_wait_for_new_blocks(xtechain.w3, 5)
    block = xtechain.w3.eth.get_block("latest")
    exceeded_gas_limit = block.gasLimit + 100

    # send a transaction exceeding the block gas limit
    xtechain_gas_price = xtechain.w3.eth.gas_price
    tx = {
        "to": ADDRS["community"],
        "value": tx_value,
        "gas": exceeded_gas_limit,
        "gasPrice": xtechain_gas_price,
    }

    # expect an error due to the block gas limit
    with pytest.raises(Exception):
        send_transaction(xtechain.w3, tx, KEYS["validator"])

    # deploy a contract on xtechain
    xtechain_contract, _ = deploy_contract(xtechain.w3, CONTRACTS["BurnGas"])

    # expect an error on contract call due to block gas limit
    with pytest.raises(Exception):
        xtechain_txhash = xtechain_contract.functions.burnGas(
            exceeded_gas_limit
        ).transact(
            {
                "from": ADDRS["validator"],
                "gas": exceeded_gas_limit,
                "gasPrice": xtechain_gas_price,
            }
        )
        (xtechain.w3.eth.wait_for_transaction_receipt(xtechain_txhash))

    return
