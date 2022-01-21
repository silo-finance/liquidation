// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IFactory {
    /// @param _siloAsset silo asset
    /// @param _data (optional) data that may be needed during silo creation
    /// @return silo address
    function createSilo(address _siloAsset, bytes memory _data) external returns (address silo);
}
