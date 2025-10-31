// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AuthStorage is Ownable {
    /**
        AuthStorage :
            - 유저당 각 Device 별로 하나의 패스키(총 3개)를 등록
    */

    enum Device {
        Mobile,
        Tablet,
        Desktop
    }

    struct User {
        uint256 id;
        string adminCode;
        uint256 createdAt;
    }
    struct Passkey {
        string credentialId;
        string credential;
    }

    uint256 private _nextUserId;
    address[] private _userAddresses;

    mapping(address => User) private _users;
    mapping(address => mapping(Device => Passkey)) private _passkeys;

    constructor() Ownable(msg.sender) {}

    function registration(
        address recipient,
        string memory _adminCode,
        Device device,
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

        _setPasskey(recipient, device, credentialId, passkey);
        _userAddresses.push(recipient);
    }

    function addPasskey(
        address recipient,
        Device device,
        string memory credentialId,
        string memory passkey
    ) public onlyOwner {
        require(recipient != address(0), "AuthStorage: invalid recipient");
        require(bytes(credentialId).length != 0, "AuthStorage: credentialId required");
        require(bytes(passkey).length != 0, "AuthStorage: credential required");

        require(_users[recipient].id != 0, "AuthStorage: user not registered");

        _setPasskey(recipient, device, credentialId, passkey);
    }

    function deletePasskey(address recipient, Device device) public onlyOwner {
        require(recipient != address(0), "AuthStorage: invalid recipient");
        require(_users[recipient].id != 0, "AuthStorage: user not registered");

        delete _passkeys[recipient][device];
    }

    /**
        Getter(Viewer)
     */

    function getPasskey(address recipient, Device device) public view onlyOwner returns (string memory, string memory) {
        Passkey storage passkey = _passkeys[recipient][device];
        return (passkey.credentialId, passkey.credential);
    }

    function getPasskeys(address recipient) public view onlyOwner returns (Passkey[] memory) {
        require(recipient != address(0), "AuthStorage: invalid recipient");
        require(_users[recipient].id != 0, "AuthStorage: user not registered");

        uint256 deviceCount = uint256(type(Device).max) + 1;
        Passkey[] memory passkeys = new Passkey[](deviceCount);

        for (uint256 i = 0; i < deviceCount; i++) {
            Passkey storage stored = _passkeys[recipient][Device(uint8(i))];
            passkeys[i] = Passkey({credentialId: stored.credentialId, credential: stored.credential});
        }

        return passkeys;
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
        string memory _credentialId,
        string memory credential
    ) internal {
        _passkeys[recipient][device] = Passkey({credentialId: _credentialId, credential: credential});
    }
}
