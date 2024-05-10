//! Getters for fields on transaction inputs.
//! This includes `Input::Coins`, `Input::Messages` and `Input::Contracts`.
library;

use ::address::Address;
use ::alloc::alloc_bytes;
use ::assert::assert;
use ::asset_id::AssetId;
use ::bytes::Bytes;
use ::contract_id::ContractId;
use ::option::Option::{self, *};
use ::revert::revert;
use ::tx::{
    GTF_CREATE_INPUT_AT_INDEX,
    GTF_CREATE_INPUTS_COUNT,
    GTF_SCRIPT_INPUT_AT_INDEX,
    GTF_SCRIPT_INPUTS_COUNT,
    Transaction,
    tx_type,
};
use core::ops::Eq;

const GTF_INPUT_TYPE = 0x200;

// GTF Opcode const selectors
//
// pub const GTF_INPUT_COIN_TX_ID = 0x201;
// pub const GTF_INPUT_COIN_OUTPUT_INDEX = 0x202;
pub const GTF_INPUT_COIN_OWNER = 0x203;
pub const GTF_INPUT_COIN_AMOUNT = 0x204;
pub const GTF_INPUT_COIN_ASSET_ID = 0x205;
pub const GTF_INPUT_COIN_WITNESS_INDEX = 0x207;
pub const GTF_INPUT_COIN_PREDICATE_LENGTH = 0x209;
pub const GTF_INPUT_COIN_PREDICATE_DATA_LENGTH = 0x20A;
pub const GTF_INPUT_COIN_PREDICATE = 0x20B;
pub const GTF_INPUT_COIN_PREDICATE_DATA = 0x20C;

// pub const GTF_INPUT_CONTRACT_CONTRACT_ID = 0x225;
pub const GTF_INPUT_MESSAGE_SENDER = 0x240;
pub const GTF_INPUT_MESSAGE_RECIPIENT = 0x241;
pub const GTF_INPUT_MESSAGE_AMOUNT = 0x242;
pub const GTF_INPUT_MESSAGE_NONCE = 0x243;
pub const GTF_INPUT_MESSAGE_WITNESS_INDEX = 0x244;
pub const GTF_INPUT_MESSAGE_DATA_LENGTH = 0x245;
pub const GTF_INPUT_MESSAGE_PREDICATE_LENGTH = 0x246;
pub const GTF_INPUT_MESSAGE_PREDICATE_DATA_LENGTH = 0x247;
pub const GTF_INPUT_MESSAGE_DATA = 0x248;
pub const GTF_INPUT_MESSAGE_PREDICATE = 0x249;
pub const GTF_INPUT_MESSAGE_PREDICATE_DATA = 0x24A;

/// The input type for a transaction.
pub enum Input {
    /// A coin input.
    Coin: (),
    /// A contract input.
    Contract: (),
    /// A message input.
    Message: (),
}

impl Eq for Input {
    fn eq(self, other: Self) -> bool {
        match (self, other) {
            (Input::Coin, Input::Coin) => true,
            (Input::Contract, Input::Contract) => true,
            (Input::Message, Input::Message) => true,
            _ => false,
        }
    }
}

// General Inputs

/// Gets the type of the input at `index`.
///
/// # Additional Information
///
/// The Input can be of 3 variants, `Input::Coin`, `Input::Contract` or `Input::Message`.
///
/// # Arguments
///
/// * `index`: [u64] - The index of the input to check.
///
/// # Returns
///
/// * [Input] - The type of the input at `index`.
///
/// # Examples
///
/// ```sway
/// use std::inputs::input_type;
///
/// fn foo() {
///     let input_type = input_type(0);
///     assert(input_type == Input::Coin);
/// }
/// ```
pub fn input_type(index: u64) -> Input {
    match __gtf::<u8>(index, GTF_INPUT_TYPE) {
        0u8 => Input::Coin,
        1u8 => Input::Contract,
        2u8 => Input::Message,
        _ => revert(0),
    }
}

/// Gets the transaction inputs count.
///
/// # Returns
///
/// * [u8] - The number of inputs in the transaction.
///
/// # Examples
///
/// ```sway
/// use std::inputs::input_count;
///
/// fn foo() {
///     let input_count = input_count();
///     assert(input_count == 1);
/// }
/// ```
pub fn input_count() -> u8 {
    match tx_type() {
        Transaction::Script => __gtf::<u8>(0, GTF_SCRIPT_INPUTS_COUNT),
        Transaction::Create => __gtf::<u8>(0, GTF_CREATE_INPUTS_COUNT),
    }
}

/// Gets the pointer of the input at `index`.
///
/// # Arguments
///
/// * `index`: [u64] - The index of the input to check.
///
/// # Returns
///
/// * [u64] - The pointer of the input at `index`.
///
/// # Examples
///
/// ```sway
/// use std::inputs::input_pointer;
///
/// fn foo() {
///     let input_pointer = input_pointer(0);
/// }
/// ```
pub fn input_pointer(index: u64) -> u64 {
    match tx_type() {
        Transaction::Script => __gtf::<u64>(index, GTF_SCRIPT_INPUT_AT_INDEX),
        Transaction::Create => __gtf::<u64>(index, GTF_CREATE_INPUT_AT_INDEX),
    }
}

/// Gets amount field from input at `index`.
///
/// # Arguments
///
/// * `index`: [u64] - The index of the input to check.
///
/// # Returns
///
/// * [Option<u64>] - The amount of the input at `index`, if the input's type is `Input::Coin` or `Input::Message`, else `None`.
///
/// # Examples
///
/// ```sway
/// use std::inputs::input_amount;
///
/// fn foo() {
///     let input_amount = input_amount(0);
///     assert(input_amount.unwrap() == 100);
/// }
/// ```
pub fn input_amount(index: u64) -> Option<u64> {
    match input_type(index) {
        Input::Coin => Some(__gtf::<u64>(index, GTF_INPUT_COIN_AMOUNT)),
        Input::Message => Some(__gtf::<u64>(index, GTF_INPUT_MESSAGE_AMOUNT)),
        Input::Contract => None,
    }
}

/// Gets owner field from input at `index` if it's a coin.
///
/// # Arguments
///
/// * `index`: [u64] - The index of the input to check.
///
/// # Returns
///
/// * [Option<Address>] - The owner of the input at `index`, if the input's type is `Input::Coin`, else `None`.
///
/// # Examples
///
/// ```sway
/// use std::inputs::input_coin_owner;
///
/// fn foo() {
///     let input_coin_owner = input_coin_owner(0);
///     assert(input_coin_owner.is_some()); // Ensure the input is a coin input.
/// }
/// ```
pub fn input_coin_owner(index: u64) -> Option<Address> {
    match input_type(index) {
        Input::Coin => Some(Address::from(__gtf::<b256>(index, GTF_INPUT_COIN_OWNER))),
        _ => None,
    }
}

/// Gets the predicate data pointer from the input at `index`.
///
/// # Arguments
///
/// * `index`: [u64] - The index of the input to check.
///
/// # Returns
///
/// * [Option<raw_ptr>] - The predicate data pointer of the input at `index`, if the input's type is `Input::Coin` or `Input::Message`, else `None`.
///
/// # Examples
///
/// ```sway
/// use std::inputs::input_predicate_data_pointer;
///
/// fn foo() {
///     let input_predicate_data_pointer = input_predicate_data_pointer(0);
///     assert(input_predicate_data_pointer.is_some()); // Ensure the input is a coin or message input.
/// }
pub fn input_predicate_data_pointer(index: u64) -> Option<raw_ptr> {
    match input_type(index) {
        Input::Coin => Some(__gtf::<raw_ptr>(index, GTF_INPUT_COIN_PREDICATE_DATA)),
        Input::Message => Some(__gtf::<raw_ptr>(index, GTF_INPUT_MESSAGE_PREDICATE_DATA)),
        Input::Contract => None,
    }
}

/// Gets the predicate data from the input at `index`.
///
/// # Arguments
///
/// * `index`: [u64] - The index of the input to check.
///
/// # Returns
///
/// * [T] - The predicate data of the input at `index`.
///
/// # Examples
///
/// ```sway
/// use std::inputs::input_predicate_data;
///
/// fn foo() {
///     let input_predicate_data: u64 = input_predicate_data(0);
///     assert(input_predicate_data == 100);
/// }
/// ```
pub fn input_predicate_data<T>(index: u64) -> T
where
    T: AbiDecode,
{
    use core::codec::decode_predicate_data_by_index;
    decode_predicate_data_by_index::<T>(index)
}

/// Gets the AssetId of the input at `index`.
///
/// # Arguments
///
/// * `index`: [u64] - The index of the input to check.
///
/// # Returns
///
/// * [Option<AssetId>] - The asset_id of the input at `index`, if the input's type is `Input::Coin` or `Input::Message`, else `None`.
///
/// # Examples
///
/// ```sway
/// use std::inputs::input_asset_id;
///
/// fn foo() {
///     let input_asset_id = input_asset_id(0);
///     assert(input_asset_id.unwrap() == AssetId::base());
/// }
/// ```
pub fn input_asset_id(index: u64) -> Option<AssetId> {
    match input_type(index) {
        Input::Coin => Some(AssetId::from(__gtf::<b256>(index, GTF_INPUT_COIN_ASSET_ID))),
        Input::Message => Some(AssetId::base()),
        Input::Contract => None,
    }
}

/// Gets the witness index from the input at `index`.
///
/// # Arguments
///
/// * `index`: [u64] - The index of the input to check.
///
/// # Returns
///
/// * [Option<u8>] - The witness index of the input at `index`, if the input's type is `Input::Coin` or `Input::Message`, else `None`.
///
/// # Examples
///
/// ```sway
/// use std::inputs::input_witness_index;
///
/// fn foo() {
///     let input_witness_index = input_witness_index(0);
///     assert(input_witness_index.is_some()); // Ensure the input has a witness index.
/// }
/// ```
pub fn input_witness_index(index: u64) -> Option<u8> {
    match input_type(index) {
        Input::Coin => Some(__gtf::<u8>(index, GTF_INPUT_COIN_WITNESS_INDEX)),
        Input::Message => Some(__gtf::<u8>(index, GTF_INPUT_MESSAGE_WITNESS_INDEX)),
        Input::Contract => None,
    }
}

/// Gets the predicate length from the input at `index`.
///
/// # Arguments
///
/// * `index`: [u64] - The index of the input to check.
///
/// # Returns
///
/// * [Option<u16>] - The predicate length of the input at `index`, if the input's type is `Input::Coin` or `Input::Message`, else `None`.
///
/// # Examples
///
/// ```sway
/// use std::inputs::input_predicate_length;
///
/// fn foo() {
///     let input_predicate_length = input_predicate_length(0);
///     assert(input_predicate_length.unwrap() != 0u16);
/// }
/// ```
pub fn input_predicate_length(index: u64) -> Option<u16> {
    match input_type(index) {
        Input::Coin => Some(__gtf::<u16>(index, GTF_INPUT_COIN_PREDICATE_LENGTH)),
        Input::Message => Some(__gtf::<u16>(index, GTF_INPUT_MESSAGE_PREDICATE_LENGTH)),
        Input::Contract => None,
    }
}

/// Gets the predicate pointer from the input at `index`.
///
/// # Arguments
///
/// * `index`: [u64] - The index of the input to check.
///
/// # Returns
///
/// * [Option<raw_ptr>] - The predicate pointer of the input at `index`, if the input's type is `Input::Coin` or `Input::Message`, else `None`.
///
/// # Examples
///
/// ```sway
/// use std::inputs::input_predicate_pointer;
///
/// fn foo() {
///     let input_predicate_pointer = input_predicate_pointer(0);
///     assert(input_predicate_pointer.is_some());
/// }
/// ```
pub fn input_predicate_pointer(index: u64) -> Option<raw_ptr> {
    match input_type(index) {
        Input::Coin => Some(__gtf::<raw_ptr>(index, GTF_INPUT_COIN_PREDICATE)),
        Input::Message => Some(__gtf::<raw_ptr>(index, GTF_INPUT_MESSAGE_PREDICATE)),
        Input::Contract => None,
    }
}

/// Gets the predicate from the input at `index`.
///
/// # Arguments
///
/// * `index`: [u64] - The index of the input to check.
///
/// # Returns
///
/// * [Bytes] - The predicate bytecode of the input at `index`, if the input's type is `Input::Coin` or `Input::Message`.
///
/// # Reverts
///
/// * When the input's type is not `Input::Coin` or `Input::Message`.
///
/// # Examples
///
/// ```sway
/// use std::inputs::input_predicate;
///
/// fn foo() {
///     let input_predicate = input_predicate(0);
///     assert(input_predicate.len() != 0);
/// }
/// ```
pub fn input_predicate(index: u64) -> Bytes {
    let wrapped = input_predicate_length(index);
    if wrapped.is_none() {
        revert(0);
    };
    let length = wrapped.unwrap().as_u64();
    let new_ptr = alloc_bytes(length);
    match input_predicate_pointer(index) {
        Some(d) => {
            d.copy_bytes_to(new_ptr, length);
            Bytes::from(raw_slice::from_parts::<u8>(new_ptr, length))
        },
        None => revert(0),
    }
}

/// Gets the predicate data length from the input at `index`.
///
/// # Arguments
///
/// * `index`: [u64] - The index of the input to check.
///
/// # Returns
///
/// * [Option<u16>] - The predicate data length of the input at `index`, if the input's type is `Input::Coin` or `Input::Message`, else `None`.
///
/// # Examples
///
/// ```sway
/// use std::inputs::input_predicate_data_length;
///
/// fn foo() {
///     let input_predicate_data_length = input_predicate_data_length(0);
///     assert(input_predicate_data_length.unwrap() != 0_u16);
/// }
/// ```
pub fn input_predicate_data_length(index: u64) -> Option<u16> {
    match input_type(index) {
        Input::Coin => Some(__gtf::<u16>(index, GTF_INPUT_COIN_PREDICATE_DATA_LENGTH)),
        Input::Message => Some(__gtf::<u16>(index, GTF_INPUT_MESSAGE_PREDICATE_DATA_LENGTH)),
        Input::Contract => None,
    }
}

// Coin Inputs

/// Gets the sender of the input message at `index`.
///
/// # Arguments
///
/// * `index`: [u64] - The index of the input to check.
///
/// # Returns
///
/// * [Address] - The sender of the input message at `index`, if the input's type is `Input::Message`.
///
/// # Examples
///
/// ```sway
/// use std::{constants::ZERO_B256, inputs::input_message_sender};
///
/// fn foo() {
///     let input_message_sender = input_message_sender(0);
///     assert(input_message_sender != Address::from(ZERO_B256));
/// }
/// ```
pub fn input_message_sender(index: u64) -> Address {
    Address::from(__gtf::<b256>(index, GTF_INPUT_MESSAGE_SENDER))
}

/// Gets the recipient of the input message at `index`.
///
/// # Arguments
///
/// * `index`: [u64] - The index of the input to check.
///
/// # Returns
///
/// * [Address] - The recipient of the input message at `index`, if the input's type is `Input::Message`.
///
/// # Examples
///
/// ```sway
/// use std::{constants::ZERO_B256, inputs::input_message_recipient};
///
/// fn foo() {
///     let input_message_recipient = input_message_recipient(0);
///     assert(input_message_recipient != Address::from(ZERO_B256));
/// }
/// ```
pub fn input_message_recipient(index: u64) -> Address {
    Address::from(__gtf::<b256>(index, GTF_INPUT_MESSAGE_RECIPIENT))
}

/// Gets the nonce of input message at `index`.
///
/// # Arguments
///
/// * `index`: [u64] - The index of the input to check.
///
/// # Returns
///
/// * [b256] - The nonce of the input message at `index`, if the input's type is `Input::Message`.
///
/// # Examples
///
/// ```sway
/// use std::{constants::ZERO_B256, inputs::input_message_nonce};
///
/// fn foo() {
///     let input_message_nonce = input_message_nonce(0);
///     assert(input_message_nonce != b256::from(ZERO_B256));
/// }
/// ```
pub fn input_message_nonce(index: u64) -> b256 {
    __gtf::<b256>(index, GTF_INPUT_MESSAGE_NONCE)
}

/// Gets the length of the input message at `index`.
///
/// # Arguments
///
/// * `index`: [u64] - The index of the input to check.
///
/// # Returns
///
/// * [u16] - The length of the input message at `index`, if the input's type is `Input::Message`.
///
/// # Examples
///
/// ```sway
/// use std::inputs::input_message_length;
///
/// fn foo() {
///     let input_message_length = input_message_length(0);
///     assert(input_message_length != 0_u16);
/// }
/// ```
pub fn input_message_data_length(index: u64) -> u16 {
    __gtf::<u16>(index, GTF_INPUT_MESSAGE_DATA_LENGTH)
}

/// Gets the data of the input message at `index`.
///
/// # Arguments
///
/// * `index`: [u64] - The index of the input to check.
/// * `offset`: [u64] - The offset to start reading the data from.
///
/// # Returns
///
/// * [Bytes] - The data of the input message at `index`, if the input's type is `Input::Message`.
///
/// # Reverts
///
/// * When the input's type is not `Input::Message`.
///
/// # Examples
///
/// ```sway
/// use std::inputs::input_message_data;
///
/// fn foo() {
///     let input_message_data = input_message_data(0, 0);
///     assert(input_message_data.len() != 0);
/// }
/// ```
pub fn input_message_data(index: u64, offset: u64) -> Bytes {
    assert(valid_input_type(index, Input::Message));
    let data = __gtf::<raw_ptr>(index, GTF_INPUT_MESSAGE_DATA);
    let data_with_offset = data.add_uint_offset(offset);
    let length = input_message_data_length(index).as_u64();
    let new_ptr = alloc_bytes(length);

    data_with_offset.copy_bytes_to(new_ptr, length);
    Bytes::from(raw_slice::from_parts::<u8>(new_ptr, length))
}

fn valid_input_type(index: u64, expected_type: Input) -> bool {
    input_type(index) == expected_type
}
