// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../interfaces/ISwapper.sol";
import "../interfaces/IOracle.sol";


contract UniswapV3Swap is ISwapper {
    bytes4 constant public ASSETS_FEES_SELECTOR = bytes4(keccak256("assetsFees(address)"));

    ISwapRouter public immutable router;

    constructor (address _router) {
        router = ISwapRouter(_router);
    }

    /// @inheritdoc ISwapper
    function swapAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address _siloOracle,
        address _siloAsset
    ) external override returns (uint256 amountOut) {
        uint24 fee = resolveFee(_siloOracle, _siloAsset);
        return _swapAmountIn(_tokenIn, _tokenOut, _amount, fee);
    }

    /// @inheritdoc ISwapper
    function swapAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut,
        address _siloOracle,
        address _siloAsset
    ) external override returns (uint256 amountIn) {
        uint24 fee = resolveFee(_siloOracle, _siloAsset);
        return _swapAmountOut(_tokenIn, _tokenOut, _amountOut, fee);
    }

    /// @inheritdoc ISwapper
    function spenderToApprove() external view override returns (address) {
        return address(router);
    }

    function resolveFee(address _oracle, address _asset) public view returns (uint24 fee) {
        bytes memory callData = abi.encodeWithSelector(ASSETS_FEES_SELECTOR, _asset);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = _oracle.staticcall(callData);
        require(success, "fee for asset not set");

        fee = abi.decode(data, (uint24));
    }

    function pathToBytes(address[] memory path, uint24[] memory fees) public pure returns (bytes memory bytesPath) {
        for (uint256 i = 0; i < path.length; i++) {
            bytesPath = i == fees.length
            ? abi.encodePacked(bytesPath, path[i])
            : abi.encodePacked(bytesPath, path[i], fees[i]);
        }
    }

    function _swapAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint24 _fee
    ) internal returns (uint256 amountOut) {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: 1,
            sqrtPriceLimitX96: 0
        });

        return router.exactInputSingle(params);
    }

    function _swapAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut,
        uint24 _fee
    ) internal returns (uint256 amountOut) {
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountOut: _amountOut,
            amountInMaximum: type(uint256).max,
            sqrtPriceLimitX96: 0
        });

        return router.exactOutputSingle(params);
    }
}
