#[starknet::interface]
trait ISimpleStorageBatch<TContractState> {
    fn addBatch(ref self: TContractState, batchId: u128, batchLength: u128, lenList: u128);
    fn executeSomething(ref self: TContractState, batchId: u128);
    fn getCurrentBatch(self: @TContractState) -> (felt252, felt252, u64);
}


#[starknet::contract]
mod SimpleStorageBatch {
    use starknet::{ContractAddress};
    use core::starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StorageMapReadAccess,
        StorageMapWriteAccess, StoragePointerWriteAccess
    };
    use starknet::get_block_timestamp;
    use core::starknet::storage_access::StorageBaseAddress; 

    mod Errors {
        pub const BATCH_NOT_STARTED: felt252 = 'batch havent started yet';
    
    }
    #[storage]
    struct Storage {
        batch: Map::<felt252, Map::<felt252, felt252>>,
        batchLengths: felt252,
        currentIndex: felt252, 
        lastProcessedTime: u64,
        interval: u64,
        i : felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.batch.write(0,0,0);
        self.batchLengths.write(1); 
        self.currentIndex.write(0);
        self.lastProcessedTime.write(get_block_timestamp());
        self.interval.write(180);
        self.i.write(0); 
    }

    #[abi(embed_v0)]
    impl SimpleStorageBatch of super::ISimpleStorageBatch<ContractState>{
        //simple function to add batch, and init every memory place to 0
        fn addBatch(
            ref self: ContractState,
            batchId: u128,
            batchLength: u128,
            lenList: u128,
        ){
            let timeStamp = get_block_timestamp();
          
            for index in lenList{
                self.batch.write(batchId, index, i);
            };
            self.lastProcessedTime.write(timeStamp); 
        }
    
        fn executeSomething(
            ref self: ContractState,
            batchId: u128,
        ){
            let time_reminded: u64 = self.lastProcessedTime.read() + self.interval.read();
            assert(get_block_timestamp() < time_reminded, Errors::BATCH_NOT_STARTED);

            let batch_map = self.batch.read(batchId);
            let mut i_ref = self.i.read();

            for (index, value) in batch_map.iter() {
                i_ref += 1; 
                // Placeholder for waiting 3 minutes (not feasible in smart contracts)
                // In actual implementation, this would be handled by external calls or events
            
            }; 

            self.i.write(i_ref); // Write back the updated value
            self.lastProcessedTime.write(get_block_timestamp());

        }

        fn getCurrentBatch(self: @ContractState) -> (felt252, felt252, u64){
            let batchLength = self.batchLengths.read();
            let currentIndex = self.currentIndex.read();
            let lastProcessedTime = self.lastProcessedTime.read();
            (batchLength, currentIndex, lastProcessedTime)
        }
    }

}
