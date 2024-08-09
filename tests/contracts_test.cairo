// make the test
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
