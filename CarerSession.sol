// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CarerSession is Ownable {
    using SafeMath for uint256;

    IERC20 public immutable GHST;

    uint256 public maxPets;
    uint256 public baseRate;
    uint256 public rateModifier;

    mapping(address => uint256) public rateOfOwner;

    constructor(address _GHST) {
        GHST = IERC20(_GHST);
    }

    function setMaxPets(uint256 _newMaxPets) external onlyOwner {
        maxPets = _newMaxPets;
    }

    function setBaseRate(uint256 _newBaseRate) external onlyOwner {
        baseRate = _newBaseRate;
    }

    function setRateModifier(uint256 _newRateModifier) external onlyOwner {
        rateModifier = _newRateModifier;
    }

    function sqrt(uint256 y) public pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function calculateRate(uint256 gotchis) public view returns (uint256) {
        require(
            gotchis != 0,
            "Carer: calculateRate: Number of gotchis cannot be 0."
        );
        uint256 extra = sqrt(rateModifier * 10**18 * gotchis);
        uint256 _rate = baseRate.add(extra);

        return _rate;
    }

    function determineAndSetRate(address _owner, uint256 _numOfIds) internal {
        uint256 _rate = calculateRate(_numOfIds);

        rateOfOwner[_owner] = _rate;
    }

    function payWages(address _owner) internal {
        uint256 _rate = rateOfOwner[_owner];

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
}
