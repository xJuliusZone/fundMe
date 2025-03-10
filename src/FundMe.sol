// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe_NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;
    address[] private s_funders;
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;

    address private immutable i_owner;
    //address of the chain we wanna pass
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        // custom type functions allowed with library// chatgpt
        //so ethAmount is msg.value
        // msg.value.getConversionRate();
        //with library
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "didn't send enough ETH");
        //(18) decimals 2000.(18)
        // without library and the the priceConverter here
        // require(getConversionRate(msg.value) >= minimumUsd, "didn't send enough ETH");
        // when someone clicks fund , msg.sender gets their wallet
        s_funders.push(msg.sender);
        // s_addressToAmountFunded[msg.sender] = s_addressToAmountFunded[msg.sender] +msg.value;
        //shortcut
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function cheaperWithdraw() public {
        // here we read teh lengt from memory not storage, that's the big difference with the withdraw function,
        uint256 fundersLength = s_funders.length;
        for (uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            /*  */
            address funder = s_funders[funderIndex];
            // reset the mapping of s_funders , 'cause we withdrew the funds, so reset to 0
            s_addressToAmountFunded[funder] = 0;
        }
        //reset the array, we just create a new blank array
        s_funders = new address[](0);
        // three ways to send eth

        //transfer ,2300 gas capped, throws and error, and revert
        //   the one who can withdraw ,contract balance
        // payable(msg.sender).transfer(address(this).balance);

        //send, 2300 gas capped, returns a bool, and will revert if we add require
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        //call forward all gas , so it's not capped, return bool
        //, call returns two parameters(bool callSuccess, bytes memory dataReturned),
        //in this example we don't need bytes
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe_NotOwner();
        }
        _;
    }

    // with this function, if someone send us money, this function will acept it if the don't call the fund function
    receive() external payable {
        fund();
    }
    /**
     * View / Pure functions (Getters)
     */

    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
