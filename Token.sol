// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StableToken is ERC20 {
    constructor() ERC20("Token", "TKN") {
        _mint(msg.sender, 1000000 * 10 ether);
    }
}
