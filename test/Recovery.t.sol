// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Recovery.sol";
import "src/levels/RecoveryFactory.sol";

contract TestRecovery is BaseTest {
    Recovery private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new RecoveryFactory();
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
        level = Recovery(levelAddress);

        // Check that the contract is correctly setup
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        // We need to find a way to get the address of the `SimpleToken` contract created by the `Recovery` contract
        // in order to call `destroy` on it and withdraw all the funds
        // I started thinking that some viable solutions would have been
        // 1) Use etherscan: look at the RecoveryFactory contract on etherscan, see the transaction that would have created `Recovery` and
        // follow the rabbit hole to get the `SimpleToken` contract address. Then just hardcode the address and call it a day
        // 2) Use ethersjs: look at the events/logs of the factory contracts via etherjs and find the transaction that have called `generateToken` and
        // created the `SimpleToken` and then hardcode it in the solution
        // Both these solution cannot be automated via foundry
        // I know that CREATE2 opcode allow you to create a new contract with a deterministic address
        // I never thought that also CREATE must have in someway a logic to generate the address of a new contract and not just call "randomAddressNotUsed"!
        // Following the suggestion found on cmichiel solution of the challenge https://cmichel.io/ethernaut-solutions/ (I swear, just wanted to check if there was a way
        // to do it manually, didn't read the full solution :D) I started researching how the CREATE opcode work in the Ethereum Yellowpaper that says
        // "The address of the new account is defined as being the rightmost 160 bits of the Keccak-256 hash of the RLP encoding of the structure containing only the sender and
        // the account nonce. For CREATE2 the rule is different and is described in EIP-1014 by Buterin [2018]. [...]"
        // More info ->
        // - https://ethereum.github.io/yellowpaper/paper.pdf
        // - https://docs.openzeppelin.com/cli/2.8/deploying-with-create2#create
        // So the way to re-build the address of a created contract is to get the rightmost 160 bits of the keccak-256 hash of the RLP encoding of sender + sender's nonce
        // More info on RPL encoding ->
        // - https://ethereum.org/en/developers/docs/data-structures-and-encoding/rlp/
        // In our case:
        // the sender is the `Receover` contract itself
        // The nonce of an EOA is the number of tx it have made
        // The nonce of a contract is the number of contract's it has created. An important thing to remember: contract's nonce starts from 1 and not 0!
        // See more here -> https://github.com/ethereum/EIPs/blob/master/EIPS/eip-161.md#specification
        // Well, to get a Solidity implementation of the RLP encoding I just google it and found an example on stack overflow
        // https://ethereum.stackexchange.com/a/761

        vm.startPrank(player, player);

        address payable lostContract = address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), address(level), bytes1(0x01)))))
        );

        uint256 contractBalanceBefore = lostContract.balance;
        assertEq(contractBalanceBefore, 0.001 ether);

        uint256 playerBalanceBefore = player.balance;
        SimpleToken(lostContract).destroy(player);

        vm.stopPrank();

        assertEq(lostContract.balance, 0);
        assertEq(player.balance, playerBalanceBefore + contractBalanceBefore);
    }
}
