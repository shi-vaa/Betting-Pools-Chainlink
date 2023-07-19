// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// betsz Token
contract BetszTestToken is ERC20("Betsz", "betsz") {
    constructor(uint256 amount) {
        _mint(msg.sender, amount);
    }
}
