// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./IShareToken.sol";

interface ITokensFactory {
    function createShareCollateralToken(
        string memory _name,
        string memory _symbol,
        address _asset
    )
        external
        returns (IShareToken);

    function createShareDebtToken(
        string memory _name,
        string memory _symbol,
        address _asset
    )
        external
        returns (IShareToken);
}
