#[starknet::interface]
pub trait ICounter<TContractState> {
    fn get_counter(self: @TContractState) -> u32;
    fn increase_counter(ref self: TContractState);
    fn decrease_counter(ref self: TContractState);
    fn reset_counter(ref self: TContractState);
}

#[starknet::contract]
pub mod Counter {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{StoragePointerWriteAccess, StoragePointerReadAccess};
    #[storage]
    struct Storage {
        counter: u32,
        owner: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CounterIncreased: CounterIncreased,
        CounterDecreased: CounterDecreased,
        CounterReset: CounterReset,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CounterIncreased {
        pub counter: u32,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CounterReset {
        pub counter: u32,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CounterDecreased {
        pub counter: u32,
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_counter: u32, owner: ContractAddress) {
        self.counter.write(initial_counter);
        self.owner.write(owner);
    }

    #[abi(embed_v0)]
    impl CounterImpl of super::ICounter<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }

        fn increase_counter(ref self: ContractState) {
            let current_counter = self.counter.read();
            let new_counter = current_counter + 1;
            self.counter.write(new_counter);
            self.emit(CounterIncreased { counter: new_counter });
        }
        fn decrease_counter(ref self: ContractState) {
            let current_counter = self.counter.read();
            let new_counter = current_counter - 1;
            assert(new_counter > 0, 'Counter cannot be negative');
            self.counter.write(new_counter);
            self.emit(CounterDecreased { counter: new_counter });
        }

        fn reset_counter(ref self: ContractState) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert(caller == owner, 'Not the owner');
            self.counter.write(0);
            self.emit(CounterReset { counter: 0 });
        }
    }
}
