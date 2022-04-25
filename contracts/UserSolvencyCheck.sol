// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./interfaces/IBaseSilo.sol";

import "./lib/Ping.sol";
import "./lib/Solvency.sol";

/// @title UserSolvencyCheck
/// @dev Contract that extracts `isSolvent` check
/// @custom:security-contact security@silo.finance
abstract contract UserSolvencyCheck is IBaseSilo {
    ISiloRepository immutable public override siloRepository;

    /// @dev asset => AssetStorage
    mapping(address => AssetStorage) public state;

    /// @dev stores all *synced* assets (bridge assets + removed bridge assets + siloAsset)
    address[] public allSiloAssets;

    constructor (address _repository) {
        require(Ping.pong(_repository, ISiloRepository.siloRepositoryPing.selector), "invalid _repository");
        siloRepository = ISiloRepository(_repository);
    }

    /// @inheritdoc IBaseSilo
    function getAssetsWithState() public view override returns (
        address[] memory assets,
        AssetStorage[] memory assetsStorage
    ) {
        assets = allSiloAssets;
        assetsStorage = new AssetStorage[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            assetsStorage[i] = state[assets[i]];
        }
    }

    /// @inheritdoc IBaseSilo
    function isSolvent(address _user) public view override returns (bool) {
        require(_user != address(0), "BaseSilo: user != address(0)");

        (address[] memory assets, AssetStorage[] memory assetsStates) = getAssetsWithState();

        (uint256 userLTV, uint256 liquidationThreshold) = Solvency.calculateLTVs(
            Solvency.SolvencyParams(
                siloRepository,
                ISilo(address(this)),
                assets,
                assetsStates,
                _user
            ),
            Solvency.TypeofLTV.LiquidationThreshold
        );

        return userLTV <= liquidationThreshold;
    }
}
