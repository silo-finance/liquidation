// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IInterestRateModel {
    /* solhint-disable */
    struct Config {
        // uopt ∈ (0, 1) – optimal utilization;
        int256 uopt;
        // ucrit ∈ (uopt, 1) – threshold of large utilization;
        int256 ucrit;
        // ulow ∈ (0, uopt) – threshold of low utilization
        int256 ulow;
        // ki > 0 – integrator gain
        int256 ki;
        // kcrit > 0 – proportional gain for large utilization
        int256 kcrit;
        // klow ≥ 0 – proportional gain for low utilization
        int256 klow;
        // klin ≥ 0 – coefficient of the lower linear bound
        int256 klin;
        // a scaling factor
        int256 beta;
        // ri ≥ 0 – initial value of the integrator
        int256 ri;
        // the time during which the utilization exceeds the critical value
        int256 Tcrit;
    }
    /* solhint-enable */

    /// @dev Set dedicated config for giver asset in a Silo. Config is per asset per Silo so different assets
    /// in different Silo can have different configs.
    /// @param _silo Silo address for which config should be set
    /// @param _asset asset address for which config should be set
    function setConfig(address _silo, address _asset, Config calldata _config) external;

    /// @dev get compound interest rate and update model storage
    /// @param _asset address of an asset in Silo for which interest rate should be calculated
    /// @param _blockTimestamp current block timestamp
    /// @return rcomp compounded interest rate from last update until now
    function getCompoundInterestRateAndUpdate(
        address _asset,
        uint256 _blockTimestamp
    ) external returns (uint256 rcomp);

    /// @dev Get config for giver asset in a Silo. If dedicated config is not set, default one will be returned.
    /// @param _silo Silo address for which config should be set
    /// @param _asset asset address for which config should be set
    /// @return Config sturct for asset in Silo
    function getConfig(address _silo, address _asset) external view returns (Config memory);

    /// @dev get compound interest rate
    /// @param _silo address of Silo
    /// @param _asset address of an asset in Silo for which interest rate should be calculated
    /// @param _blockTimestamp current block timestamp
    /// @return rcomp compounded interest rate from last update until now
    function getCompoundInterestRate(
        address _silo,
        address _asset,
        uint256 _blockTimestamp
    ) external view returns (uint256 rcomp);

    /// @dev get current annual interest rate
    /// @param _silo address of Silo
    /// @param _asset address of an asset in Silo for which interest rate should be calculated
    /// @param _blockTimestamp current block timestamp
    /// @return rcur current annual interest rate
    function getCurrentInterestRate(
        address _silo,
        address _asset,
        uint256 _blockTimestamp
    ) external view returns (uint256 rcur);

    /// @dev pure function that calculates current annual interest rate
    /// @param _c configuration object, InterestRateModel.Config
    /// @param _u asset untilization
    /// @param _interestRateTimestamp timestamp of last interest rate update
    /// @param _blockTimestamp current block timestamp
    /// @return rcur current annual interest rate
    function calculateCurrentInterestRate(
        Config memory _c,
        int256 _u,
        uint256 _interestRateTimestamp,
        uint256 _blockTimestamp
    ) external pure returns (uint256 rcur);

    /// @dev pure function that calculates interest rate based on raw input data
    /// @param _c configuration object, InterestRateModel.Config
    /// @param _u asset untilization
    /// @param _interestRateTimestamp timestamp of last interest rate update
    /// @param _blockTimestamp current block timestamp
    /// @return rcomp compounded interest rate from last update until now
    /// @return ri current integral part of the rate
    /// @return Tcrit time during which the utilization exceeds the critical value
    function calculateCompoundInterestRate(
        Config memory _c,
        int256 _u,
        uint256 _interestRateTimestamp,
        uint256 _blockTimestamp
    ) external pure returns (
        uint256 rcomp,
        int256 ri,
        int256 Tcrit // solhint-disable-line var-name-mixedcase
    );

    /// @dev returns decimal points used by model
    function DP() external pure returns (int256); // solhint-disable-line func-name-mixedcase

    /// @dev just a helper method to see if address is a InterestRateModel
    /// @return always true
    function interestRateModelPing() external pure returns (bool);
}
