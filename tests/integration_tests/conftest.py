import pytest

from .network import setup_xtechain, setup_geth


@pytest.fixture(scope="session")
def xtechain(tmp_path_factory):
    path = tmp_path_factory.mktemp("xtechain")
    yield from setup_xtechain(path, 26650)


@pytest.fixture(scope="session")
def geth(tmp_path_factory):
    path = tmp_path_factory.mktemp("geth")
    yield from setup_geth(path, 8545)


@pytest.fixture(
    scope="session", params=["xtechain", "xtechain-ws"]
)
def xtechain_rpc_ws(request, xtechain):
    """
    run on both xtechain and xtechain websocket
    """
    provider = request.param
    if provider == "xtechain":
        yield xtechain
    elif provider == "xtechain-ws":
        xtechain_ws = xtechain.copy()
        xtechain_ws.use_websocket()
        yield xtechain_ws
    else:
        raise NotImplementedError
