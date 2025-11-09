// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VisitorStorage is Ownable {
    struct VisitorLog {
        bytes32[] hashedVisitors; // anonymized visitor identifiers for the day
        mapping(bytes32 => bool) exists; // quick lookup for duplicates
        uint64 total; // number of unique visitors recorded for the day
    }

    mapping(address => mapping(uint64 => VisitorLog)) private _logs;

    event HashedVisitorRecorded(address indexed owner, uint64 indexed dayId, bytes32 ipHash);

    constructor() Ownable(msg.sender) {}

    function currentDayId() public view returns (uint64) {
        return uint64(block.timestamp / 1 days);
    }

    function totalVisitorsOf(address owner, uint64 dayId) external view returns (uint64) {
        return _logs[owner][dayId].total;
    }

    function hashedVisitorCount(address owner, uint64 dayId) external view returns (uint256) {
        return _logs[owner][dayId].hashedVisitors.length;
    }

    function hashedVisitorAt(address owner, uint64 dayId, uint256 index) external view returns (bytes32) {
        bytes32[] storage visitors = _logs[owner][dayId].hashedVisitors;
        require(index < visitors.length, "VisitorStorage: index out of bounds");
        return visitors[index];
    }

    function hashedVisitorsOf(address owner, uint64 dayId) external view returns (bytes32[] memory) {
        VisitorLog storage log = _logs[owner][dayId];
        uint256 length = log.hashedVisitors.length;
        bytes32[] memory visitors = new bytes32[](length);
        for (uint256 i = 0; i < length; ++i) {
            visitors[i] = log.hashedVisitors[i];
        }
        return visitors;
    }

    function hasSeenHash(address owner, uint64 dayId, bytes32 ipHash) external view returns (bool) {
        return _logs[owner][dayId].exists[ipHash];
    }

    function addHashedVisitor(address owner, uint64 dayId, bytes32 ipHash) external onlyOwner {
        _recordHashedVisitor(owner, dayId, ipHash);
    }

    function addHashedVisitorForToday(address owner, bytes32 ipHash) external onlyOwner {
        _recordHashedVisitor(owner, currentDayId(), ipHash);
    }

    function addHashedVisitors(address owner, uint64 dayId, bytes32[] calldata ipHashes) external onlyOwner {
        for (uint256 i = 0; i < ipHashes.length; ++i) {
            _recordHashedVisitor(owner, dayId, ipHashes[i]);
        }
    }

    function addHashedVisitorsForToday(address owner, bytes32[] calldata ipHashes) external onlyOwner {
        uint64 dayId = currentDayId();
        for (uint256 i = 0; i < ipHashes.length; ++i) {
            _recordHashedVisitor(owner, dayId, ipHashes[i]);
        }
    }

    function _recordHashedVisitor(address owner, uint64 dayId, bytes32 ipHash) private {
        require(owner != address(0), "VisitorStorage: zero owner");
        require(ipHash != bytes32(0), "VisitorStorage: empty hash");

        VisitorLog storage log = _logs[owner][dayId];
        if (!log.exists[ipHash]) {
            log.exists[ipHash] = true;
            log.hashedVisitors.push(ipHash);
            unchecked {
                log.total += 1;
            }
            emit HashedVisitorRecorded(owner, dayId, ipHash);
        }
    }
}
