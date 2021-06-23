// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import {AavegotchiInfo} from "../libraries/LibAavegotchi.sol";

interface IAavegotchiFacet {
    function totalSupply() external view returns (uint256 totalSupply_);

    function balanceOf(address _owner) external view returns (uint256 balance_);

    function getAavegotchi(uint256 _tokenId)
        external
        view
        returns (AavegotchiInfo memory aavegotchiInfo_);

    function aavegotchiClaimTime(uint256 _tokenId)
        external
        view
        returns (uint256 claimTime_);

    function tokenByIndex(uint256 _index)
        external
        view
        returns (uint256 tokenId_);

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256 tokenId_);

    function tokenIdsOfOwner(address _owner)
        external
        view
        returns (uint32[] memory tokenIds_);

    function allAavegotchisOfOwner(address _owner)
        external
        view
        returns (AavegotchiInfo[] memory aavegotchiInfos_);

    function ownerOf(uint256 _tokenId) external view returns (address owner_);

    function getApproved(uint256 _tokenId)
        external
        view
        returns (address approved_);

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool approved_);
}
