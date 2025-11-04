// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/metatx/ERC2771Forwarder.sol";

contract PostForwarder is ERC2771Forwarder {
    constructor(string memory _name) ERC2771Forwarder(_name) {}
}
