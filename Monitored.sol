// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import {
    SafeERC20,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Monitored {
    address public constant MATIC = 0x0000000000000000000000000000000000001010;
    address payable public immutable bot;

    constructor(address payable _bot) {
        bot = _bot;
    }

    modifier botOnly(uint256 _amount, address _paymentToken) {
        require(msg.sender == bot, "Monitored: Only bot");
        _;
        if (_paymentToken == MATIC) {
            (bool success, ) = bot.call{value: _amount}("");
            require(success, "Monitored: Bot fee failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_paymentToken), bot, _amount);
        }
    }
}
