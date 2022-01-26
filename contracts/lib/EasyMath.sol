// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

library EasyMath {
    function abs(int256 x) internal pure returns (uint256) {
        return x <= 0 ? uint256(-x) : uint256(x);
    }

    function toShare(uint256 amount, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256) {
        if (totalShares == 0 || totalAmount == 0) {
            return amount;
        }
        return amount * totalShares / totalAmount;
    }

    function toAmount(uint256 share, uint256 totalAmount, uint256 totalShares) internal pure returns (uint256) {
        if (totalShares == 0 || totalAmount == 0) {
            return 0;
        }
        return share * totalAmount / totalShares;
    }
}
