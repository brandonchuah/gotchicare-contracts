// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import {IAavegotchiFacet} from "./Aavegotchi/interfaces/IAavegotchiFacet.sol";
import {IAavegotchiGameFacet} from "./Aavegotchi/interfaces/IAavegotchiGameFacet.sol";
import {AavegotchiInfo} from "./Aavegotchi/libraries/LibAavegotchi.sol";
import {CarerSession} from "./CarerSession.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Carer is CarerSession, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct CareInfo {
        address owner;
        uint256[] gotchis;
        uint256 pets;
    }

    EnumerableSet.AddressSet internal caringOwners;

    mapping(address => uint256) public gotchisOfOwner;
    mapping(address => CareInfo) public careInfoByOwner;

    address public immutable diamond;
    address payable public immutable bot;
    IAavegotchiFacet public immutable facet;
    IAavegotchiGameFacet public immutable gameFacet;

    event LogTaskSubmitted(address indexed owner);
    event LogTaskDiscarded(address indexed owner);

    constructor(
        address _diamond,
        address payable _bot,
        address _GHST
    ) CarerSession(_GHST) {
        diamond = _diamond;
        bot = _bot;
        facet = IAavegotchiFacet(_diamond);
        gameFacet = IAavegotchiGameFacet(_diamond);
    }

    function startCareForOwner(uint256[] calldata _ids) external {
        require(
            !caringOwners.contains(msg.sender),
            "Carer: startCareForMultiple: Owner already started"
        );
        require(
            facet.isApprovedForAll(msg.sender, address(this)),
            "Carer: startCareForMultiple: Carer not approved"
        );

        address _owner = facet.getAavegotchi(_ids[0]).owner;
        require(
            msg.sender == _owner,
            "Carer: startCareForMultiple: Starter not owner"
        );

        CareInfo memory newCareInfo = CareInfo(_owner, _ids, 0);
        determineAndSetRate(msg.sender, _ids.length);

        careInfoByOwner[msg.sender] = newCareInfo;

        caringOwners.add(msg.sender);

        LogTaskSubmitted(msg.sender);
    }

    function stopCareForOwner() external {
        require(
            caringOwners.contains(msg.sender),
            "Carer: stopCareForOwner: Owner has not started"
        );

        clearOwnerInfo(msg.sender);
    }

    function clearOwnerInfo(address _owner) internal {
        caringOwners.remove(_owner);
        delete careInfoByOwner[_owner];
        delete rateOfOwner[_owner];

        LogTaskDiscarded(_owner);
    }

    function exec(CareInfo calldata _careInfo) external {
        require(msg.sender == bot, "Monitored: Only bot");

        require(
            caringOwners.contains(_careInfo.owner),
            "Carer: exec: Owner has not started"
        );

        require(
            _careInfo.pets < maxPets,
            "Carer: exec: Max continuous pets reached"
        );

        gameFacet.interact(_careInfo.gotchis);

        payWages(_careInfo.owner);

        if (_careInfo.pets.add(1) >= maxPets) {
            clearOwnerInfo(_careInfo.owner);
        } else {
            CareInfo memory newCareInfo = CareInfo(
                _careInfo.owner,
                _careInfo.gotchis,
                _careInfo.pets.add(1)
            );

            careInfoByOwner[_careInfo.owner] = newCareInfo;
        }
    }

    function getCaringOwners()
        external
        view
        returns (address[] memory _caringOwners)
    {
        uint256 length = caringOwners.length();
        _caringOwners = new address[](length);
        for (uint256 i = 0; i < length; i++)
            _caringOwners[i] = caringOwners.at(i);
    }

    function isCaring(address _owner) external view returns (bool) {
        return (caringOwners.contains(_owner));
    }

    function getCareInfoByOwner(address _owner)
        external
        view
        returns (CareInfo memory)
    {
        return careInfoByOwner[_owner];
    }
}
