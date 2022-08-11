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

func ERC1155_Metadata_tokenURI{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}(
    token_id : Uint256
) -> (
    token_uri_len : felt,
    token_uri : felt*
):
    alloc_locals

    let (local base_token_uri) = alloc()
    let (local base_token_uri_len) = ERC1155_base_token_uri_len.read()

    _ERC1155_Metadata_baseTokenURI(base_token_uri_len, base_token_uri)
    let (token_id_ss_len, token_id_ss) = uint256_to_ss(token_id)
    let (token_uri_temp, token_uri_len_temp) = concat_arr(
        base_token_uri_len,
        base_token_uri,
        token_id_ss_len,
        token_id_ss,
    )

    let (ERC1155_base_token_uri_suffix_local) = ERC1155_base_token_uri_suffix.read()

    let (local suffix) = alloc()
    [suffix] = ERC1155_base_token_uri_suffix_local

    let (token_uri, token_uri_len) = concat_arr(
        token_uri_len_temp,
        token_uri_temp,
        1,
        suffix,
    )

    return (
        token_uri_len=token_uri_len,
        token_uri=token_uri
    )
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