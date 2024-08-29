
#[starknet::contract]
mod SimpleStorage {
    use starknet::get_block_timestamp;
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use super::StoreFelt252Array;

    mod Errors {
        pub const WAIT_TIME_NOT_ELAPSED: felt252 = 'Wait time has not elapsed';
    }

    #[storage]
    struct Storage {
        lastExecutedTime: u64,
        interval: u64,
        arr: Array<felt252>
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.lastExecutedTime.write(0);
        self.interval.write(180); // 3 minutes in seconds
    }

    #[abi(embed_v0)]
    impl SimpleStorage of super::ISimpleStorage<ContractState> {
        fn storeArray(
            ref self: ContractState,
            arr: Array<felt252>
        ) {       
            let current_time = get_block_timestamp();
            let last_time = self.lastExecutedTime.read();
            let interval = self.interval.read();

            assert(current_time >= last_time + interval, Errors::WAIT_TIME_NOT_ELAPSED);

            self.arr.write(arr);
            self.lastExecutedTime.write(current_time);
        }

        fn read_array(self: @ContractState) -> Array<felt252> {
            self.arr.read()
        }
    }

}