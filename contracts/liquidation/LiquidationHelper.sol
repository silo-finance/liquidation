// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../SiloLens.sol";
import "../interfaces/ISiloFactory.sol";
import "../interfaces/IPriceProvider.sol";
import "../interfaces/ISwapper.sol";
import "../interfaces/ISiloRepository.sol";
import "../interfaces/IPriceProvidersRepository.sol";

import "../lib/Ping.sol";

interface IWrappedNativeToken is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

/// @dev LiquidationHelper IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
///         see https://github.com/silo-finance/liquidation#readme for details how liquidation process should look like
contract LiquidationHelper is IFlashLiquidationReceiver, Ownable {
    bytes4 constant private _SWAP_AMOUNT_IN_SELECTOR =
        bytes4(keccak256("swapAmountIn(address,address,uint256,address,address)"));

    bytes4 constant private _SWAP_AMOUNT_OUT_SELECTOR =
        bytes4(keccak256("swapAmountOut(address,address,uint256,address,address)"));

    ISiloRepository public immutable siloRepository;
    SiloLens public immutable lens;
    IERC20 public immutable quoteToken;

    mapping(address => uint256) public earnings;
    mapping(IPriceProvider => ISwapper) public swappers;

    IPriceProvider[] public priceProvidersWithSwapOption;

    event LiquidationBalance(
        address user,
        uint256 quoteAmountFromCollaterals,
        int256 quoteLeftAfterRepay,
        uint256 gasSpend
    );

    constructor (
        address _repository,
        address _lens,
        IPriceProvider[] memory _priceProvidersWithSwapOption,
        ISwapper[] memory _swappers
    ) {
        require(Ping.pong(_repository, ISiloRepository.siloRepositoryPing.selector), "invalid _repository");
        require(Ping.pong(_lens, SiloLens.lensPing.selector), "invalid _lens");

        require(_swappers.length == _priceProvidersWithSwapOption.length, "swappers != providers");

        siloRepository = ISiloRepository(_repository);
        lens = SiloLens(_lens);

        for (uint256 i = 0; i < _swappers.length; i++) {
            swappers[_priceProvidersWithSwapOption[i]] = _swappers[i];
        }

        priceProvidersWithSwapOption = _priceProvidersWithSwapOption;

        IPriceProvidersRepository priceProviderRepo = ISiloRepository(_repository).priceProvidersRepository();
        quoteToken = IERC20(priceProviderRepo.quoteToken());
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

    function executeLiquidation(address[] calldata _users, ISilo _silo) external {
        uint256 gasStart = 29_001_691; // eg: gasleft();
        _silo.flashLiquidate(_users, abi.encode(gasStart));
    }

    function setSwapper(IPriceProvider _oracle, ISwapper _swapper) external onlyOwner {
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
        require(siloRepository.isSilo(address(silo)), "not a Silo");

        uint256 quoteAmountFromCollaterals;

        // swap all for quote token
        unchecked {
            for (uint256 i = 0; i < _assets.length; i++) {
                quoteAmountFromCollaterals += _swapForQuote(_assets[i], _receivedCollaterals[i]);
            }
        }

        uint256 quoteSpendOnRepay;

        // repay
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_shareAmountsToRepaid[i] == 0) continue;

            unchecked {
                quoteSpendOnRepay += _swapForAsset(_assets[i], _shareAmountsToRepaid[i]);
            }

            IERC20(_assets[i]).approve(address(silo), _shareAmountsToRepaid[i]);
            silo.repayFor(_assets[i], _user, _shareAmountsToRepaid[i]);

            // DEFLATIONARY TOKENS ARE NOT SUPPORTED
            // we are not using lower limits for swaps so we may not get enough tokens to do full repay
            // our assumption here is that `_shareAmountsToRepaid[i]` is total amount to repay the full debt
            // if after repay user has no debt in this asset, the swap is acceptable
            require(silo.assetStorage(_assets[i]).debtToken.balanceOf(_user) == 0, "repay failed");
        }

        int256 quoteLeftAfterRepay = int256(quoteAmountFromCollaterals) - int256(quoteSpendOnRepay);
        address _owner = owner();

        earnings[_owner] = quoteLeftAfterRepay < 0
            ? earnings[_owner] - uint256(-1 * quoteLeftAfterRepay)
            : earnings[_owner] + uint256(quoteLeftAfterRepay);

        uint256 gasSpend = gasStart - gasleft() - 21000;

        emit LiquidationBalance(_user, quoteAmountFromCollaterals, quoteLeftAfterRepay, gasSpend);
    }

    function priceProvidersWithSwapOptionCount() external view returns (uint256) {
        return priceProvidersWithSwapOption.length;
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

    function findPriceProvider(address _asset) public view returns (IPriceProvider) {
        IPriceProvider[] memory providers = priceProvidersWithSwapOption;

        for (uint256 i = 0; i < providers.length; i++) {
            IPriceProvider provider = providers[i];
            if (provider.assetSupported(_asset)) return provider;
        }

        revert("provider not found");
    }

    function _swapForQuote(address _asset, uint256 _amount) internal returns (uint256) {
        if (_amount == 0 || _asset == address(quoteToken)) return _amount;

        IPriceProvider priceProvider = findPriceProvider(_asset);
        ISwapper swapper = swappers[priceProvider];

        bytes memory callData = abi.encodeWithSelector(
            _SWAP_AMOUNT_IN_SELECTOR,
            _asset,
            quoteToken,
            _amount,
            priceProvider,
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
    function _swapForAsset(address _asset, uint256 _amount) internal returns (uint256) {
        if (_amount == 0 || address(quoteToken) == _asset) return _amount;

        IPriceProvider priceProvider = findPriceProvider(_asset);
        ISwapper swapper = swappers[priceProvider];

        bytes memory callData = abi.encodeWithSelector(
            _SWAP_AMOUNT_OUT_SELECTOR,
            quoteToken,
            _asset,
            _amount,
            priceProvider,
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
}
