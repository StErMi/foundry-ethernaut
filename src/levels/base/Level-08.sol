// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../helpers/Ownable-08.sol";

abstract contract Level is Ownable {
    function createInstance(address _player) public payable virtual returns (address);

    function validateInstance(address payable _instance, address _player) public virtual returns (bool);
}
