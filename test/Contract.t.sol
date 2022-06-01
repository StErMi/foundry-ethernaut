// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./utils/BaseTest.sol";

import "src/Contract.sol";

contract TestContract is BaseTest {
    Contract private c;

    constructor() {
        // Created (during `setUp()`) users will be available in `users` state variable

        // Setup test to create 2 test user with 100 ether in balance each
        // preSetUp(2);

        // Setup test to create 2 test user with 1 ether in balance each
        // preSetUp(2, 1 ether);

        // Setup test to create 2 test user with 1 ether in balance each and label them accordingly
        string[] memory userLabels = new string[](2);
        userLabels[0] = "Alice";
        userLabels[1] = "Bob";
        preSetUp(2, 100 ether, userLabels);
    }

    function setUp() public override {
        // Call the BaseTest setUp() function that will also create testsing accounts
        super.setUp();

        c = new Contract();
    }

    function testSetUp() public {
        assertEq(users.length, 2);
        assertEq(users[0].balance, 100 ether);
    }

    function testBar() public {
        assertEq(uint256(1), uint256(1), "ok");
    }

    function testFoo(uint256 x) public {
        vm.assume(x < type(uint128).max);
        assertEq(x + x, x * 2);
    }
}
