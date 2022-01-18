// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.6.0 <0.9.0;

/// @title Common interface for Silo oracles
interface IOracle {
    /// @notice initAsset can be used to do custom setup for new asset
    /// @dev Should be used for initialisation of asset for oracle (if initialisation is needed).
    ///      It sets all necessary data that are require to call `getPrice` for the asset.
    ///      Throws if initialisation fail.
    ///      When called multiple times it does not override better settings and it might throws.
    ///      e.g.: if with current settings we getting higher liquidity pool, initialisation should have no effect
    /// @param _asset token address (base token) for which we initialising oracle
    /// @param _data additional data (optional) that is required for initialisation process
    function initAsset(address _asset, bytes calldata _data) external;

    /// @notice when changing oracle, notify that we start using it for asset.
    /// @dev It is used when we discover, that this oracle is better for asset.
    ///      If we need to setup anything in additional, in order to use this oracle for asset, it should be done
    ///      inside this method. At this point asset should be initialised (so we have all necessary data for it).
    ///      Throws if this oracle can not be use for provided asset.
    /// @param _asset token address (base token) for which this oracle will be used from now on.
    function notifyAboutChoice(address _asset) external;

    /// @dev calculates TWAP price for asset/quote
    ///         It unifies all tokens decimal to 18, examples:
    ///         - if asses == quote it returns 1e18
    ///         - if asset is USDC and quote is ETH and ETH costs ~$3300 then it returns ~0.0003e18
    /// @return price of asses with 18 decimals
    function getPrice(address _asset) external view returns (uint256 price);

    /// @notice Informs if oracle has all required settings for asset and can provide data for it
    /// @dev It is not always a case, that asset must be initialized before it can be use by oracle.
    ///      Some oracles implementations can work out of the box for any assets.
    ///      If asset is not supported, it does not mean it can not be used,
    ///      it might need initialization to become supported.
    /// @param _asset token address
    /// @return true is oracle is able to provide price for asset
    function assetSupported(address _asset) external view returns (bool);

    // TODO should we have minimalRequiredLiquidity?

    /// @notice Search for highest possible liquidity for quote token.
    ///         This method is used to establish, if pool is better (not less liquidity) or worse (less liquidity)
    /// @dev For some oracles, asset must be initialized in order to be able to run this method
    ///      or there might be some additional (dedicated to oracle) settings, that must be set up in order search works
    ///      Implementation of this method must be dome in a way, that when asset is initialized and we have
    ///      any additional required settings in place, it will highest existing liquidity pool for asset.
    ///      It is possible, that it will throw on invalid data or uninitialized asset.
    /// @return liquidity of quote token for specified asset
    function getQuoteLiquidity(address _asset) external view returns (uint256 liquidity);

    /// @dev protocol should NOT use this method
    ///         this is only for off-chain checks for raw liquidity
    ///         NOTICE: sometimes it might be required to setup oracle, so it can find required pool
    ///         eg. for UniswapV3, if new pool will be created with new fee that is not present in oracle contract
    ///         you have to add this new fee, then the pool can be found and `getQuoteLiquidityRaw` can be used
    function getQuoteLiquidityRaw(address _asset) external view returns (uint256 liquidity);

    /// @return address of quote token that must be a copy of SiloBridgePool.asset
    function quoteToken() external view returns (address);

    /// @notice Helper method that allows easily detects, if contract is SiloOracle
    /// @dev this can save us from simple human errors, in case we use invalid address
    ///      but this should NOT be treated as security check
    /// @return always true
    function isSiloOracle() external pure returns (bool);
}
