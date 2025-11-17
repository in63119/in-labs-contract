// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RelayerManager
 * @notice Keeps track of authorized relayers, their availability state, and exposes
 *         helper methods other contracts can query before trusting a relayer call.
 */
contract RelayerManager is Ownable {
    enum RelayerStatus {
        Ready,
        Processing,
        Shutdown
    }

    struct RelayerInfo {
        RelayerStatus status;
        bool exists;
    }

    mapping(address => RelayerInfo) private _relayers;
    address[] private _relayerList;
    uint256 private _readyRelayerCount;

    event RelayerAdded(address indexed relayer);
    event RelayerStatusChanged(address indexed relayer, RelayerStatus status);

    constructor() Ownable(msg.sender) {}

    modifier onlyRelayer() {
        require(_relayers[msg.sender].exists, "RelayerManager: not registered");
        _;
    }

    modifier onlyReadyRelayer() {
        RelayerInfo storage info = _relayers[msg.sender];
        require(info.exists, "RelayerManager: not registered");
        require(info.status == RelayerStatus.Ready, "RelayerManager: relayer busy");
        _;
    }

    // === Viewer functions ===

    function relayerStatus(address relayer) external view onlyOwner returns (RelayerStatus) {
        RelayerInfo storage info = _relayers[relayer];
        require(info.exists, "RelayerManager: relayer unknown");
        return info.status;
    }

    function isRelayer(address relayer) external view onlyOwner returns (bool) {
        return _relayers[relayer].exists;
    }

    function isRelayerReady(address relayer) public view onlyOwner returns (bool) {
        RelayerInfo storage info = _relayers[relayer];
        return info.exists && info.status == RelayerStatus.Ready;
    }

    function readyRelayerCount() external view onlyOwner returns (uint256) {
        return _readyRelayerCount;
    }

    function getReadyRelayer() external view onlyOwner returns (address) {
        for (uint256 i = 0; i < _relayerList.length; ++i) {
            if (_relayers[_relayerList[i]].status == RelayerStatus.Ready) {
                return _relayerList[i];
            }
        }
        revert("RelayerManager: no ready relayer");
    }

    function hasReadyRelayers(uint256 required) external view onlyOwner returns (bool) {
        return _readyRelayerCount >= required;
    }

    function getRelayers() external view onlyOwner returns (address[] memory) {
        return _relayerList;
    }

    // === External helper view (for other contracts) ===

    function assertReadyRelayer(address relayer) external view {
        RelayerInfo storage info = _relayers[relayer];
        require(info.exists, "RelayerManager: relayer unknown");
        require(info.status == RelayerStatus.Ready, "RelayerManager: relayer not ready");
    }

    // === Setter functions (owner) ===

    function addRelayer(address relayer) external onlyOwner {
        require(relayer != address(0), "RelayerManager: zero address");
        require(!_relayers[relayer].exists, "RelayerManager: already added");

        _relayers[relayer] = RelayerInfo({status: RelayerStatus.Ready, exists: true});
        _relayerList.push(relayer);
        _readyRelayerCount += 1;

        emit RelayerAdded(relayer);
        emit RelayerStatusChanged(relayer, RelayerStatus.Ready);
    }

    function setRelayerStatus(address relayer, RelayerStatus status) external onlyOwner {
        _setRelayerStatus(relayer, status);
    }

    // === Setter functions (relayer workflow) ===

    function beginProcessing() external onlyReadyRelayer {
        _setRelayerStatus(msg.sender, RelayerStatus.Processing);
    }

    function finishProcessing() external onlyRelayer {
        RelayerInfo storage info = _relayers[msg.sender];
        require(info.status == RelayerStatus.Processing, "RelayerManager: not processing");
        _setRelayerStatus(msg.sender, RelayerStatus.Ready);
    }

    function shutdownSelf() external onlyRelayer {
        _setRelayerStatus(msg.sender, RelayerStatus.Shutdown);
    }

    // === Helper functions ===

    function _setRelayerStatus(address relayer, RelayerStatus status) private {
        RelayerInfo storage info = _relayers[relayer];
        require(info.exists, "RelayerManager: relayer unknown");
        if (info.status == status) {
            return;
        }

        if (info.status == RelayerStatus.Ready) {
            _readyRelayerCount -= 1;
        }
        if (status == RelayerStatus.Ready) {
            _readyRelayerCount += 1;
        }

        info.status = status;
        emit RelayerStatusChanged(relayer, status);
    }
}
