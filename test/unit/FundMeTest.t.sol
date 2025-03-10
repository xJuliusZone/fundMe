// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {FundMe} from "../../src/FundMe.sol";
import {Test, console} from "forge-std/Test.sol";

// call the deploy contract cause , everytime it changes we have to change the test
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
//*what can we do to work with addresses outside our system?
//*1. Unit : Testing a specific part of our code, like these ones
//*2. Integration: Testing how our code works with other parts of our code
//*3. Forked: Testing our code on a simulated real environment
//*4. Staging: Testing our code in a real environment that is not production

contract FudMeTest is Test {
    // we call it here cause we need it to use it in the functions
    // this is the scope
    FundMe fundMe;
    //create a random user
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    // give a balance
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        //* deploys a new contract and use the run function to deploy the contract
        DeployFundMe deployFundMe = new DeployFundMe();
        // now the we use run function that deploys in script, so we can test our contract that deploys
        fundMe = deployFundMe.run();
        // give balance to our user with vm.deal
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        // to check if that's equal, 'cause we're testing the code, if it's not equal will fail: 6e19
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        //*so msg.sender(us) calling FundMeTest, and FundMeTeste deploys FundMe, not us
        console.log(fundMe.getOwner()); // this contract is the owner, not us
        console.log(msg.sender); // this is us(deployer of FundMe contract, not this contract)
        console.log(address(this)); // this is the address of the contract

        assertEq(fundMe.getOwner(), msg.sender);
    }

    //* now when i do forge test (getVersion) pass cause now the contract is deployed and exists in anvil(MockV3),before we had to forge test to sepolia, right now we can do it locally

    //* to know if you getConversionRate is working we need to test first the version
    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithouthEnoughEth() public {
        vm.expectRevert(); // next line should revert
        //* so i need to make sure that the next line fails, to expectRevert pass the text
        fundMe.fund(); // we didn't send any eth, so it fails, and the test pass
            //* fundMe.fund{value: 1211111111111111113}(); // this line doesn't fail cause , i'm sending more than 5 usdc of eth, and will fail the test
    }

    function testFundUpdatesFundedDataStructures() public {
        //* USER IS THE ONE THAT'S CLICK LIKE ME GOING TO LFJ, EVERYTIME I SWAP THAT GETS THE MSG.SENDER
        vm.prank(USER); // the next tx will be sent by USER
            // 10 eth > 5 usdc

        console.log("User balance before funding:", USER.balance); // Log before
        //*THE USER SENDING VALUE LIKE ME SENDING AVAX TO A FUNDME CONTRACT
        fundMe.fund{value: SEND_VALUE}();
        console.log("User balance after funding:", USER.balance); // Log after
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
        console.log("User balance after funding :", fundMe.getAddressToAmountFunded(USER));
    }

    //* test made by me

    function testSendValue() public pure {
        assertEq(0.1 ether, SEND_VALUE);
        assertEq(10 ether, STARTING_BALANCE);
        console.log("Checking Starting Balance: ", STARTING_BALANCE);
    }
    //* USER IS THE ONE THAT'S CLICK LIKE ME GOING TO LFJ, EVERYTIME I SWAP THAT GETS THE MSG.SENDER

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}(); //*THE USER SENDING VALUE LIKE ME SENDING AVAX TO A FUNDME CONTRACT
        //index 0
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }
    //* using state tree, to unit tests, check this out better
    //* so instead of writing everytime vm.prank and fundMe.fund, we use this modifier

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }
    //* i will not use here cause the comments i made in withdraw are really good.

    function testOnlyOwnerCanWithdraw() public {
        vm.prank(USER); // a random user that sees a fundme contract
        fundMe.fund{value: SEND_VALUE}(); //user decides to fund
        vm.expectRevert(); // ignores the vm cheatcodes and reverts the next line
        vm.prank(USER); // here's the user
        fundMe.withdraw(); // that wants to know if he can withdraw
            //* so the test pass cause USER is not the owner, nice
    }

    function testWithdrawWithASingleFunder() public funded {
        //* they USER already funded the contract, don't forget the modifier
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance; //owner address balance
        uint256 startingFundMeBalance = address(fundMe).balance; // balance of the contract fundMe that user funded
        //*just checking how much gas was used to withdraw
        //act , gasleft built-in function
        uint256 gasStart = gasleft(); //how much gas is left in our tx call,like the gas limit:1000
        console.log("gas limit:", gasStart);
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); // the next tx will be done by : 200
        fundMe.withdraw(); //owner withdrew the funds
        uint256 gasEnd = gasleft(); // 800
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // gasprice built-in function
        console.log("Gas used:", gasUsed);

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance; // owner balance after the withdrawal
        uint256 endingFundMeBalance = address(fundMe).balance; // contract balance after the owner withdrew all the funds
        assertEq(endingFundMeBalance, 0); // check if the contract balance = 0
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance); // contract balance that user funded + owner balance = after the owner withdrew all the funds
        console.log("owner balance after the withdrawal", endingOwnerBalance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        //* we're generating a address so will have to use 160, cause have the same bytes of a address, so we have to use it in all of the uint, cause if i don't use it will pull up and error, explicit conversion not allowed from "uint256" to "address"
        uint160 numberOfFunder = 10; // we'll generate 10 addresses
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunder; i++) {
            //hoax sets up an prank  with some ether(prank + deal)
            // generating address = address(0), address(1)etc
            // vm.prank(address(i));
            // vm.deal(address(i), SEND_VALUE);
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}(); // using the 10 wallets to fund the contract
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank(); //assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        //* we're generating a address so will have to use 160, cause have the same bytes of a address, so we have to use it in all of the uint, cause if i don't use it will pull up and error, explicit conversion not allowed from "uint256" to "address"
        uint160 numberOfFunder = 10; // we'll generate 10 addresses
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunder; i++) {
            //hoax sets up an prank  with some ether(prank + deal)
            // generating address = address(0), address(1)etc
            // vm.prank(address(i));
            // vm.deal(address(i), SEND_VALUE);
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}(); // using the 10 wallets to fund the contract
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank(); //assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}
