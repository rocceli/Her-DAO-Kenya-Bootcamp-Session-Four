use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, spy_events,
    EventSpyAssertionsTrait,};

use count::{Counter, ICounterDispatcher, ICounterDispatcherTrait};

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
fn test_reset_counter() {
    let initial_count = 0x10; // 16
    let counter = deploy_counter(initial_count);
    
    let owner_address = owner();
    start_cheat_caller_address(counter.contract_address, owner_address);

    counter.reset_counter();
    
    assert(counter.get_counter() == 0x0, 'Absolute mess');
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
fn test_increament_counter_event() {
    let owner_address = owner();

    let initial_count = 0x10; // 16
    let counter = deploy_counter(initial_count);

    start_cheat_caller_address(counter.contract_address, owner_address);
    let dispatcher = ICounterDispatcher { contract_address: counter.contract_address };

    let pre_count = counter.get_counter();

    let mut events = spy_events();
    dispatcher.increase_counter();
    events
        .assert_emitted(
            @array![
                (
                    counter.contract_address,
                    Counter::Event::CounterIncreased(
                        Counter::CounterIncreased{ counter: pre_count + 1 }
                    )
                )
            ]
        );
}

#[test]
fn test_reset_counter_event() {
    let owner_address = owner();

    let initial_count = 0x10; // 16
    let counter = deploy_counter(initial_count);

    start_cheat_caller_address(counter.contract_address, owner_address);
    let dispatcher = ICounterDispatcher { contract_address: counter.contract_address };

    let mut events = spy_events();
    dispatcher.reset_counter();
    events
        .assert_emitted(
            @array![
                (
                    counter.contract_address,
                    Counter::Event::CounterReset(
                        Counter::CounterReset{ counter: 0x0 }
                    )
                )
            ]
        );
}

#[test]
fn test_decrement_counter_event() {
    let owner_address = owner();

    let initial_count = 0x10; // 16
    let counter = deploy_counter(initial_count);

    start_cheat_caller_address(counter.contract_address, owner_address);
    let dispatcher = ICounterDispatcher { contract_address: counter.contract_address };

    let pre_count = counter.get_counter();

    let mut events = spy_events();
    dispatcher.decrease_counter();
    events
        .assert_emitted(
            @array![
                (
                    counter.contract_address,
                    Counter::Event::CounterDecreased(
                        Counter::CounterDecreased{ counter: pre_count - 1 }
                    )
                )
            ]
        );
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
