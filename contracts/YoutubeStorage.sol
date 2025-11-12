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

    mapping(address => YouTubeVideo[]) private _videosByAccount;

    event VideoStored(address indexed account, string indexed id, string title);

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

    function _copyVideoToMemory(YouTubeVideo storage videoData) private view returns (YouTubeVideo memory) {
        string[] memory keyPoints = new string[](videoData.keyPoints.length);

        for (uint256 i = 0; i < videoData.keyPoints.length; i++) {
            keyPoints[i] = videoData.keyPoints[i];
        }

        return YouTubeVideo({id: videoData.id, title: videoData.title, keyPoints: keyPoints});
    }
}
