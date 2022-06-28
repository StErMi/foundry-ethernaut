// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Privacy.sol";
import "src/levels/PrivacyFactory.sol";

contract TestPrivacy is BaseTest {
    Privacy private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new PrivacyFactory();
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
        level = Privacy(levelAddress);

        // Check that the contract is correctly setup
        assertEq(level.locked(), true);
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        // Remember when we said in the `Vault` challenge that nothing is private in the blockchain?
        // Well I reall meant it!
        // If we look at the `Privacy` contract we can see that to solve this challenge we need to read from the
        // `data` state variable, take the item from the index 2 of the bytes32 array and cast them down to bytes16

        // This challenge involves a lot of knowledge
        // First of all you need to understand how the layout of state variables in storage works
        // You can read more here: https://docs.soliditylang.org/en/v0.8.15/internals/layout_in_storage.html#layout-of-state-variables-in-storage
        // But basically you need to remember a couple of things:
        // 1) "slots" in storage are 256bits (32byte) words
        // 2) variables that fits in less than that will be packed together. This is has advantages but also disadvantages
        // 3) dynamic arrays and mapping have a "special" rule to calculate were their values are stored (see the docs)

        // In our case `data` is a fixed size arrays
        // The storage of Privacy contract is like this
        // slot0 -> `locked` variable. Even if a boolean does not take 32bytes it cannot be packed with uint256 that take a whole word
        // slot1 -> `ID` because it's a uint256 that use 32bytes
        // slot2 -> `flattening` + `denomination` + `awkwardness` can be packed together because they take less than 32bytes
        // Each element of our array will take 1 entire slot so:
        // slot3 -> `data[0]`
        // slot4 -> `data[1]`
        // slot5 -> `data[2]`

        // what we need to do is to read slot5 value that store the value for `data[2]`
        // cast it to bytes16
        // and use it to unlock the `Privacy` smart contract!

        bytes32 data = vm.load(address(level), bytes32(uint256(5)));
        level.unlock(bytes16(data));

        assertEq(level.locked(), false);

        vm.stopPrank();
    }
}
