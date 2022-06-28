# Ethernaut CTF - Foundry edition

## What is Ethernaut by OpenZeppelin

[Ethernaut](https://github.com/OpenZeppelin/ethernaut) is a Web3/Solidity based war game inspired in [overthewire.org](https://overthewire.org/), to be played in the Ethereum Virtual Machine. Each level is a smart contract that needs to be 'hacked'.

The game acts both as a tool for those interested in learning Ethereum, and as a way to catalog historical hacks in levels. Levels can be infinite, and the game does not require to be played in any particular order.

Created by [OpenZeppelin](https://www.openzeppelin.com/)
Visit [https://ethernaut.openzeppelin.com/](https://ethernaut.openzeppelin.com/)

## Acknowledgements

- Created by [OpenZeppelin](https://www.openzeppelin.com/)
- [Ethernaut Website](https://ethernaut.openzeppelin.com/)
- [Ethernaut GitHub](https://github.com/OpenZeppelin/ethernaut)
- [Foundry](https://github.com/gakonst/foundry)
- [Foundry Book](https://book.getfoundry.sh/)

Thanks to everyone who had helped me during the making of this project!

## Warnings - some solutions are missing!

Ethernaut sometimes rely on old version of solidity to showcase bugs/exploits. Some of those challenges were throwing compilation errors because of solidity compiler incompatibility.

These challenges are not part of the repository:

- [Alien Codex](https://ethernaut.openzeppelin.com/level/0xda5b3Fb76C78b6EdEE6BE8F11a1c31EcfB02b272)
- [Motorbike](https://ethernaut.openzeppelin.com/level/0x58Ab506795EC0D3bFAE4448122afa4cDE51cfdd2)

## How to play

### Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
```

### Update Foundry

```bash
foundryup
```

### Clone repo and install dependencies

```bash
git clone git@github.com:StErMi/foundry-ethernaut.git
cd foundry-ethernaut
git submodule update --init --recursive
```

### Run a solution

```bash
# example forge test --match-contract TestCoinFlip
forge test --match-contract NAME_OF_THE_TEST
```

### Create your own solutions

Create a new test `CHALLENGE.t.sol` in the `test/` directory and inherit from `BaseTest.sol`.

**BaseTest.sol** will automate all these things:

1. The constructor will set up some basic parameters like the number of users to create, how many ethers give them (5 ether) as initial balance and the labels for each user (for better debugging with forge)
2. Set up the `Ethernaut` contract
3. Register the level that you have specified in your `CHALLENGE.t.sol` constructor
4. Run the test automatically calling two callbacks inside your `CHALLENGE.t.sol` contract
   - `setupLevel` is the function you must override and implement all the logic needed to set up the challenge. Usually is always the same (call `createLevelInstance` and initialize the `level` variable)
   - `exploitLevel` is the function you must override and implement all the logic to solve the challenge
5. Run automatically the `checkSuccess` function that will check if the solution you have provided has solved the challenge

Here's an example of a test

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import './utils/BaseTest.sol';
import 'src/levels/CHALLENGE.sol';
import 'src/levels/CHALLENGEFactory.sol';

import '@openzeppelin/contracts/math/SafeMath.sol';

contract TestCHALLENGE is BaseTest {
  CoinFlip private level;

  constructor() public {
    // SETUP LEVEL FACTORY
    levelFactory = new CHALLENGEFactory();
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
    level = CHALLENGE(levelAddress);
  }

  function exploitLevel() internal override {
    /** CODE YOUR EXPLOIT HERE */

    vm.startPrank(player);

    // SOLVE THE CHALLENGE!

    vm.stopPrank();
  }
}

```

What you need to do is to

1. Replace `CHALLENGE` with the name of the Ethernaut challenge you are solving
2. Modify `setupLevel` if needed
3. Implement the logic to solve the challenge inside `setupLevel` between `startPrank` and `stopPrank`
4. Run the test!

## Disclaimer

All Solidity code, practices and patterns in this repository are DAMN VULNERABLE and for educational purposes only.

I **do not give any warranties** and **will not be liable for any loss** incurred through any use of this codebase.

**DO NOT USE IN PRODUCTION**.
