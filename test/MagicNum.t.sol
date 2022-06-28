// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/MagicNum.sol";
import "src/levels/MagicNumFactory.sol";

contract TestMagicNum is BaseTest {
    MagicNum private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new MagicNumFactory();
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
        level = MagicNum(levelAddress);

        // Check that the contract is correctly setup
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        // This is a tricky one, I don't know if this is the best solution
        // but after deep diving into EVM with EVM Puzzle challenges
        // it was just natural for me to solve it with this approach

        // To solve this challenge we need to deploy a smart contract that
        // 1) Answer 0x2a (42 in decimal) when `whatIsTheMeaningOfLife()` is called
        // 2) Its code must be less or equal than 10 bytes (so less than 10 instructions)

        // One really useful resource for me is https://www.evm.codes/ where yoy can find
        // All the EVM Opcodes info and a Playground to test your EVM bytecode

        // Step 1: create a minimal smart contract that only return 0x2a
        // You can call this smart contract with whatever function you want
        // but the only thing it will do is to always answer 0x2a (in 32 bytes format)

        // ---- EVM to make the contract return 0x2a
        // PUSH1 0x2a
        // PUSH1 00
        // MSTORE
        // PUSH1 0x20
        // PUSH1 00
        // RETURN
        // bytecode -> 0x602A60005260206000F3

        // Step2: create the bytecode that will deploy the minimal bytecode of the smart contract
        // When a smart contract is created, the EVM will execute the constructor code once
        // And the code of the deployed smart contract is the one returned by the `RETURN` opcode
        // In this case we are just pushing the smartcontract bytecode into memory
        // And returning it

        // --- EVM to create a contract with the above code

        // PUSH10 602A60005260206000F3 (runtime code)
        // PUSH1 0
        // MSTORE
        // PUSH1 0A
        // PUSH1 0x16
        // RETURN
        // bytecode -> 0x69602A60005260206000F3600052600A6016F3

        // Step3: deploy the bytecode that will create the smart contract
        // This code is inspired by the OpenZeppelin Clones utils
        // that is implementing the EIP 1167 that is a standard for deploying
        // minimal bytecode implementation
        // More info ->
        // - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Clones.sol
        // - https://eips.ethereum.org/EIPS/eip-1167

        address solverInstance;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, shl(0x68, 0x69602A60005260206000F3600052600A6016F3))
            solverInstance := create(0, ptr, 0x13)
        }

        level.setSolver(solverInstance);

        assertEq(
            Solver(solverInstance).whatIsTheMeaningOfLife(),
            0x000000000000000000000000000000000000000000000000000000000000002a
        );

        vm.stopPrank();
    }
}
