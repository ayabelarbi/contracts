## Deployed contract adress : 
TT Token - Test Token | 0x01633a1aeda4419d5d0cec94531305845c2b3d537ddd0815a97373201fdc9590
MTDCA - My Token DCA | 0x05801d18e7386b0f7499b692bca8115f10c0f135a6f32d1a96049d94165dddab

## To run the smart contract 

# 1. Make sure to have deployed you're smart wallet, if not here's how to do it 
[How to Deploy on Starknet](https://starknet-by-example.voyager.online/getting-started/interacting/how_to_deploy.html)

# 2. Make sure to have the correct version of scarb and all 
[version of scarb](https://docs.openzeppelin.com/contracts-cairo/0.15.1/)

# 3. compiling error and personnal troubleshooting 
If you have this kind of error : 
`Error: Cannot compile Sierra version 1.6.0 with the current compiler (sierra version: 1.5.0)`

Make sure to `starkli up`before declaring your contract 

# 4. Declaring and Deploying contract 
example of declaration : 
`declare contracts  
 starkli declare target/dev/starknet_integration_contracts_MyTokenDCA.contract_class.json --account  ~/.starkli-wallets/deployer/my_account_1.json --keystore ~/.starkli-wallets/deployer/my_keystore_1.json  --network sepolia --watch`

example of deployment: 
starkli deploy 0x050d022ec57e0bbca90e52b16afb3f73e5e01a13840a36ef0c8fbde5041b893d --account  ~/.starkli-wallets/deployer/my_account_1.json --keystore ~/.starkli-wallets/deployer/my_keystore_1.json --network sepolia --watch 0x03fd6505dbfa1602191b4599dd474054c0cc169fbfe7b502681be10f52e4c8a7

beware: the account and keystore names depends on how you locally deployed your smart wallet localy  ! 

starkli deploy <THE CLASS CONTRACT> account  ~/.starkli-wallets/deployer/my_account_1.json --keystore ~/.starkli-wallets/deployer/my_keystore_1.json network sepolia --watch <Your wallet>
