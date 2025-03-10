// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        //* if you don't understand you paste the whole codebase to chatgpt, with test, src, etc
        // deploys a new contract, so we don't spend gas trying to deploy this
        HelperConfig helperConfig = new HelperConfig();
        // call the activeNetwrok to fetch/traer/buscar the correct price data
        (address ethUsdPriceFeed) = helperConfig.activeNetworkConfig();
        //* anything before vm , is not a tx, so doesn't deploy, it simulates in a simulator environment
        //* in vm will be a real tx,
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        // use the return cause know we returning this to test
        return fundMe;
    }
}
