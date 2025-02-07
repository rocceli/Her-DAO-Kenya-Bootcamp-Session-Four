use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

use count::{ICounterDispatcher, ICounterDispatcherTrait};

fn owner() -> ContractAddress {
    'owner'.try_into().unwrap()
}

fn deploy_counter(initial_count: u32) -> ICounterDispatcher {
    let contract_class = declare("Counter").unwrap().contract_class();

    let mut calldata = array![];
    initial_count.serialize(ref calldata);
    owner().serialize(ref calldata);

    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();

    ICounterDispatcher { contract_address }
}

#[test]
fn test_deploy_contract() {
    let initial_count = 3;
    let counter = deploy_counter(initial_count);

    let current_count = counter.get_counter();

    assert(current_count == initial_count, 'Not looking good');
}

#[test]
#[should_panic]
fn test_reset_counter() {
    let initial_count = 0x10; // 16
    let counter = deploy_counter(initial_count);

    counter.reset_counter();
}

#[test]
fn test_decrementing_counter() {
    let initial_count = 0x10; // 16
    let counter = deploy_counter(initial_count);

    let pre_count = counter.get_counter();
    counter.decrease_counter();

    assert(counter.get_counter() == pre_count - 1, 'Absolute mess');
}


#[test]
fn test_increament_counter() {
    let initial_count = 0x10; // 16
    let counter = deploy_counter(initial_count);

    let pre_count = counter.get_counter();
    counter.increase_counter();
    
    assert(counter.get_counter() == pre_count + 1, 'Absolute mess');
}


#[test]
#[should_panic]
fn test_decrement_counter_underflow() {
    let initial_count = 0x0; // min value of 0
    let counter = deploy_counter(initial_count);

    counter.decrease_counter();
}

#[test]
#[should_panic]
fn test_increament_counter_overflow() {
    let initial_count = 0xffffffff; // max value of u32
    let counter = deploy_counter(initial_count);

    counter.increase_counter();
}
