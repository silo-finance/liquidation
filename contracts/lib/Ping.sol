// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library Ping {
    function pong(address _contract, bytes4 _selector) internal view returns (bool) {
        if (_contract == address(0)) return false;

        (bool success, bytes memory data) = _contract.staticcall(abi.encodeWithSelector(_selector));
        return success && abi.decode(data, (bool));
    }

    function decimals(address _contract) internal view returns (uint256) {
        if (_contract == address(0)) return 0;

        (bool success, bytes memory data) = _contract.staticcall(abi.encodeWithSelector(ERC20.decimals.selector));
        if (!success) return 0;

        return abi.decode(data, (uint256));
    }
}
