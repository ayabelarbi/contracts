use starknet::ContractAddress;


#[starknet::interface]
trait ISwapTokens<TContractState> {
    fn create_swap(ref self: TContractState, swap: Swap, biding: Span<Asset>, asking: Span<Asset>) -> u256;
    fn accept_swap(ref self: TContractState, swap_id: u256) -> bool;
    fn cancel_swap(ref self: TContractState, swap_id: u256);
    fn get_swap(self: @TContractState, swap_id: u256) -> Swap;
    fn get_total_swaps(self: @TContractState) -> u256;
}

#[starknet::interface]
trait ITransfer<TContractState> {
    fn transfer_from(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, amount_or_id: u256
    );
}


#[derive(Copy, Drop, Serde, starknet::Store)]
struct Asset {
    addr: ContractAddress,
    amount_or_id: u256,
}

#[derive(Copy, Drop, Serde, starknet::Store)]
struct Swap {
    owner: ContractAddress,
    allowed: ContractAddress,
    expiry: u64,
    biding_count: u32,
    asking_count: u32,
}

#[starknet::contract]
mod SwapTokens {
    use super::{Asset, Swap};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    // use swaptokens::interfaces::{
    //     ISwapTokens::ISwapTokens, ITransfer::{ITransferDispatcher, ITransferDispatcherTrait},
    // };
    use super::{ISwapTokens, ITransferDispatcher, ITransferDispatcherTrait};
    use core::starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StorageMapReadAccess,
        StorageMapWriteAccess, Map
    };

    #[storage]
    struct Storage {
        total_swaps: u256,
        swaps: Map<u256, Swap>,
        swaps_biding: Map<(u256, u32), Asset>,
        swaps_asking: Map<(u256, u32), Asset>,
    }

    //Event of Swap
    #[event]
    #[derive(Copy, Drop, starknet::Event, PartialEq)]
    enum Event {
        SwapCreated: SwapCreated,
        SwapAccepted: SwapAccepted,
        SwapCanceled: SwapCanceled,
    }

    // Emitted when a new Swap is created.
    #[derive(Copy, Drop, starknet::Event, PartialEq)]
    struct SwapCreated {
        #[key]
        user: ContractAddress,
        #[key]
        swap_id: u256,
        allowed: ContractAddress,
        expiry: u64,
    }

    // Emitted when a Swap is accepted.
    #[derive(Copy, Drop, starknet::Event, PartialEq)]
    struct SwapAccepted {
        #[key]
        user: ContractAddress,
        #[key]
        swap_id: u256,
    }

    // Emitted when a Swap is canceled.
    #[derive(Copy, Drop, starknet::Event, PartialEq)]
    struct SwapCanceled {
        #[key]
        user: ContractAddress,
        #[key]
        swap_id: u256,
    }

    // Errors of Swap
    mod Errors {
        const INVALID_ADDRESS: felt252 = 'SwapTokens: Invalid address';
        const INVALID_EXPIRY: felt252 = 'SwapTokens: Invalid expiry time';
        const INVALID_ASSETS_LENGTH: felt252 = 'Swap: Invalid assets length';
    }

    #[abi(embed_v0)]
    impl ISwapTokensImpl of ISwapTokens<ContractState> {
        fn create_swap(
            ref self: ContractState, swap: Swap, mut biding: Span<Asset>, mut asking: Span<Asset>
        ) -> u256 {
            assert(swap.owner == get_caller_address(), Errors::INVALID_ADDRESS);
            assert(swap.expiry >= get_block_timestamp(), Errors::INVALID_EXPIRY);
            assert(biding.len() > 0 && asking.len() > 0, Errors::INVALID_ASSETS_LENGTH);
            assert(
                biding.len() == swap.biding_count && asking.len() == swap.asking_count,
                Errors::INVALID_ASSETS_LENGTH
            );

            let swap_id = self.total_swaps.read() + 1;
            self.total_swaps.write(swap_id);

            self.swaps.write(swap_id, swap);

            let mut i = 0;
            loop {
                if i == swap.biding_count {
                    break;
                }
                self.swaps_biding.write((swap_id, i), *biding.at(i));
                i += 1;
            };

            i = 0;
            loop {
                if i == swap.asking_count {
                    break;
                }
                self.swaps_asking.write((swap_id, i), *asking.at(i));
                i += 1;
            };

            self
                .emit(
                    SwapCreated {
                        user: get_caller_address(),
                        swap_id,
                        allowed: swap.allowed,
                        expiry: swap.expiry
                    }
                );

            swap_id
        }

        fn accept_swap(ref self: ContractState, swap_id: u256) -> bool {
            let mut swap = self.swaps.read(swap_id);

            assert(
                !(swap.allowed.is_non_zero() && swap.allowed != get_caller_address()),
                Errors::INVALID_ADDRESS
            );
            assert(swap.expiry >= get_block_timestamp(), Errors::INVALID_EXPIRY);

            swap.expiry = 0;
            self.swaps.write(swap_id, swap);

            let mut i = 0;
            loop {
                if i == swap.asking_count {
                    break;
                }
                let asset = self.swaps_asking.read((swap_id, i));
                ITransferDispatcher { contract_address: asset.addr }
                    .transfer_from(get_caller_address(), swap.owner, asset.amount_or_id);
                i += 1;
            };

            let mut i = 0;
            loop {
                if i == swap.biding_count {
                    break;
                }
                let asset = self.swaps_biding.read((swap_id, i));
                ITransferDispatcher { contract_address: asset.addr }
                    .transfer_from(swap.owner, get_caller_address(), asset.amount_or_id);
                i += 1;
            };

            self.emit(SwapAccepted { user: get_caller_address(), swap_id });
            true
        }

        fn cancel_swap(ref self: ContractState, swap_id: u256) {
            let mut swap = self.swaps.read(swap_id);

            assert(swap.owner == get_caller_address(), Errors::INVALID_ADDRESS);
            assert(swap.expiry >= get_block_timestamp(), Errors::INVALID_EXPIRY);

            swap.expiry = 0;
            self.swaps.write(swap_id, swap);
            self.emit(SwapCanceled { user: get_caller_address(), swap_id });
        }

        fn get_swap(self: @ContractState, swap_id: u256) -> Swap {
            self.swaps.read(swap_id)
        }

        fn get_total_swaps(self: @ContractState) -> u256 {
            self.total_swaps.read()
        }
    }
}