// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./RelayerManager.sol";

contract SubscriberStorage is Ownable {
    struct PinRecord {
        string pinCode;
        uint64 expiresAt;
    }

    error SubscriberStorage__InvalidAccount();
    error SubscriberStorage__InvalidPinCode();
    error SubscriberStorage__PinNotFound();
    error SubscriberStorage__InvalidSubscriberEmail();
    error SubscriberStorage__SubscriberEmailNotFound();
    error SubscriberStorage__SubscriberEmailAlreadyExists();

    uint64 private constant PIN_TTL = 10 minutes;

    RelayerManager public relayerManager;
    mapping(address => mapping(bytes32 => PinRecord)) private _pins;
    mapping(address => string[]) private _subscriberEmails;
    mapping(address => mapping(bytes32 => bool)) private _subscriberEmailExists;

    event PinCodeStored(address indexed account, string pinCode, uint64 expiresAt);
    event PinCodeCleared(address indexed account, string pinCode);
    event SubscriberEmailAdded(address indexed account, string email);
    event SubscriberEmailRemoved(address indexed account, string email);
    event RelayerManagerUpdated(address indexed relayerManager);

    constructor(address relayerManager_) Ownable(msg.sender) {
        _setRelayerManager(relayerManager_);
    }

    modifier onlyRelayer() {
        relayerManager.assertRelayer(msg.sender);
        _;
    }

    /* ========== Setter Functions ========== */

    function setRelayerManager(address relayerManager_) external onlyOwner {
        _setRelayerManager(relayerManager_);
    }

    function claimPinCode(address account, string calldata pinCode) external onlyRelayer {
        _setPinCode(account, pinCode);
    }

    function clearPinCode(address account, string calldata pinCode) external onlyRelayer {
        _clearPinCode(account, pinCode);
    }

    function addSubscriberEmail(address account, string calldata subscriberEmail) external onlyRelayer {
        _addSubscriberEmail(account, subscriberEmail);
    }

    function removeSubscriberEmail(address account, string calldata subscriberEmail) external onlyRelayer {
        _removeSubscriberEmail(account, subscriberEmail);
    }

    /* ========== Getter Functions ========== */

    function getPinCode(address account, string calldata pinCode) external view onlyOwner returns (PinRecord memory) {
        if (account == address(0)) revert SubscriberStorage__InvalidAccount();
        bytes32 pinKey = keccak256(bytes(pinCode));
        PinRecord memory record = _pins[account][pinKey];
        if (bytes(record.pinCode).length == 0) revert SubscriberStorage__PinNotFound();
        return record;
    }

    function isPinCodeActive(address account, string calldata pinCode) external view onlyOwner returns (bool) {
        if (account == address(0)) revert SubscriberStorage__InvalidAccount();
        bytes32 pinKey = keccak256(bytes(pinCode));
        PinRecord storage record = _pins[account][pinKey];
        if (bytes(record.pinCode).length == 0) {
            return false;
        }
        return block.timestamp <= record.expiresAt;
    }

    function getSubscriberEmails(address account) external view onlyOwner returns (string[] memory) {
        if (account == address(0)) revert SubscriberStorage__InvalidAccount();
        return _subscriberEmails[account];
    }

    /* ========== Internal Functions ========== */

    function _setPinCode(address account, string calldata pinCode) private {
        if (account == address(0)) revert SubscriberStorage__InvalidAccount();
        _validatePinCode(pinCode);

        bytes32 pinKey = keccak256(bytes(pinCode));
        uint64 expiresAt = uint64(block.timestamp + PIN_TTL);
        _pins[account][pinKey] = PinRecord({pinCode: pinCode, expiresAt: expiresAt});
        emit PinCodeStored(account, pinCode, expiresAt);
    }

    function _clearPinCode(address account, string calldata pinCode) private {
        if (account == address(0)) revert SubscriberStorage__InvalidAccount();
        bytes32 pinKey = keccak256(bytes(pinCode));
        PinRecord storage record = _pins[account][pinKey];
        if (bytes(record.pinCode).length == 0) revert SubscriberStorage__PinNotFound();

        delete _pins[account][pinKey];
        emit PinCodeCleared(account, pinCode);
    }

    function _validatePinCode(string calldata pinCode) private pure {
        bytes memory pinBytes = bytes(pinCode);
        if (pinBytes.length != 4) revert SubscriberStorage__InvalidPinCode();
        for (uint256 i = 0; i < pinBytes.length; i++) {
            bytes1 char = pinBytes[i];
            if (char < 0x30 || char > 0x39) revert SubscriberStorage__InvalidPinCode();
        }
    }

    function _addSubscriberEmail(address account, string calldata subscriberEmail) private {
        if (account == address(0)) revert SubscriberStorage__InvalidAccount();
        _validateSubscriberEmail(subscriberEmail);

        bytes32 emailKey = keccak256(bytes(subscriberEmail));
        if (_subscriberEmailExists[account][emailKey]) revert SubscriberStorage__SubscriberEmailAlreadyExists();

        _subscriberEmails[account].push(subscriberEmail);
        _subscriberEmailExists[account][emailKey] = true;
        emit SubscriberEmailAdded(account, subscriberEmail);
    }

    function _removeSubscriberEmail(address account, string calldata subscriberEmail) private {
        if (account == address(0)) revert SubscriberStorage__InvalidAccount();
        bytes32 emailKey = keccak256(bytes(subscriberEmail));
        if (!_subscriberEmailExists[account][emailKey]) revert SubscriberStorage__SubscriberEmailNotFound();

        string[] storage storedEmails = _subscriberEmails[account];
        uint256 length = storedEmails.length;
        for (uint256 i = 0; i < length; i++) {
            if (keccak256(bytes(storedEmails[i])) == emailKey) {
                uint256 lastIndex = length - 1;
                if (i != lastIndex) {
                    storedEmails[i] = storedEmails[lastIndex];
                }
                storedEmails.pop();
                delete _subscriberEmailExists[account][emailKey];
                emit SubscriberEmailRemoved(account, subscriberEmail);
                return;
            }
        }

        revert SubscriberStorage__SubscriberEmailNotFound();
    }

    function _validateSubscriberEmail(string calldata subscriberEmail) private pure {
        if (bytes(subscriberEmail).length == 0) revert SubscriberStorage__InvalidSubscriberEmail();
    }

    function _setRelayerManager(address relayerManager_) private {
        require(relayerManager_ != address(0), "SubscriberStorage: invalid RelayerManager");
        relayerManager = RelayerManager(relayerManager_);
        emit RelayerManagerUpdated(relayerManager_);
    }
}
