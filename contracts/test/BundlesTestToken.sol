// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Bund Token
contract BundlesTestToken is ERC20("Bundles", "BUND") {
    constructor(uint256 amount) {
        _mint(msg.sender, amount);
    }
}
