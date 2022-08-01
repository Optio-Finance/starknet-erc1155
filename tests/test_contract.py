import os
import pytest

from starkware.starknet.testing.starknet import Starknet

CONTRACT_FILE = os.path.join("contracts", "erc1155.cairo")

@pytest.mark.asyncio
async def test_increase_balance():
    starknet = await Starknet.empty()
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )
    await contract.increase_balance(amount=10).invoke()
    await contract.increase_balance(amount=20).invoke()

    execution_info = await contract.get_balance().call()
    assert execution_info.result == (30,)