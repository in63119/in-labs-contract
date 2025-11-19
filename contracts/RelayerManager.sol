// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RelayerManager
 * @notice Keeps track of authorized relayers and exposes helper methods other
 *         contracts can query before trusting a relayer call.
 */
contract RelayerManager is Ownable {
    mapping(address => bool) private _relayers;
    address[] private _relayerList;

    event RelayerAdded(address indexed relayer);
    event RelayerRemoved(address indexed relayer);

    constructor() Ownable(msg.sender) {}

    modifier onlyRelayer() {
        require(_relayers[msg.sender], "RelayerManager: not registered");
        _;
    }

    // === Viewer functions ===

    function isRelayer(address relayer) external view onlyOwner returns (bool) {
        return _relayers[relayer];
    }

    function getRelayers() external view onlyOwner returns (address[] memory) {
        return _relayerList;
    }

    // === External helper view (for other contracts) ===

    function assertRelayer(address relayer) external view {
        require(_relayers[relayer], "RelayerManager: relayer unknown");
    }

    // === Setter functions (owner) ===

    function addRelayer(address relayer) external onlyOwner {
        require(relayer != address(0), "RelayerManager: zero address");
        require(!_relayers[relayer], "RelayerManager: already added");

        _relayers[relayer] = true;
        _relayerList.push(relayer);

        emit RelayerAdded(relayer);
    }

    function removeRelayer(address relayer) external onlyOwner {
        require(_relayers[relayer], "RelayerManager: relayer unknown");
        _relayers[relayer] = false;
        emit RelayerRemoved(relayer);
    }
}
