// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./IBaseSilo.sol";
import "./IFlashLiquidationReceiver.sol";

interface ISilo is IBaseSilo {
    function borrow(address _asset, uint256 _amount) external;

    function borrowFor(address _asset, address _user, address _to, uint256 _amount) external;

    function deposit(address _asset, uint256 _amount, bool collateralOnly) external;

    function depositFor(address _asset, address _user, uint256 _amount, bool collateralOnly) external;

    function repay(address _asset, uint256 _amount) external;

    function repayFor(address _asset, address _user, uint256 _amount) external;

    function withdraw(address _asset, uint256 _amount, bool collateralOnly) external;

    function withdrawFor(
        address _asset,
        address _depositor,
        address _receiver,
        uint256 _amount,
        bool collateralOnly
    ) external;

    /// @notice this methods does not requires to have tokens in order to liquidate user
    /// @param _users array of users to liquidate
    /// @param _liquidator all collateral will be send to this address
    /// @param _flashReceiver this address will be notified once all collateral will be send to _liquidator
    /// @param _flashReceiverData this data will be forward to receiver on notification
    /// @return assets array of all processed assets (collateral + debt, including removed)
    /// @return receivedCollaterals seizedCollaterals[userId][assetId] => amount
    ///         amounts of collaterals send to liquidator
    /// @return shareAmountsToRepaid shareAmountsToRepaid[userId][assetId] => amount
    ///         required amounts of debt to be repaid
    function flashLiquidate(
        address[] memory _users,
        address _liquidator,
        IFlashLiquidationReceiver _flashReceiver,
        bytes memory _flashReceiverData
    )
        external
        returns (
            address[] memory assets,
            uint256[][] memory receivedCollaterals,
            uint256[][] memory shareAmountsToRepaid
        );
}
