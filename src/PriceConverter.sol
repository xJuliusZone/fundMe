// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // 0x694AA1769357215DE4FAC081bf1f309aDC325306 eth/usd
        // ABI we only need the functions to interact, that's why we use the interface(aggregator)
        (, int256 answer,,,) = priceFeed.latestRoundData();
        // price of ETH in terms of USD
        //2000.00000000(8)
        // to match up
        return uint256(answer * 1e10);
    }

    // we convert it to usd
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        // 1eth?
        // 2000_1e18
        uint256 ethPrice = getPrice(priceFeed);
        //this has 1e18 = (1e18*1e18) / 1e18 = 1e18, cause we need to match to msg.value
        //                      (2000_1e18* 1eth_1e18)/ 1e18 = $2000.1e18 = 1eth,
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    function getVersion() internal view returns (uint256) {
        return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
    }
}
