%lang starknet

from starkware.cairo.common.uint256 import Uint256

const IERC1155_RECEIVER_ID = 0x4e2312e0
const ON_ERC1155_RECEIVED_SELECTOR = 0xf23a6e61
const ON_BATCH_ERC1155_RECEIVED_SELECTOR = 0xbc197c81

@external
func supportsInterface(interfaceId : felt) -> (success : felt):
    if interfaceId == IERC1155_RECEIVER_ID:
        return (1)
    else:
        return (0)
    end
end
