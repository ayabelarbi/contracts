use starknet::SyscallResultTrait;
use starknet::{Store, SyscallResult};
use starknet::storage_access::StorageBaseAddress;

// ANCHOR: StorageAccessImpl
impl StoreFelt252Array of Store<Array<felt252>> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult<Array<felt252>> {
        Self::read_at_offset(address_domain, base, 0)
    }

    fn write(
        address_domain: u32, base: StorageBaseAddress, value: Array<felt252>
    ) -> SyscallResult<()> {
        Self::write_at_offset(address_domain, base, 0, value)
    }

    fn read_at_offset(
        address_domain: u32, base: StorageBaseAddress, mut offset: u8
    ) -> SyscallResult<Array<felt252>> {
        let mut arr: Array<felt252> = array![];

        // Read the stored array's length. If the length is greater than 255, the read will fail.
        let len: u8 = Store::<u8>::read_at_offset(address_domain, base, offset)
            .expect('Storage Span too large');
        offset += 1;

        // Sequentially read all stored elements and append them to the array.
        let exit = len + offset;
        loop {
            if offset >= exit {
                break;
            }

            let value = Store::<felt252>::read_at_offset(address_domain, base, offset).unwrap();
            arr.append(value);
            offset += Store::<felt252>::size();
        };

        // Return the array.
        Result::Ok(arr)
    }

    fn write_at_offset(
        address_domain: u32, base: StorageBaseAddress, mut offset: u8, mut value: Array<felt252>
    ) -> SyscallResult<()> {
        // Store the length of the array in the first storage slot.
        let len: u8 = value.len().try_into().expect('Storage - Span too large');
        Store::<u8>::write_at_offset(address_domain, base, offset, len).unwrap();
        offset += 1;

        // Store the array elements sequentially
        while let Option::Some(element) = value
            .pop_front() {
                Store::<felt252>::write_at_offset(address_domain, base, offset, element).unwrap();
                offset += Store::<felt252>::size();
            };

        Result::Ok(())
    }

    fn size() -> u8 {
        255 * Store::<felt252>::size()
    }
}
// ANCHOR_END: StorageAccessImpl


#[starknet::interface]
trait ISimpleStorage<TContractState> {
    fn storeArray(ref self: TContractState, arr: Array<felt252>);
    fn read_array(self: @TContractState) -> Array<felt252>;
}

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