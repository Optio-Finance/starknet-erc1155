%lang starknet

from introspection.ERC165 import ERC165_register_interface

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