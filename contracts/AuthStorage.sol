// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AuthStorage is Ownable {
    uint256 private constant DEFAULT_PASSKEY_SLOTS = 3;

    enum Device {
        Mobile,
        Tablet,
        Desktop
    }

    enum OS {
        Windows,
        MacOS,
        Android,
        iOS,
        Linux,
        Others
    }

    struct User {
        uint256 id;
        string adminCode;
        uint256 createdAt;
    }
    struct Passkey {
        Device deviceType;
        OS osType;
        string credentialId;
        string credential;
    }

    uint256 private _nextUserId;
    address[] private _userAddresses;

    mapping(address => User) private _users;
    mapping(address => Passkey[]) private _passkeys;
    mapping(address => uint256) private _passkeyCapacities;

    constructor() Ownable(msg.sender) {}

    function registration(
        address recipient,
        string memory _adminCode,
        Device device,
        OS osType,
        string memory credentialId,
        string memory passkey
    ) public onlyOwner {
        require(recipient != address(0), "AuthStorage: invalid recipient");
        require(bytes(_adminCode).length != 0, "AuthStorage: admin code required");
        require(bytes(credentialId).length != 0, "AuthStorage: credentialId required");
        require(bytes(passkey).length != 0, "AuthStorage: credential required");

        User storage user = _users[recipient];
        require(user.id == 0, "AuthStorage: already registered");

        user.id = ++_nextUserId;
        user.createdAt = block.timestamp;
        user.adminCode = _adminCode;

        _passkeyCapacities[recipient] = DEFAULT_PASSKEY_SLOTS;
        _setPasskey(recipient, device, osType, credentialId, passkey);
        _userAddresses.push(recipient);
    }

    function addPasskey(
        address recipient,
        Device device,
        OS osType,
        string memory credentialId,
        string memory passkey
    ) public onlyOwner {
        require(recipient != address(0), "AuthStorage: invalid recipient");
        require(bytes(credentialId).length != 0, "AuthStorage: credentialId required");
        require(bytes(passkey).length != 0, "AuthStorage: credential required");

        User storage user = _users[recipient];
        require(user.id != 0, "AuthStorage: user not registered");
        require(_passkeys[recipient].length < _passkeyCapacities[recipient], "AuthStorage: no free slots");

        _setPasskey(recipient, device, osType, credentialId, passkey);
    }

    function grantPasskeySlot(address recipient, uint256 amount) public onlyOwner {
        require(recipient != address(0), "AuthStorage: invalid recipient");
        require(_users[recipient].id != 0, "AuthStorage: user not registered");
        require(amount > 0, "AuthStorage: amount required");

        _passkeyCapacities[recipient] += amount;
    }

    function deletePasskey(address recipient, uint256 index) public onlyOwner {
        require(recipient != address(0), "AuthStorage: invalid recipient");
        require(_users[recipient].id != 0, "AuthStorage: user not registered");
        require(index < _passkeys[recipient].length, "AuthStorage: invalid index");

        uint256 lastIndex = _passkeys[recipient].length - 1;
        if (index != lastIndex) {
            _passkeys[recipient][index] = _passkeys[recipient][lastIndex];
        }
        _passkeys[recipient].pop();
    }

    function updatePasskey(
        address recipient,
        uint256 index,
        Device device,
        OS osType,
        string memory credentialId,
        string memory passkey
    ) public onlyOwner {
        require(recipient != address(0), "AuthStorage: invalid recipient");
        require(_users[recipient].id != 0, "AuthStorage: user not registered");
        require(index < _passkeys[recipient].length, "AuthStorage: invalid index");
        require(bytes(credentialId).length != 0, "AuthStorage: credentialId required");
        require(bytes(passkey).length != 0, "AuthStorage: credential required");

        Passkey storage slot = _passkeys[recipient][index];
        slot.deviceType = device;
        slot.osType = osType;
        slot.credentialId = credentialId;
        slot.credential = passkey;
    }

    /**
        Getter(Viewer)
     */

    function getPasskey(address recipient, uint256 index) public view onlyOwner returns (Passkey memory) {
        require(recipient != address(0), "AuthStorage: invalid recipient");
        require(_users[recipient].id != 0, "AuthStorage: user not registered");
        require(index < _passkeys[recipient].length, "AuthStorage: invalid index");

        return _passkeys[recipient][index];
    }

    function getPasskeys(address recipient) public view onlyOwner returns (Passkey[] memory) {
        require(recipient != address(0), "AuthStorage: invalid recipient");
        require(_users[recipient].id != 0, "AuthStorage: user not registered");

        return _passkeys[recipient];
    }

    function getPasskeyCapacity(address recipient) public view onlyOwner returns (uint256 used, uint256 capacity) {
        require(recipient != address(0), "AuthStorage: invalid recipient");
        require(_users[recipient].id != 0, "AuthStorage: user not registered");

        return (_passkeys[recipient].length, _passkeyCapacities[recipient]);
    }

    function getUserAddresses() public view onlyOwner returns (address[] memory) {
        return _userAddresses;
    }

    /**
        Helper
     */

    function _setPasskey(
        address recipient,
        Device device,
        OS osType,
        string memory _credentialId,
        string memory credential
    ) internal {
        Passkey memory passkey =
            Passkey({deviceType: device, osType: osType, credentialId: _credentialId, credential: credential});
        _passkeys[recipient].push(passkey);
    }
}
