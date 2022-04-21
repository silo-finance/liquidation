// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.6.0 <0.9.0;

library ModelStats {
    /// @notice Calculates fraction between borrowed and deposited amount of tokens denominated in percentage
    /// @dev It assumes 1e18 = 100%.
    /// @param _dp decimal points used by model
    /// @param _totalDeposits current total deposits for assets
    /// @param _totalBorrowAmount current total borrows for assets
    /// @return utilization value
    function calculateUtilization(int256 _dp, uint256 _totalDeposits, uint256 _totalBorrowAmount)
        internal
        pure
        returns (uint256)
    {
        if (_totalDeposits == 0 || _totalBorrowAmount == 0) return 0;

        return _totalBorrowAmount * uint256(_dp) / _totalDeposits;
    }
}
