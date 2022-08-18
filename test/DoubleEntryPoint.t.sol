// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/DoubleEntryPoint.sol";
import "src/levels/DoubleEntryPointFactory.sol";

contract TestDoubleEntryPoint is BaseTest {
    DoubleEntryPoint private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new DoubleEntryPointFactory();
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
        level = DoubleEntryPoint(levelAddress);

        // Check that the contract is correctly setup
    }

    function exploitLevel() internal override {
        /** CODE YOUR EXPLOIT HERE */

        vm.startPrank(player, player);

        // In this challenge you have two tokens
        // DoubleEntryPoint token and LegacyToken
        // As far as I get from the description (that tbh is not very clear) the LegacyToken has been discontinued
        // Via `DoubleEntryPoint.delegateTransfer` user that still own some `LegacyToken` can still use them as if they were `DoubleEntryPoint`
        // When you transfer 1 `LegacyToken`, the contract will call `DoubleEntryPoint.delegateTransfer`
        // In practice, transferring 1 legacy token would in reality transfer 1 DoubleEntryPoint
        // We now have CryptoVault that is a vault with an underlying that cannot be swept by `sweepToken` function
        // It's not important in this context to know why. We only know that DoubleEntryPoint held by the contract cannot be transferred by the `sweepToken`
        // Our goal is to find the issue on `CryptoVault` and understand how to use `Forta` to report the problem

        // Step1: identify the issue in `CryptoVault`
        // if you look at `sweepToken` you see that there's a check that will make the tx revert
        // if `token == underlying`, in this case if `token != DoubleEntryPoint`
        // The problem in this case is that the vault holds also `LegacyToken` that can be swept because the check will pass
        // When you will sweep LegacyToken tokens they will transfer DoubleEntryPoint tokens because of `delegateTransfer`
        // So we need to prevent anyone to also sweep `LegacyToken` tokens

        // To do so we create a `DetectionBot` will implement the `handleTransaction`
        // `handleTransaction` has 2 parameters:
        // - `address user`
        // - `bytes msgData` that is the calldata payload
        // What we need to do is to call `IForta(msg.sender).raiseAlert(user)` if both conditions are true
        // - the signature of the calling function (first 4 bytes of the `calldata`) is equal to `delegateTransfer`
        // - the original sender (who is calling `DoubleEntryPoint.delegateTransfer`) is `CryptoVault`

        // Onother problem that I see (but this is outside of the challenge)
        // Is that when the Legacy token is transferred via `delegateTransfer` the balance of the owner remain the same
        // The `LegacyToken` should be burned prior collaing `delegateTransfer`

        DetectionBot bot = new DetectionBot(
            level.cryptoVault(),
            abi.encodeWithSignature("delegateTransfer(address,uint256,address)")
        );
        level.forta().setDetectionBot(address(bot));

        vm.stopPrank();
    }
}

contract DetectionBot is IDetectionBot {
    address private monitoredSource;
    bytes private monitoredSig;

    constructor(address _monitoredSource, bytes memory _monitoredSig) public {
        monitoredSource = _monitoredSource;
        monitoredSig = _monitoredSig;
    }

    function handleTransaction(address user, bytes calldata msgData) external override {
        (address to, uint256 value, address origSender) = abi.decode(msgData[4:], (address, uint256, address));

        bytes memory callSig = abi.encodePacked(msgData[0], msgData[1], msgData[2], msgData[3]);

        if (origSender == monitoredSource && keccak256(callSig) == keccak256(monitoredSig)) {
            IForta(msg.sender).raiseAlert(user);
        }
    }
}
