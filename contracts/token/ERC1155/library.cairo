%lang starknet
%builtins pedersen range_check ecdsa


func _transfer_from{
    pedersen_ptr : HashBuiltin*,
    syscall_ptr : felt*,
    range_check_ptr
}(
    sender : felt,
    recipient : felt,
    token_id : felt,
    amount : felt
):
    assert_not_zero(recipient)
    let (sender_balance) = balances.read(owner=sender, token_id=token_id)
    assert_nn_le(amount, sender_balance)
    balances.write(sender, token_id, sender_balance - amount)
    let (res) = balances.read(owner=recipient, token_id=token_id)
    balances.write(recipient, token_id, res + amount)
    return ()
end

func _batch_transfer_from{
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
    assert_not_zero(to)

    with_attr error_message("ERC1155: tokens length not equal to passed args"):
        assert tokens_id_len = amounts_len
    end

    if tokens_id_len == 0:
        return ()
    end
    _transfer_from(_from, to, [tokens_id], [amounts])
    return _batch_transfer_from(
        _from=_from,
        to=to,
        tokens_id_len=tokens_id_len - 1,
        tokens_id=tokens_id + 1,
        amounts_len=amounts_len - 1,
        amounts=amounts + 1)
end

func _assert_is_owner_or_approved{
    pedersen_ptr : HashBuiltin*,
    syscall_ptr : felt*,
    range_check_ptr}(address : felt
):
    let (caller) = get_caller_address()

    if caller == address:
        return ()
    end

    let (operator_is_approved) = is_approved_for_all(
        account=address,
        operator=caller
    )
    assert operator_is_approved = 1
    
    return ()
end