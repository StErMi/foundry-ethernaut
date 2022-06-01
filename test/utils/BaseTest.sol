// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "./Utilities.sol";

abstract contract BaseTest is Test {
    Utilities internal utilities;
    address payable[] internal users;
    uint256 private userCount;
    uint256 private userInitialFunds = 100 ether;
    string[] private userLabels;

    function preSetUp(
        uint256 _userCount,
        uint256 _userInitialFunds,
        string[] memory _userLabels
    ) public {
        userCount = _userCount;
        userInitialFunds = _userInitialFunds;
        userLabels = _userLabels;
    }

    function preSetUp(uint256 userNum, uint256 initialFunds) public {
        string[] memory a;
        preSetUp(userNum, initialFunds, a);
    }

    function preSetUp(uint256 userNum) public {
        preSetUp(userNum, 100 ether);
    }

    function setUp() public virtual {
        utilities = new Utilities();

        console.log("userCount", userCount);

        if (userCount > 0) {
            console.log("running utilities.createUsers");
            // check which one we need to call
            users = utilities.createUsers(userCount, userInitialFunds, userLabels);
        }
    }
}
