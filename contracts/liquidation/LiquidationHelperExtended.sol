// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./LiquidationHelper.sol";


contract LiquidationHelperExtended is LiquidationHelper {
    /// @dev is value that used for integer calculations and decimal points for utilisation ratios, LTV, protocol fees
    uint256 public constant PRECISION_DECIMALS = 1e18;

    constructor (
        address _repository,
        address _lens,
        IOracle[] memory _oraclesWithSwapOption,
        ISwapper[] memory _swappers
    ) LiquidationHelper(_repository, _lens, _oraclesWithSwapOption, _swappers) {}

    // goal here is to create method that can be safely implemented in BE
    function checkSolvencyOptimised(address[] memory _users, ISilo _silo)
        external
        view
        returns (bool[] memory solvency)
    {
        solvency = new bool[](_users.length);

        for (uint256 i; i < _users.length; i++) {
            uint256 liquidationThreshold = calculateUserLTV(_silo, _users[i]);
            uint256 ltv = getLTV(_silo, _users[i]);

            solvency[i] = ltv <= liquidationThreshold;
        }
    }

    function calculateUserLTV(ISilo _silo, address _user)
        public
        view
        returns (uint256)
    {
        ISiloOracleRepository oracle = ISiloOracleRepository(repository.oracle());
        uint256 totalCollateralValue;
        uint256 totalAvailableToBorrow;

        address[] memory assets = _silo.getAssets();

        for (uint256 i = 0; i < assets.length; i++) {
            uint256 assetPrice = _oracle.getPrice(assets[i]);
            uint256 decimals = ERC20(assets[i]).decimals();

            uint256 deposit = state[assets[i]].collateralToken.balanceOf(_user) +
                state[assets[i]].collateralOnlyToken.balanceOf(_user);

            // do math only if user has collateral deposited for given asset
            if (deposit != 0) {
                uint256 collateralValue = calculateCollateralValue(_silo, _user, assets[i], assetPrice, decimals);

                uint256 assetLTV = repository.getLiquidationThreshold(address(_silo), assets[i]);

                // value that can be borrowed against the deposit
                // ie. for assetLTV = 50%, 1 ETH * 50% = 0.5 ETH of available to borrow
                uint256 availableToBorrow = collateralValue * assetLTV / PRECISION_DECIMALS;

                totalCollateralValue += collateralValue;
                totalAvailableToBorrow += availableToBorrow;
            }
        }

        if (totalAvailableToBorrow == 0) return 0;
        if (totalCollateralValue == 0) return INFINITY;

        return totalAvailableToBorrow * PRECISION_DECIMALS / totalCollateralValue;
    }

    function getLTV(ISilo _silo, address _user) public view returns (uint256) {
        address[] memory assets = _silo.getAssets();
        uint256 collateralValue;
        uint256 borrowAmountValue;
        ISiloOracleRepository oracle = ISiloOracleRepository(repository.oracle());

        for (uint256 i = 0; i < assets.length; i++) {
            uint256 assetPrice = oracle.getPrice(assets[i]);
            uint256 decimals = ERC20(assets[i]).decimals();

            uint256 _borrowAmountValue = calculateBorrowValue(_user, assets[i], assetPrice, decimals);

            // It should be impossible but never too safe. If a user somehow ends up with debt
            // and collateral in single asset, we ignore collateral value of that asset
            if (_borrowAmountValue > 0) {
                borrowAmountValue += _borrowAmountValue;
            } else {
                // We allow removed bridge asset to be a collateral, that's why we do not check for:
                // !state[assets[i]].removed
                // otherwise people may be liquidated right away.
                collateralValue += calculateCollateralValue(_silo, _user, assets[i], assetPrice, decimals);
            }
        }

        if (borrowAmountValue == 0) return 0;
        if (collateralValue == 0) return INFINITY;

        return borrowAmountValue * PRECISION_DECIMALS / collateralValue;
    }

    function calculateCollateralValue(ISilo _silo, address _user, address _asset, uint256 _assetPrice, uint256 _assetDecimals)
        public
        view
        override
        returns (uint256)
    {
        ISilo.AssetStorage memory _state = _silo.assetStorage(_asset);

        uint256 assetAmount = _state.collateralToken.balanceOf(_user).toAmount(
            totalDepositsWithInterest(_silo, _asset),
            _state.collateralToken.totalSupply()
        );

        uint256 assetCollateralOnlyAmount = _state.collateralOnlyToken.balanceOf(_user).toAmount(
            _state.collateralOnlyDeposits,
            _state.collateralOnlyToken.totalSupply()
        );

        return (assetAmount + assetCollateralOnlyAmount) * _assetPrice / (10 ** _assetDecimals);
    }

    function calculateBorrowValue(address _user, address _asset, uint256 _assetPrice, uint256 _assetDecimals)
        public
        view
        returns (uint256)
    {
        uint256 debtAmount = getBorrowAmount(_asset, _user, block.timestamp);
        return debtAmount * _assetPrice / (10 ** _assetDecimals);
    }

    /// @return assetDebtAmount total amount of asset user needs to repay at provided timestamp
    function getBorrowAmount(address _asset, address _user, uint256 _timestamp) public view returns (uint256) {
        uint256 rcomp = _getModel(_asset).getCompoundInterestRate(address(this), _asset, _timestamp);
        // ^^^^^^^^^^^^^

        uint256 totalBorrowAmountCached = state[_asset].totalBorrowAmount;
        totalBorrowAmountCached += totalBorrowAmountCached * rcomp / PRECISION_DECIMALS;

        return state[_asset].debtToken.balanceOf(_user).toAmount(
            totalBorrowAmountCached,
            state[_asset].debtToken.totalSupply()
        );
    }

    function totalDepositsWithInterest(ISilo _silo, address _asset) public view returns (uint256 _totalDeposits) {
        uint256 rcomp = _getModel(_asset).getCompoundInterestRate(address(_silo), _asset, block.timestamp);
        // ^^^^^^^^^^^^^^^

        uint256 protocolShareFee = repository.protocolShareFee();
        uint256 depositorsShare = PRECISION_DECIMALS - protocolShareFee;
        uint256 assetDeposits = state[_asset].totalDeposits;

        return assetDeposits + assetDeposits * rcomp * depositorsShare / PRECISION_DECIMALS / PRECISION_DECIMALS;
    }
}
