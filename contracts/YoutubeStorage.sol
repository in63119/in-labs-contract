// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

contract YoutubeStorage is Ownable {
    struct YouTubeVideo {
        string id;
        string title;
        string[] keyPoints;
    }

    error YoutubeStorage__InvalidAccount();
    error YoutubeStorage__IndexOutOfBounds();
    error YoutubeStorage__VideoNotFound();

    mapping(address => YouTubeVideo[]) private _videosByAccount;

    event VideoStored(address indexed account, string indexed id, string title);
    event VideoDeleted(address indexed account, string indexed id);
    event VideoUpdated(address indexed account, string indexed id, string title);

    constructor() Ownable(msg.sender) {}

    /* ========== Setter Functions ========== */
    function saveMyVideo(
        string calldata videoId,
        string calldata title,
        string[] calldata keyPoints
    ) external {
        _storeVideo(msg.sender, videoId, title, keyPoints);
    }

    function saveVideoFor(
        address account,
        string calldata videoId,
        string calldata title,
        string[] calldata keyPoints
    ) external onlyOwner {
        _storeVideo(account, videoId, title, keyPoints);
    }

    function updateMyVideo(
        string calldata videoId,
        string calldata title,
        string[] calldata keyPoints
    ) external {
        _updateVideo(msg.sender, videoId, title, keyPoints);
    }

    function updateVideoFor(
        address account,
        string calldata videoId,
        string calldata title,
        string[] calldata keyPoints
    ) external onlyOwner {
        _updateVideo(account, videoId, title, keyPoints);
    }

    function deleteMyVideo(string calldata videoId) external {
        _deleteVideoById(msg.sender, videoId);
    }

    function deleteVideoFor(address account, string calldata videoId) external onlyOwner {
        _deleteVideoById(account, videoId);
    }

    /* ========== Getter Functions ========== */
    function getVideoCount(address account) external view returns (uint256) {
        return _videosByAccount[account].length;
    }

    function getVideo(address account, uint256 index) external view returns (YouTubeVideo memory) {
        if (index >= _videosByAccount[account].length) revert YoutubeStorage__IndexOutOfBounds();
        return _copyVideoToMemory(_videosByAccount[account][index]);
    }

    function getVideos(address account) external view returns (YouTubeVideo[] memory) {
        YouTubeVideo[] storage storedVideos = _videosByAccount[account];
        YouTubeVideo[] memory videos = new YouTubeVideo[](storedVideos.length);

        for (uint256 i = 0; i < storedVideos.length; i++) {
            videos[i] = _copyVideoToMemory(storedVideos[i]);
        }

        return videos;
    }

    /* ========== Helper Functions ========== */
    function _storeVideo(
        address account,
        string calldata videoId,
        string calldata title,
        string[] calldata keyPoints
    ) private {
        if (account == address(0)) revert YoutubeStorage__InvalidAccount();

        YouTubeVideo storage newVideo = _videosByAccount[account].push();
        newVideo.id = videoId;
        newVideo.title = title;

        for (uint256 i = 0; i < keyPoints.length; i++) {
            newVideo.keyPoints.push(keyPoints[i]);
        }

        emit VideoStored(account, videoId, title);
    }

    function _updateVideo(
        address account,
        string calldata videoId,
        string calldata title,
        string[] calldata keyPoints
    ) private {
        if (account == address(0)) revert YoutubeStorage__InvalidAccount();

        YouTubeVideo[] storage videos = _videosByAccount[account];
        for (uint256 i = 0; i < videos.length; i++) {
            if (keccak256(bytes(videos[i].id)) == keccak256(bytes(videoId))) {
                YouTubeVideo storage videoToUpdate = videos[i];
                videoToUpdate.title = title;

                delete videoToUpdate.keyPoints;
                for (uint256 j = 0; j < keyPoints.length; j++) {
                    videoToUpdate.keyPoints.push(keyPoints[j]);
                }

                emit VideoUpdated(account, videoId, title);
                return;
            }
        }

        revert YoutubeStorage__VideoNotFound();
    }

    function _deleteVideoById(address account, string calldata videoId) private {
        if (account == address(0)) revert YoutubeStorage__InvalidAccount();

        YouTubeVideo[] storage videos = _videosByAccount[account];
        uint256 length = videos.length;

        for (uint256 i = 0; i < length; i++) {
            if (keccak256(bytes(videos[i].id)) == keccak256(bytes(videoId))) {
                uint256 lastIndex = length - 1;
                if (i != lastIndex) {
                    videos[i] = videos[lastIndex];
                }
                videos.pop();
                emit VideoDeleted(account, videoId);
                return;
            }
        }

        revert YoutubeStorage__VideoNotFound();
    }

    function _copyVideoToMemory(YouTubeVideo storage videoData) private view returns (YouTubeVideo memory) {
        string[] memory keyPoints = new string[](videoData.keyPoints.length);

        for (uint256 i = 0; i < videoData.keyPoints.length; i++) {
            keyPoints[i] = videoData.keyPoints[i];
        }

        return YouTubeVideo({id: videoData.id, title: videoData.title, keyPoints: keyPoints});
    }
}
