%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_nn_le, assert_not_equal, assert_not_zero, assert_le
from starkware.cairo.common.alloc import alloc

from contracts.token.ERC1155.library import (
  _transfer_from,
  _batch_transfer_from,
  _assert_is_owner_or_approved
)

#
# Storage
#

@storage_var
func balances(owner : felt, token_id : felt) -> (res : felt):
end

@storage_var
func operator_approvals(owner : felt, operator : felt) -> (res : felt):
end

@storage_var
func initialized() -> (res : felt):
end

struct BlockchainNamespace:
    member a : felt
end

# ChainID. Chain Agnostic specifies that the length can go up to 32 nines (i.e. 9999999....)
# but we will only support 31 nines.
struct BlockchainReference:
    member a : felt
end

struct AssetNamespace:
    member a : felt
end

struct AssetReference:
    member a : felt
end

struct TokenId:
    member a : felt
end

# As defined by Chain Agnostics (CAIP-29 and CAIP-19):
# {blockchain_namespace}:{blockchain_reference}/{asset_namespace}:{asset_reference}/{token_id}
# tokenId will be represented by the substring '{id}'
struct TokenUri:
    member blockchain_namespace : BlockchainNamespace
    member blockchain_reference : BlockchainReference
    member asset_namespace : AssetNamespace
    member asset_reference : AssetReference
    member token_id : TokenId
end

@storage_var
func _uri() -> (res: TokenUri):
end

#
# Constructor
#

@constructor
func constructor{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}(
    recipient : felt,
    tokens_id_len : felt,
    tokens_id : felt*,
    amounts_len : felt,
    amounts : felt*,
    uri_ : TokenUri
):
    _mint_batch(recipient, tokens_id_len, tokens_id, amounts_len, amounts)
    _set_uri(uri_)
    return ()
end

func _set_uri{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}(
    uri_ : TokenUri
):
    _uri.write(uri_)
    return()
end

#
# Initializer
#

@external
func initialize_batch{
    pedersen_ptr : HashBuiltin*,
    syscall_ptr : felt*,
    range_check_ptr
}(
    tokens_id_len : felt,
    tokens_id : felt*,
    amounts_len : felt,
    amounts : felt*,
    uri_ : TokenUri
):
    let (_initialized) = initialized.read()
    assert _initialized = 0
    initialized.write(1)
    let (sender) = get_caller_address()
    _mint_batch(sender, tokens_id_len, tokens_id, amounts_len, amounts)
    _set_uri(uri_)
    return ()
end

func _mint{
    pedersen_ptr : HashBuiltin*,
    syscall_ptr : felt*,
    range_check_ptr
}(
    to : felt,
    token_id : felt,
    amount : felt
) -> ():
    assert_not_zero(to)
    let (res) = balances.read(owner=to, token_id=token_id)
    balances.write(to, token_id, res + amount)
    return ()
end

func _mint_batch{
    pedersen_ptr : HashBuiltin*,
    syscall_ptr : felt*,
    range_check_ptr
}(
    to : felt,
    tokens_id_len : felt,
    tokens_id : felt*,
    amounts_len : felt,
    amounts : felt*
) -> ():
    assert_not_zero(to)
    assert tokens_id_len = amounts_len

    if tokens_id_len == 0:
        return ()
    end

    _mint(to, tokens_id[0], amounts[0])

    return _mint_batch(
        to=to,
        tokens_id_len=tokens_id_len - 1,
        tokens_id=tokens_id + 1,
        amounts_len=amounts_len - 1,
        amounts=amounts + 1)
end

#
# Getters
#

# Returns the same URI for all tokens type ID
# Client calling the function must replace the {id} substring with the actual token type ID
@view
func uri{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
}() -> (
    res : TokenUri
):
    let (res) = _uri.read()
    return (res)
end

@view
func balance_of{
    pedersen_ptr : HashBuiltin*,
    syscall_ptr : felt*,
    range_check_ptr
}(
    owner : felt,
    token_id : felt
) -> (res : felt):
    assert_not_zero(owner)
    let (res) = balances.read(owner=owner, token_id=token_id)
    return (res)
end

@view
func balance_of_batch{
    pedersen_ptr : HashBuiltin*,
    syscall_ptr : felt*,
    range_check_ptr
}(
    owners_len : felt,
    owners : felt*,
    tokens_id_len : felt,
    tokens_id : felt*
) -> (
    res_len : felt,
    res : felt*
):
    assert owners_len = tokens_id_len
    alloc_locals
    local max = owners_len
    let (local ret_array : felt*) = alloc()
    local ret_index = 0
    populate_balance_of_batch(owners, tokens_id, ret_array, ret_index, max)
    return (max, ret_array)
end

func populate_balance_of_batch{
    pedersen_ptr : HashBuiltin*,
    syscall_ptr : felt*,
    range_check_ptr
}(
    owners : felt*,
    tokens_id : felt*,
    rett : felt*,
    ret_index : felt,
    max : felt
):
    alloc_locals
    if ret_index == max:
        return ()
    end
    let (local retval0 : felt) = balances.read(owner=owners[0], token_id=tokens_id[0])
    rett[0] = retval0
    populate_balance_of_batch(owners + 1, tokens_id + 1, rett + 1, ret_index + 1, max)
    return ()
end

#
# Approvals
#

@view
func is_approved_for_all{
    pedersen_ptr : HashBuiltin*,
    syscall_ptr : felt*,
    range_check_ptr
}(
    account : felt,
    operator : felt
) -> (
    res : felt
):
    let (res) = operator_approvals.read(owner=account, operator=operator)
    return (res=res)
end

@external
func set_approval_for_all{
    pedersen_ptr : HashBuiltin*,
    syscall_ptr : felt*,
    range_check_ptr
}(
    operator : felt,
    approved : felt
):
    let (account) = get_caller_address()
    assert_not_equal(account, operator)
    assert approved * (1 - approved) = 0
    operator_approvals.write(account, operator, approved)
    return ()
end

#
# Transfer from
#

@external
func safe_transfer_from{
    pedersen_ptr : HashBuiltin*,
    syscall_ptr : felt*,
    range_check_ptr
}(
    _from : felt,
    to : felt,
    token_id : felt,
    amount : felt
):
    _assert_is_owner_or_approved(_from)
    _transfer_from(_from, to, token_id, amount)
    return ()
end

@external
func safe_batch_transfer_from{
    pedersen_ptr : HashBuiltin*,
    syscall_ptr : felt*,
    range_check_ptr
}(
    _from : felt,
    to : felt,
    tokens_id_len : felt,
    tokens_id : felt*,
    amounts_len : felt,
    amounts : felt*
):
    _assert_is_owner_or_approved(_from)
    _batch_transfer_from(_from, to, tokens_id_len, tokens_id, amounts_len, amounts)
    return ()
end

#
# Burn
#

@external
func _burn{
    pedersen_ptr : HashBuiltin*,
    syscall_ptr : felt*,
    range_check_ptr
}(
    _from : felt,
    token_id : felt,
    amount : felt
):
    assert_not_zero(_from)
    let (from_balance) = balance_of(_from, token_id)
    assert_le(amount, from_balance)
    balances.write(_from, token_id, from_balance - amount)
    return ()
end

@external
func _burn_batch{
    pedersen_ptr : HashBuiltin*,
    syscall_ptr : felt*,
    range_check_ptr
}(
    _from : felt,
    tokens_id_len : felt,
    tokens_id : felt*,
    amounts_len : felt,
    amounts : felt*
):
    assert_not_zero(_from)

    # TODO: Modularity
    let (caller) = get_caller_address()
    with_attr error_message("ERC1155: called from zero address"):
        assert_not_zero(caller)
    end
    
    assert tokens_id_len = amounts_len
    if tokens_id_len == 0:
        return ()
    end
    _burn(_from, [tokens_id], [amounts])
    return _burn_batch(
        _from=_from,
        tokens_id_len=tokens_id_len - 1,
        tokens_id=tokens_id + 1,
        amounts_len=amounts_len - 1,
        amounts=amounts + 1)
end