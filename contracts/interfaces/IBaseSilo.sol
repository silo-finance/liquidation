// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./IShareToken.sol";


interface IBaseSilo {
    struct AssetStorage {
        // Token that represents a share in totalDeposits of Silo
        IShareToken collateralToken;
        // Token that represents a share in collateralOnlyDeposits of Silo
        IShareToken collateralOnlyToken;
        // Token that represents a share in totalBorrowAmount of Silo
        IShareToken debtToken;
        // COLLATERAL: Amount of asset token that has been deposited to Silo with interest earned by depositors.
        // It also includes token amount that has been borrowed.
        uint256 totalDeposits;
        // COLLATERAL ONLY: Amount of asset token that has been deposited to Silo that can be ONLY used as collateral.
        // These deposits do NOT earn interest and CANNOT be borrowed.
        uint256 collateralOnlyDeposits;
        // DEBT: Amount of asset token that has been borrowed with accrued interest.
        uint256 totalBorrowAmount;
        // Timestamp of the last time `interestRate` has been updated in storage.
        uint256 interestRateTimestamp;
        // Total amount (ever growing) of asset token that has been earned by the protocol from generated interest.
        uint256 protocolFees;
        // Total amount of already harvested protocol fees
        uint256 harvestedProtocolFees;
        // True if asset was removed from the protocol. If so, deposit and borrow functions are disabled for that asset
        bool removed;
    }

    function getAssets() external view returns (address[] memory assets);

    function assetStorage(address _asset) external view returns (AssetStorage memory);

    // function liquidationWithdraw(address _depositor) external returns (uint256 amount);
    // function seizeCollateral(address user, address liquidator) external returns (uint256);
    function isSolvent(address _user) external view returns (bool);

    /// @dev calculate combined Loan-To-Value of user, using either maximumLTV or liquidationThreshold
    /// @param _useMaximumLTV bool
    ///         when TRUE returns maximum Loan-To-Value of given user,
    ///         when FALSE return liquidation threshold of given user
    /// @return Loan-To-Value of given user
    function calculateUserLTV(address _user, bool _useMaximumLTV) external view returns (uint256);

    function calculateCollateralValue(address _user, address _asset, uint256 _assetPrice, uint256 _assetDecimals)
        external
        view
        returns (uint256);

    function getLTV(address _user) external view returns (uint256);

    /// @dev we do not allow for deposit when asset is already borrowed by user
    /// @param _asset asset we want to deposit
    /// @param _depositor depositor address
    /// @return true if asset can be deposited by depositor
    function depositPossible(address _asset, address _depositor) external view returns (bool);

    /// @dev we do not allow for borrow when asset is also deposited by user
    /// @param _asset asset we want to deposit
    /// @param _borrower borrower address
    /// @return true if asset can be borrowed by borrower
    function borrowPossible(address _asset, address _borrower) external view returns (bool);

    function getUtilization(address _asset) external view returns (uint256);
    function interestRateTimestamp(address _asset) external view returns (uint256);
}
