// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/metatx/ERC2771Forwarder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RelayerManager.sol";

contract InForwarder is ERC2771Forwarder, Ownable {
    RelayerManager public relayerManager;

    modifier onlyRelayer() {
        relayerManager.assertRelayer(msg.sender);
        _;
    }

    event RelayerManagerUpdated(address indexed relayerManager);

    constructor(string memory _name, address relayerManager_) ERC2771Forwarder(_name) Ownable(msg.sender) {
        _setRelayerManager(relayerManager_);
    }

    function setRelayerManager(address relayerManager_) external onlyOwner {
        _setRelayerManager(relayerManager_);
    }

    function execute(ForwardRequestData calldata req) public payable override onlyRelayer {
        super.execute(req);
    }

    function _setRelayerManager(address relayerManager_) private {
        require(relayerManager_ != address(0), "PostForwarder: invalid RelayerManager");
        relayerManager = RelayerManager(relayerManager_);
        emit RelayerManagerUpdated(relayerManager_);
    }
}
