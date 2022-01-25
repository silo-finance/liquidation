// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./IFactory.sol";
import "./ITokensFactory.sol";

interface IRepository {
    event NewSilo(address indexed silo, address indexed asset, uint256 siloVersion, address[] bridgeAssets);

    event BridgeAssetAdded(address newBridgeAsset);

    event BridgeAssetRemoved(address bridgeAssetRemoved);

    event InterestRateModel(address oldModel, address newModel);

    event BridgePoolUpdate(address oldPool, address newPool);

    event OracleUpdate(address oldOracle, address newOracle);

    event TokensFactoryUpdate(address oldTokensFactory, address newTokensFactory);

    event RouterUpdate(address oldRouter, address newRouter);

    event RegisterSiloVersion(address factory, uint256 siloLatestVersion, uint256 siloDefaultVersion);

    event UnregisterSiloVersion(address factory, uint256 siloVersion);

    event SiloDefaultVersion(uint256 siloDefaultVersion, uint256 defaultVersion);

    event FeeUpdate(
        uint256 oldEntryFee,
        uint256 newEntryFee,
        uint256 oldProtocolShareFee,
        uint256 newProtocolShareFee,
        uint256 oldProtocolLiquidationFee,
        uint256 newProtocolLiquidationFee
    );

    /// @dev use this method only when off-chain verification is OFF
    /// @param _siloAsset silo asset
    /// @param _siloVersion version of silo implementation
    /// @param _siloData (optional) data that may be needed during silo creation
    /// @param _oracle (optional) if provided, asset will be initialised on that oracle
    ///        it does not mean, this oracle will be chosen for asset, it only means, after valid initialization,
    ///        it could be chosen, if it is the best one
    /// @param _oracleData custom data for oracle initialization
    function newSilo(
        address _siloAsset,
        uint256 _siloVersion,
        bytes memory _siloData,
        address _oracle,
        bytes calldata _oracleData
    ) external;

    /// @dev use this method to deploy new version of Silo for an asset that already has Silo deployed.
    ///      Only owner (DAO) can replace.
    /// @param _siloAsset silo asset
    /// @param _siloVersion version of silo implementation. Use 0 for default version which is fine
    ///        for 99% of cases.
    /// @param _siloData (optional) data that may be needed during silo creation
    /// @param _oracle (optional) if provided, asset will be initialised on that oracle
    ///        it does not mean, this oracle will be chosen for asset, it only means, after valid initialization,
    ///        it could be chosen, if it is the best one
    /// @param _oracleData custom data for oracle initialization
    function replaceSilo(
        address _siloAsset,
        uint256 _siloVersion,
        bytes memory _siloData,
        address _oracle,
        bytes calldata _oracleData
    ) external;

    /// @dev use this method only when off-chain verification is ON
    /// @param _v v portion of off-chain verifier signature
    /// @param _r r portion of off-chain verifier signature
    /// @param _s s portion of off-chain verifier signature
    /// @param _siloAsset silo asset
    /// @param _siloVersion version of silo implementation
    /// @param _siloData (optional) data that may be needed during silo creation
    /// @param _oracle (optional) if provided, asset will be initialised on that oracle
    ///        it does not mean, this oracle will be chosen for asset, it only means, after valid initialization,
    ///        it could be chosen, if is is the best one
    /// @param _oracleData custom data for oracle initialization
    function newSiloVerified(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        address _siloAsset,
        uint256 _siloVersion,
        bytes memory _siloData,
        address _oracle,
        bytes calldata _oracleData
    ) external;

    function isSilo(address silo) external view returns (bool);
    function silo(address asset) external view returns (address);
    function siloFactory(uint256 siloVersion) external view returns (IFactory);
    function tokensFactory() external view returns (ITokensFactory);
    function router() external view returns (address);
    function getBridgeAssets() external view returns (address[] memory);
    function getRemovedBridgeAssets() external view returns (address[] memory);
    function oracle() external view returns (address);
    function owner() external view returns (address);
    function entryFee() external view returns (uint256);
    function protocolShareFee() external view returns (uint256);
    function getInterestRateModel(address silo, address asset) external view returns (address);
    function getMaximumLTV(address silo, address asset) external view returns (uint256);
    function getLiquidationThreshold(address silo, address asset) external view returns (uint256);
}
