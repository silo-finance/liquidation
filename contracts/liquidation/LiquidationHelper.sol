// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../SiloLens.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/ISwapper.sol";
import "../interfaces/IRepository.sol";
import "../interfaces/ISiloOracleRepository.sol";

interface IWrappedNativeToken is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

/// @dev see https://github.com/silo-finance/liquidation#readme for details how liquidation process should looks like
contract LiquidationHelper is IFlashLiquidationReceiver, Ownable {
    bytes4 constant public SWAP_AMOUNT_IN_SELECTOR =
        bytes4(keccak256("swapAmountIn(address,address,uint256,address,address)"));

    bytes4 constant public SWAP_AMOUNT_OUT_SELECTOR =
        bytes4(keccak256("swapAmountOut(address,address,uint256,address,address)"));

    IRepository public immutable repository;
    SiloLens public immutable lens;
    IERC20 public immutable quoteToken;

    mapping(address => uint256) public earnings;
    mapping(IOracle => ISwapper) public swappers;

    IOracle[] public oraclesWithSwapOption;

    event LiquidationBalance(
        address user,
        uint256 quoteAmountFromCollaterals,
        int256 quoteLeftAfterRepay,
        uint256 gasSpend
    );

    constructor (
        address _repository,
        address _lens,
        IOracle[] memory _oraclesWithSwapOption,
        ISwapper[] memory _swappers
    ) {
        require(_repository != address(0), "empty repository");
        require(_lens != address(0), "empty lens");
        require(_swappers.length == _oraclesWithSwapOption.length, "swappers != oracles");

        repository = IRepository(_repository);
        lens = SiloLens(_lens);

        for (uint256 i = 0; i < _swappers.length; i++) {
            swappers[_oraclesWithSwapOption[i]] = _swappers[i];
        }

        oraclesWithSwapOption = _oraclesWithSwapOption;

        ISiloOracleRepository oracleRepo = ISiloOracleRepository(IRepository(_repository).oracle());
        quoteToken = IERC20(oracleRepo.quoteToken());
    }

    function withdraw() external {
        uint256 amount = earnings[msg.sender];
        if (amount == 0) return;

        earnings[msg.sender] = 0;
        quoteToken.transfer(msg.sender, amount);
    }

    function withdrawEth() external {
        uint256 amount = earnings[msg.sender];
        if (amount == 0) return;

        earnings[msg.sender] = 0;
        IWrappedNativeToken(address(quoteToken)).withdraw(amount);
        payable(msg.sender).transfer(amount);
    }

    function executeLiquidation(address[] memory _users, ISilo _silo) external {
        uint256 gasStart = gasleft();
        _silo.flashLiquidate(_users, address(this), IFlashLiquidationReceiver(this), abi.encode(gasStart));
    }

    function setSwapper(IOracle _oracle, ISwapper _swapper) external onlyOwner {
        swappers[_oracle] = _swapper;
    }

    /// @dev this is working example of how to perform liquidation, this method will be called by Silo
    ///         Keep in mind, that this helper might NOT choose the best swap option.
    ///         For best results (highest earnings) you probably want to implement your own callback and maybe use some
    ///         dex aggregators.
    function siloLiquidationCallback(
        address _user,
        address[] calldata _assets,
        uint256[] calldata _receivedCollaterals,
        uint256[] calldata _shareAmountsToRepaid,
        bytes memory _flashReceiverData
    ) external override {
        uint256 gasStart = abi.decode(_flashReceiverData, (uint256));

        ISilo silo = ISilo(msg.sender);
        require(repository.isSilo(address(silo)), "not a Silo");

        uint256 quoteAmountFromCollaterals;

        // swap all for quote token
        unchecked {
            for (uint256 i = 0; i < _assets.length; i++) {
                quoteAmountFromCollaterals += swapForQuote(_assets[i], _receivedCollaterals[i]);
            }
        }

        uint256 quoteSpendOnRepay;

        // repay
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_shareAmountsToRepaid[i] == 0) continue;

            unchecked {
                quoteSpendOnRepay += swapForAsset(_assets[i], _shareAmountsToRepaid[i]);
            }

            IERC20(_assets[i]).approve(address(silo), _shareAmountsToRepaid[i]);
            silo.repayFor(_assets[i], _user, _shareAmountsToRepaid[i]);
        }

        int256 quoteLeftAfterRepay = int256(quoteAmountFromCollaterals) - int256(quoteSpendOnRepay);
        address _owner = owner();

        earnings[_owner] = quoteLeftAfterRepay < 0
            ? earnings[_owner] - uint256(-1 * quoteLeftAfterRepay)
            : earnings[_owner] + uint256(quoteLeftAfterRepay);

        uint256 gasSpend = gasleft() - gasStart - 21000;
        emit LiquidationBalance(_user, quoteAmountFromCollaterals, quoteLeftAfterRepay, gasSpend);
    }

    function oraclesWithSwapOptionCount() external view returns (uint256) {
        return oraclesWithSwapOption.length;
    }

    function checkSolvency(address[] memory _users, ISilo[] memory _silos) external view returns (bool[] memory) {
        require(_users.length == _silos.length, "oops");

        bool[] memory solvency = new bool[](_users.length);

        for (uint256 i; i < _users.length; i++) {
            solvency[i] = _silos[i].isSolvent(_users[i]);
        }

        return solvency;
    }

    function checkDebt(address[] memory _users, ISilo[] memory _silos) external view returns (bool[] memory) {
        bool[] memory hasDebt = new bool[](_users.length);

        for (uint256 i; i < _users.length; i++) {
            hasDebt[i] = lens.inDebt(_silos[i], _users[i]);
        }

        return hasDebt;
    }

    function swapForQuote(address _asset, uint256 _amount) public returns (uint256) {
        if (_amount == 0 || _asset == address(quoteToken)) return _amount;

        IOracle oracle = findBestOracle(_asset);
        ISwapper swapper = swappers[oracle];

        bytes memory callData = abi.encodeWithSelector(
            SWAP_AMOUNT_IN_SELECTOR,
                _asset,
                quoteToken,
                _amount,
                oracle,
                _asset
        );

        // no need for safe approval, because we always using 100%
        IERC20(_asset).approve(swapper.spenderToApprove(), _amount);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = address(swapper).delegatecall(callData);
        require(success, "swapAmountIn failed");

        return abi.decode(data, (uint256));
    }

    /// @dev it swaps quote token for asset
    /// @param _asset address
    /// @param _amount exact amount OUT, what we want to receive
    /// @return amount of quote token used for swap
    function swapForAsset(address _asset, uint256 _amount) public returns (uint256) {
        if (_amount == 0 || address(quoteToken) == _asset) return _amount;

        IOracle oracle = findBestOracle(_asset);
        ISwapper swapper = swappers[oracle];

        bytes memory callData = abi.encodeWithSelector(
            SWAP_AMOUNT_OUT_SELECTOR,
            quoteToken,
            _asset,
            _amount,
            oracle,
            _asset
        );

        address spender = swapper.spenderToApprove();
        IERC20(quoteToken).approve(spender, type(uint256).max);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = address(swapper).delegatecall(callData);
        require(success, "swapAmountOut failed");
        IERC20(quoteToken).approve(spender, 0);

        return abi.decode(data, (uint256));
    }

    function findBestOracle(address _asset) public view returns (IOracle) {
        IOracle[] memory oracles = oraclesWithSwapOption;
        uint256 maxLiquidity;
        IOracle bestOracle;

        for (uint256 i = 0; i < oracles.length; i++) {
            IOracle oracle = oracles[i];
            uint256 quoteLiquidity = oracle.getQuoteLiquidityRaw(_asset);

            if (quoteLiquidity > maxLiquidity) {
                bestOracle = oracle;
                maxLiquidity = quoteLiquidity;
            }
        }

        return bestOracle;
    }
}
