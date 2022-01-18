// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./interfaces/ISilo.sol";
import "./lib/EasyMath.sol";


contract SiloLens {
    using EasyMath for uint256;

    function totalDeposits(ISilo _silo, address _asset) external view returns (uint256) {
        return _silo.assetStorage(_asset).totalDeposits;
    }

    function collateralOnlyDeposits(ISilo _silo, address _asset) external view returns (uint256) {
        return _silo.assetStorage(_asset).collateralOnlyDeposits;
    }

    function totalBorrowAmount(ISilo _silo, address _asset) external view returns (uint256) {
        return _silo.assetStorage(_asset).totalBorrowAmount;
    }

    function protocolFees(ISilo _silo, address _asset) external view returns (uint256) {
        return _silo.assetStorage(_asset).protocolFees;
    }

    function totalBorrowShare(ISilo _silo, address _asset) external view returns (uint256) {
        return _silo.assetStorage(_asset).debtToken.totalSupply();
    }

    function borrowShare(ISilo _silo, address _asset, address _user) external view returns (uint256) {
        return _silo.assetStorage(_asset).debtToken.balanceOf(_user);
    }

    function collateralBalanceOfUnderlying(ISilo _silo, address _asset, address _user) external view returns (uint256) {
        ISilo.AssetStorage memory _state = _silo.assetStorage(_asset);

        return balanceOfUnderlying(_state.totalDeposits, _state.collateralToken, _user) +
            balanceOfUnderlying(_state.collateralOnlyDeposits, _state.collateralOnlyToken, _user);
    }

    function debtBalanceOfUnderlying(ISilo _silo, address _asset, address _user) external view returns (uint256) {
        ISilo.AssetStorage memory _state = _silo.assetStorage(_asset);

        return balanceOfUnderlying(_state.totalBorrowAmount, _state.debtToken, _user);
    }

    /// @dev calculate combined Liquidation Threshold based on user deposits
    /// @return liquidation threshold of given user
    function getUserLiquidationThreshold(ISilo _silo, address _user) external view returns (uint256) {
        return _silo.calculateUserLTV(_user, false);
    }

    /// @dev calculate combined Maximum Loan-To-Value of user
    /// @return maximumLTV Maximum Loan-To-Value of given user
    function getUserMaximumLTV(ISilo _silo, address _user) external view returns (uint256) {
        return _silo.calculateUserLTV(_user, true);
    }

    /// @dev check if user is in debt
    /// @return TRUE if user borrowed any amount of any asset, otherwise FALSE
    function inDebt(ISilo _silo, address _user) external view returns (bool) {
        address[] memory allAssets = _silo.getAssets();

        for (uint256 i; i < allAssets.length; i++) {
            if (_silo.assetStorage(allAssets[i]).debtToken.balanceOf(_user) != 0) return true;
        }

        return false;
    }

    function balanceOfUnderlying(uint256 _assetTotalDeposits, IShareToken _shareToken, address _user)
        public
        view
        returns (uint256)
    {
        uint256 share = _shareToken.balanceOf(_user);
        return share.toAmount(_assetTotalDeposits, _shareToken.totalSupply());
    }
}
