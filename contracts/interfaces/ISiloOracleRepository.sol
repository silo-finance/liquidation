// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface ISiloOracleRepository {
    function addOracle(address oracle) external;
    function removeOracle(uint256 oracleId) external;
    function initOracleForAsset(address _asset, address _oracle, bytes calldata _data) external;
    function setBestOracleForAsset(address _asset) external returns (address bestOracle);
    function changeBestOracleForAsset(address asset, address oracle) external;

    /// @param _asset asset address
    /// @param _rawSearch boolean
    ///         - if FALSE, it performs search with all requirements, for example, TWAP readiness
    ///         - if TRUE, it performs a raw search, without any requirements (this is for off-chain checks)
    ///           that needs to be done for guarded silo creations
    function findBestOracle(address _asset, bool _rawSearch) external view returns (address);

    /// @return price TWAP price of a token
    function getPrice(address token) external view returns (uint256 price);

    /// @param _asset address
    /// @return oracle address assigned for asset
    function assetsOracles(address _asset) external view returns (address oracle);

    function quoteToken() external view returns (address);
}
