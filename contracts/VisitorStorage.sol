// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./RelayerManager.sol";

contract VisitorStorage is Ownable {
    RelayerManager public relayerManager;

    struct VisitorEntry {
        bytes32 hashedVisitor;
        string visitUrl;
    }

    struct VisitorLog {
        VisitorEntry[] visitors;
        mapping(bytes32 => bool) exists;
    }

    mapping(address => mapping(uint64 => VisitorLog)) private _logs; // owner -> day -> log
    mapping(address => mapping(uint64 => uint256)) private _totals; // owner -> day -> total visitors
    mapping(address => mapping(uint64 => bool)) private _imported; // owner -> day -> imported

    event HashedVisitorRecorded(address indexed owner, uint64 indexed dayId, bytes32 ipHash, string url);
    event RelayerManagerUpdated(address indexed relayerManager);

    constructor(address relayerManager_) Ownable(msg.sender) {
        _setRelayerManager(relayerManager_);
    }

    modifier onlyRelayer() {
        relayerManager.assertRelayer(msg.sender);
        _;
    }

    // ----- Viewer functions -----
    function currentDayId() public view returns (uint64) {
        return uint64(block.timestamp / 1 days);
    }

    function totalVisitorsOf(address owner, uint64 dayId) external view returns (uint256) {
        return _totals[owner][dayId];
    }

    function hashedVisitorCount(address owner, uint64 dayId) external view returns (uint256) {
        return _logs[owner][dayId].visitors.length;
    }

    function hashedVisitorAt(address owner, uint64 dayId, uint256 index) external view returns (bytes32) {
        require(index < _logs[owner][dayId].visitors.length, "VisitorStorage: index out of bounds");
        VisitorEntry storage entry = _logs[owner][dayId].visitors[index];
        return entry.hashedVisitor;
    }

    function hashedVisitorsOf(address owner, uint64 dayId) external view returns (bytes32[] memory) {
        VisitorLog storage log = _logs[owner][dayId];
        uint256 length = log.visitors.length;
        bytes32[] memory visitors = new bytes32[](length);
        for (uint256 i = 0; i < length; ++i) {
            visitors[i] = log.visitors[i].hashedVisitor;
        }
        return visitors;
    }

    function hasSeenHash(address owner, uint64 dayId, bytes32 ipHash) external view returns (bool) {
        return _logs[owner][dayId].exists[ipHash];
    }

    function visitUrlAt(address owner, uint64 dayId, uint256 index) external view returns (string memory) {
        require(index < _logs[owner][dayId].visitors.length, "VisitorStorage: index out of bounds");
        VisitorEntry storage entry = _logs[owner][dayId].visitors[index];
        return entry.visitUrl;
    }

    function exportData(
        address owner,
        uint64[] calldata dayIds
    ) external view onlyOwner returns (bytes32[][] memory hashesPerDay, string[][] memory urlsPerDay) {
        require(owner != address(0), "VisitorStorage: zero owner");
        uint256 length = dayIds.length;
        hashesPerDay = new bytes32[][](length);
        urlsPerDay = new string[][](length);

        for (uint256 d = 0; d < length; ++d) {
            uint64 dayId = dayIds[d];
            VisitorLog storage log = _logs[owner][dayId];
            uint256 count = log.visitors.length;

            bytes32[] memory hashes = new bytes32[](count);
            string[] memory urls = new string[](count);
            for (uint256 i = 0; i < count; ++i) {
                VisitorEntry storage entry = log.visitors[i];
                hashes[i] = entry.hashedVisitor;
                urls[i] = entry.visitUrl;
            }
            hashesPerDay[d] = hashes;
            urlsPerDay[d] = urls;
        }
    }

    // ----- Setter functions -----
    function addHashedVisitor(address owner, uint64 dayId, bytes32 ipHash, string calldata url) external onlyRelayer {
        _recordHashedVisitor(owner, dayId, ipHash, url);
    }

    function addHashedVisitorForToday(address owner, bytes32 ipHash, string calldata url) external onlyRelayer {
        _recordHashedVisitor(owner, currentDayId(), ipHash, url);
    }

    function addHashedVisitors(
        address owner,
        uint64 dayId,
        bytes32[] calldata ipHashes,
        string calldata url
    ) external onlyRelayer {
        for (uint256 i = 0; i < ipHashes.length; ++i) {
            _recordHashedVisitor(owner, dayId, ipHashes[i], url);
        }
    }

    function addHashedVisitorsForToday(
        address owner,
        bytes32[] calldata ipHashes,
        string calldata url
    ) external onlyRelayer {
        uint64 dayId = currentDayId();
        for (uint256 i = 0; i < ipHashes.length; ++i) {
            _recordHashedVisitor(owner, dayId, ipHashes[i], url);
        }
    }

    function setRelayerManager(address relayerManager_) external onlyOwner {
        _setRelayerManager(relayerManager_);
    }

    function migrate(
        address owner,
        uint64[] calldata dayIds,
        bytes32[][] calldata hashesPerDay,
        string[][] calldata urlsPerDay
    ) external onlyOwner {
        require(owner != address(0), "VisitorStorage: zero owner");
        require(dayIds.length == hashesPerDay.length, "VisitorStorage: length mismatch");
        require(dayIds.length == urlsPerDay.length, "VisitorStorage: url length mismatch");

        for (uint256 d = 0; d < dayIds.length; ++d) {
            uint64 dayId = dayIds[d];
            require(!_imported[owner][dayId], "VisitorStorage: already imported");
            _imported[owner][dayId] = true;

            bytes32[] calldata hashes = hashesPerDay[d];
            string[] calldata urls = urlsPerDay[d];
            require(hashes.length == urls.length, "VisitorStorage: day length mismatch");
            for (uint256 i = 0; i < hashes.length; ++i) {
                _recordHashedVisitor(owner, dayId, hashes[i], urls[i]);
            }
        }
    }

    // ----- Helper functions -----
    function _recordHashedVisitor(address owner, uint64 dayId, bytes32 ipHash, string calldata url) private {
        require(owner != address(0), "VisitorStorage: zero owner");
        require(ipHash != bytes32(0), "VisitorStorage: empty hash");

        VisitorLog storage log = _logs[owner][dayId];
        if (!log.exists[ipHash]) {
            log.exists[ipHash] = true;
            log.visitors.push(VisitorEntry({hashedVisitor: ipHash, visitUrl: url}));
            unchecked {
                _totals[owner][dayId] += 1;
            }
            emit HashedVisitorRecorded(owner, dayId, ipHash, url);
        }
    }

    function _setRelayerManager(address relayerManager_) private {
        require(relayerManager_ != address(0), "VisitorStorage: invalid RelayerManager");
        relayerManager = RelayerManager(relayerManager_);
        emit RelayerManagerUpdated(relayerManager_);
    }
}
