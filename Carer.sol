// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import {Monitored} from "./Monitored.sol";
import {IAavegotchiFacet} from "./Aavegotchi/interfaces/IAavegotchiFacet.sol";
import {
    IAavegotchiGameFacet
} from "./Aavegotchi/interfaces/IAavegotchiGameFacet.sol";
import {AavegotchiInfo} from "./Aavegotchi/libraries/LibAavegotchi.sol";
import {CarerSession} from "./CarerSession.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Carer is Monitored, CarerSession, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    struct CareInfo {
        address owner;
        uint256 pets;
        uint256 maxPets;
    }

    EnumerableSet.UintSet internal caringGotchis;

    mapping(uint256 => CareInfo) public careInfoByGotchi;
    mapping(address => uint256) public balances;

    address public immutable diamond;
    IAavegotchiFacet public immutable facet;
    IAavegotchiGameFacet public immutable gameFacet;

    event LogTaskSubmitted(uint256 indexed index);
    event LogTaskDiscarded(uint256 indexed index);
    event LogFundsDeposited(address indexed sender, uint256 amount);
    event LogFundsWithdrawn(address indexed sender, uint256 amount);

    constructor(
        address _diamond,
        address payable _bot,
        address _GHST
    ) Monitored(_bot) CarerSession(_GHST) {
        diamond = _diamond;
        facet = IAavegotchiFacet(_diamond);
        gameFacet = IAavegotchiGameFacet(_diamond);
    }

    function startCareForMultiple(uint256[] calldata _indexes, uint256 _pets)
        external
    {
        require(
            maxPets.contains(_pets),
            "Carer: startCare: Not a session option"
        );
        require(
            facet.isApprovedForAll(msg.sender, address(this)),
            "Carer: startCareForMultiple: Carer not approved"
        );

        for (uint256 i = 0; i < _indexes.length; i++) {
            startCare(_indexes[i], _pets);
        }
    }

    function startCare(uint256 _index, uint256 _pets) internal {
        address _owner = facet.getAavegotchi(_index).owner;

        CareInfo memory newCareInfo = CareInfo(_owner, 0, _pets);
        careInfoByGotchi[_index] = newCareInfo;
        caringGotchis.add(_index);

        LogTaskSubmitted(_index);
    }

    function stopCare(uint256 _index) internal {
        caringGotchis.remove(_index);
        delete careInfoByGotchi[_index];

        LogTaskDiscarded(_index);
    }

    function stopCareForMultiple(uint256[] calldata _indexes) external {
        for (uint256 i = 0; i < _indexes.length; i++) {
            stopCare(_indexes[i]);
        }
    }

    function exec(
        uint256 _index,
        CareInfo calldata _careInfo,
        uint256 _fee
    ) external botOnly(_fee, MATIC) {
        require(
            caringGotchis.contains(_index),
            "Carer: exec: Gotchi not cared"
        );
        require(
            balances[_careInfo.owner] >= _fee,
            "Carer: exec: Insufficient balance"
        );

        uint256 _lastInteracted = facet.getAavegotchi(_index).lastInteracted;

        require(
            block.timestamp.sub(_lastInteracted) >= 12 hours,
            "Carer: exec: Time not elapsed"
        );

        require(
            _careInfo.pets < _careInfo.maxPets,
            "Carer: exec: Max continuous pets reached"
        );

        uint256[] memory _indexInArray = new uint256[](1);
        _indexInArray[0] = _index;

        gameFacet.interact(_indexInArray);

        balances[_careInfo.owner] = balances[_careInfo.owner].sub(_fee);

        payWages(_careInfo.owner, _careInfo.maxPets);

        if (_careInfo.pets.add(1) >= _careInfo.maxPets) {
            stopCare(_index);
        } else {
            CareInfo memory newCareInfo =
                CareInfo(
                    _careInfo.owner,
                    _careInfo.pets.add(1),
                    _careInfo.maxPets
                );

            careInfoByGotchi[_index] = newCareInfo;
        }
    }

    function depositFunds() external payable {
        require(msg.value >= 0.01 ether);
        balances[msg.sender] = balances[msg.sender].add(msg.value);

        emit LogFundsDeposited(msg.sender, msg.value);
    }

    function withdrawFunds() external nonReentrant {
        require(
            balances[msg.sender] > 0,
            "Carer: withdrawFunds: Sender has no balance"
        );

        uint256 _amount = balances[msg.sender];

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Carer: withdrawFunds: Withdraw funds failed");

        balances[msg.sender] = 0;

        emit LogFundsWithdrawn(msg.sender, _amount);
    }

    function getAllCaringGotchis()
        external
        view
        returns (uint256[] memory allCaringGotchis)
    {
        uint256 length = caringGotchis.length();
        allCaringGotchis = new uint256[](length);
        for (uint256 i = 0; i < length; i++)
            allCaringGotchis[i] = caringGotchis.at(i);
    }

    function isCaring(uint256 _index) external view returns (bool) {
        return (caringGotchis.contains(_index));
    }
}
