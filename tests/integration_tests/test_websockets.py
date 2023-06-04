def test_single_request_netversion(xtechain):
    xtechain.use_websocket()
    eth_ws = xtechain.w3.provider

    response = eth_ws.make_request("net_version", [])

    # net_version should be 9000
    assert response["result"] == "9527", "got " + response["result"] + ", expected 9527"

# note:
# batch requests still not implemented in web3.py
# todo: follow https://github.com/ethereum/web3.py/issues/832, add tests when complete

# eth_subscribe and eth_unsubscribe support still not implemented in web3.py
# todo: follow https://github.com/ethereum/web3.py/issues/1402, add tests when complete


def test_batch_request_netversion(xtechain):
    return


def test_ws_subscribe_log(xtechain):
    return


def test_ws_subscribe_newheads(xtechain):
    return
