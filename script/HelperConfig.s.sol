// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

// 1. Defploy mocks when we are on a local anvil chain
// 2. Keep track of contract address across different chains: sepolia ETH/USD, Mainnet ETH/USD
import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;
    //If we are on a local anvil, we deploy mocks
    //Otherwise, grab the existing addres from the live network(sepolia,mainnet)

    uint8 public constant DECIMALS = 8;
    int256 public constant INTIAL_PRICE = 2000e8;

    // we create this struct (custom type), cause we might need gas, address and more
    //right now only gas
    struct NetworkConfig {
        address priceFeed;
    }

    constructor() {
        // sepolia chain id
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        //price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});

        //* can also do this but patrick want it explicit
        // NetworkConfig memory sepoliaConfig = NetworkConfig(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethConfig = NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        return ethConfig;
    }

    //* now when i do forge test (getVersion) pass cause now the contract exist in anvil(MockV3),before we have to forge test to sepolia, right now we can do it locally
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        //* the first time it deploys will have an address(0x23423423w), the second time we check with the (if), address(0) default address of deploy
        //*(if) checks is the mockPriceFeed was deployed and if it was won't redeploy the contract, if it doesn't , it will deploy the contract, so if it was deploy will only reuses it and return it, if it wasn't, it will do vm.start etc.
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig; // if there's a contract will return activeNetwork that has this whole function
        }
        //1. Deploy the mocks
        //2. Return the mock address
        vm.startBroadcast();
        // takes two paremeters in the constructor, decimales in terms of eth/usd, eth/usd price
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INTIAL_PRICE);
        vm.stopBroadcast();
        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        return anvilConfig;
    }

    function testFundFailsWithoutEnoughEth() public {}
}
