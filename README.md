# <h1 align="center"> Forge Template </h1>

**Template repository for getting started quickly with Foundry projects**

![Github Actions](https://github.com/StErMi/forge-template/workflows/CI/badge.svg)

## Recognitions

- Base [forge-template](https://github.com/foundry-rs/forge-template) from Foundry team
- `Utilities.sol` from [FrankieIsLost forge-template](https://github.com/FrankieIsLost/forge-template)

## What is different from base tamplate?

- Added FrankieIsLost `Utilities.sol`
- Extended FrankieIsLost `Utilities.sol` to create tests users and setup them via `Utilities.createUsers`
- Auto labeling created test users
- Created `BaseTest.sol` contract
- preconfigured `solhint` and `prettier`

## Getting Started

Click "Use this template" on [GitHub](https://github.com/StErMi/forge-template) to create a new repository with this repo as the initial state.

Or, if your repo already exists, run:

```sh
forge init
forge build
forge test
```

## Writing your first test

All you need is to `import "./utils/BaseTest.sol";` that will inherit from and then inherit it from your test contract. Forge-std's Test contract comes with a pre-instatiated [cheatcodes environment](https://book.getfoundry.sh/cheatcodes/), the `vm`. It also has support for [ds-test](https://book.getfoundry.sh/reference/ds-test.html)-style logs and assertions. Finally, it supports Hardhat's [console.log](https://github.com/brockelmore/forge-std/blob/master/src/console.sol). The logging functionalities require `-vvvv`.

```solidity
// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import './utils/BaseTest.sol';

contract TestContract is BaseTest {
  constructor() {
    // Created (during `setUp()`) users will be available in `users` state variable

    // Setup test to create 2 test user with 100 ether in balance each
    // preSetUp(2);

    // Setup test to create 2 test user with 1 ether in balance each
    // preSetUp(2, 1 ether);

    // Setup test to create 2 test user with 1 ether in balance each and label them accordingly
    string[] memory userLabels = new string[](2);
    userLabels[0] = 'Alice';
    userLabels[1] = 'Bob';
    preSetUp(2, 100 ether, userLabels);
  }

  function setUp() public override {
    // Call the BaseTest setUp() function that will also create testsing accounts
    super.setUp();
  }

  function testSetUp() public {
    assertEq(users.length, 2);
    assertEq(users[0].balance, 100 ether);
  }

  function testBar() public {
    assertEq(uint256(1), uint256(1), 'ok');
  }

  function testFoo(uint256 x) public {
    vm.assume(x < type(uint128).max);
    assertEq(x + x, x * 2);
  }
}

```

## Development

This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html) for instructions on how to install and use Foundry.
