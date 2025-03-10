-include .env

build:; forge build
deploy-sepolia:;forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(SEPOLIA_URL) --account tesnet --sender 0x4c1FF48aD9a7500dccF9Ff5F0F7C7a0eb359B446 --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

fund:; forge script script/Interactions.s.sol:FundFundMe --rpc-url $(SEPOLIA_URL) --account tesnet --sender 0x4c1FF48aD9a7500dccF9Ff5F0F7C7a0eb359B446 --broadcast
withdraw:; forge script script/Interactions.s.sol:WithdrawFundMe --rpc-url $(SEPOLIA_URL) --account tesnet --sender 0x4c1FF48aD9a7500dccF9Ff5F0F7C7a0eb359B446 --broadcast