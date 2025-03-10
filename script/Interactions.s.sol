// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//*fund script
//*withdraw script

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether;
    // this is what we do to fund

    function fundFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        console.log("Funded FundMe with :", SEND_VALUE);
        vm.stopBroadcast();
    }

    function run() external {
        // we want to fund the lastest deployed contract
        // so we're gonna use a foundry-devops tools of patrick
        // so this looks the brodcast folder and then goes to run-latest.json and grabs the most recently deployed contract
        address mostRecentDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);

        fundFundMe(mostRecentDeployed);
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();

        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
    }

    function run() external {
        // we want to fund the lastest deployed contract
        // so we're gonna use a foundry-devops tools of patrick
        // so this looks the brodcast folder and then goes to run-latest.json and grabs the most recently deployed contract
        address mostRecentDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);

        withdrawFundMe(mostRecentDeployed);
    }
}
