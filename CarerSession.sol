// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import {
    SafeERC20,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CarerSession is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    IERC20 public immutable GHST;

    EnumerableSet.UintSet internal maxPets;
    mapping(uint256 => uint256) public rateOfMaxPets;

    constructor(address _GHST) {
        GHST = IERC20(_GHST);
    }

    function addMaxPets(uint256 _newMaxPets, uint256 _rateOfMaxPet)
        external
        onlyOwner
    {
        require(
            !maxPets.contains(_newMaxPets),
            "CarerSession: addMaxPets: Max pets already exists!"
        );

        maxPets.add(_newMaxPets);
        rateOfMaxPets[_newMaxPets] = _rateOfMaxPet;
    }

    function removeMaxPets(uint256 _maxPets) external onlyOwner {
        require(
            maxPets.contains(_maxPets),
            "CarerSession: addMaxPets: Max pets already exists!"
        );

        maxPets.remove(_maxPets);
        delete rateOfMaxPets[_maxPets];
    }

    function setRateOfMaxPet(uint256 _maxPet, uint256 _ratePerPet)
        external
        onlyOwner
    {
        rateOfMaxPets[_maxPet] = _ratePerPet;
    }

    function payWages(address _owner, uint256 _maxPets) internal {
        uint256 _rate = rateOfMaxPets[_maxPets];

        require(
            GHST.allowance(_owner, address(this)) >= _rate,
            "CarerSession: payWages: Allowance too low"
        );

        SafeERC20.safeTransferFrom(GHST, _owner, address(this), _rate);
    }

    function claimWages(uint256 _amt) external onlyOwner {
        address _owner = owner();
        SafeERC20.safeTransfer(GHST, _owner, _amt);
    }

    function getAllMaxPets()
        external
        view
        returns (uint256[] memory allMaxPets)
    {
        uint256 length = maxPets.length();
        allMaxPets = new uint256[](length);
        for (uint256 i; i < length; i++) allMaxPets[i] = maxPets.at(i);
    }
}
