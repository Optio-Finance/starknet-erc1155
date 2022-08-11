%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256

from introspection.ERC165 import ERC165_register_interface
from contracts.utils.constants import IERC1155_METADATA_ID

from contracts.utils.ShortString import uint256_to_ss
from contracts.utils.Array import concat_arr

#
# Storage
#

@storage_var
func ERC1155_base_token_uri(index: felt) -> (res: felt):
end

@storage_var
func ERC1155_base_token_uri_len() -> (res: felt):
end

@storage_var
func ERC1155_base_token_uri_suffix() -> (res: felt):
end


#
# Initializer
#

func ERC1155_Metadata_initializer{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}():
    ERC165_register_interface(IERC1155_METADATA_ID)
    return ()
end

func _ERC1155_Metadata_baseTokenURI{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}(
    base_token_uri_len : felt,
    base_token_uri : felt*
):
    if base_token_uri_len == 0:
        return ()
    end

    let (base) = ERC1155_base_token_uri.read(base_token_uri_len)
    assert [base_token_uri] = base

    _ERC1155_Metadata_baseTokenURI(
        base_token_uri_len=base_token_uri_len - 1,
        base_token_uri=base_token_uri + 1
    )
    return ()
end