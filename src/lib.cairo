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

mod SimpleStorage;
mod erc20; 

// TODO : 
// 1. Creation of 1 token that will be used to swap on the DCA contract 
// 2. Implement the swap in the DCA function 
// 3. Implement the DCA function

// ANCHOR: DCA
#[starknet::contract]
mod DCA{



}
// ANCHOR_END: DCA