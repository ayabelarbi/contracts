//ANCHOR: all
use starknet::ContractAddress;

#[starknet::interface]
pub trait INameRegistry<TContractState> {
    fn store_name(
        ref self: TContractState, name: felt252, registration_type: NameRegistry::RegistrationType
    );
    fn get_name(self: @TContractState, address: ContractAddress) -> felt252;
    fn get_owner(self: @TContractState) -> NameRegistry::Person;
}

#[starknet::contract]
mod NameRegistry {
    use starknet::{ContractAddress, get_caller_address, storage_access::StorageBaseAddress};

    #[storage]
    struct Storage {
        names: LegacyMap::<ContractAddress, felt252>,
        registration_type: LegacyMap::<ContractAddress, RegistrationType>,
        total_names: u128,
        owner: Person
    }
  
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StoredName: StoredName,
    }

    #[derive(Drop, starknet::Event)]
    struct StoredName {
        #[key]
        user: ContractAddress,
        name: felt252
    }


    #[derive(Drop, Serde, starknet::Store)]
    pub struct Person {
        name: felt252,
        address: ContractAddress
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub enum RegistrationType {
        finite: u64,
        infinite
    }


    #[constructor]
    fn constructor(ref self: ContractState, owner: Person) {
        self.names.write(owner.address, owner.name);
        self.total_names.write(1);
        self.owner.write(owner);

    }


    #[abi(embed_v0)]
    impl NameRegistry of super::INameRegistry<ContractState> {
        fn store_name(ref self: ContractState, name: felt252, registration_type: RegistrationType) {
            let caller = get_caller_address();
            self._store_name(caller, name, registration_type);
        }

        fn get_name(self: @ContractState, address: ContractAddress) -> felt252 {
            let name = self.names.read(address);
            name
        }

        fn get_owner(self: @ContractState) -> Person {
            let owner = self.owner.read();
            owner
        }
    }

   

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _store_name(
            ref self: ContractState,
            user: ContractAddress,
            name: felt252,
            registration_type: RegistrationType
        ) {
            let mut total_names = self.total_names.read();
            self.names.write(user, name);
            self.registration_type.write(user, registration_type);
            self.total_names.write(total_names + 1);
            self.emit(StoredName { user: user, name: name });
        }
    }

    fn get_contract_name() -> felt252 {
        'Name Registry'
    }

    fn get_owner_storage_address(self: @ContractState) -> StorageBaseAddress {
        self.owner.address()
    }
}

// make the test
#[cfg(test)]
mod tests {
    use snforge_std::{ declare, ContractClassTrait,start_cheat_caller_address };
    use super::NameRegistry::{ContractState, Person, RegistrationType};
    use using_dispatchers::{ INameRegistryDispatcher, INameRegistryDispatcherTrait };

    #[test]
    fn call_and_invoke() {
        let contract = declare("NameRegistry").unwrap();
        let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
        let dispatcher = INameRegistryDispatcher { contract_address };

        let name = dispatcher.get_name();
        assert(name.is_none(), 'Name should be none');
    }

    // #[test]
    // fn test_name_registry() {
    // }
}