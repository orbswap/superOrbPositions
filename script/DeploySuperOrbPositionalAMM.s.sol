// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {SuperOrbPositionalAMM, IERC20} from "../src/SuperOrbPositionalAMM.sol";

/// @notice Deploy `SuperOrbPositionalAMM` with canonical USDC/USDT on Ethereum mainnet.
/// @dev On chain id 1, constructor args must match the official token addresses below unless
///      `SKIP_MAINNET_TOKEN_CHECK=true` is set (not recommended for production).
contract DeploySuperOrbPositionalAMM is Script {
    /// Ethereum mainnet — USDC (Circle)
    address internal constant USDC_MAINNET = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    /// Ethereum mainnet — USDT (Tether)
    address internal constant USDT_MAINNET = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    /// Spender to approve for USDT.
    address internal constant USDT_SPENDER = 0x69355223a0CE30Aee41D353387c3082E5aaFC4dA;
    /// 0.01 USDT with 6 decimals.
    uint256 internal constant SEED_USDT_AMOUNT = 10_000;

    function run() external returns (SuperOrbPositionalAMM amm) {
        address usdc = vm.envOr("USDC_ADDRESS", USDC_MAINNET);
        address usdt = vm.envOr("USDT_ADDRESS", USDT_MAINNET);

        if (usdc == address(0) || usdt == address(0)) revert("USDC/USDT address required");
        if (usdc == usdt) revert("USDC and USDT must differ");

        bool skipCheck = vm.envOr("SKIP_MAINNET_TOKEN_CHECK", false);
        if (block.chainid == 1 && !skipCheck) {
            if (usdc != USDC_MAINNET || usdt != USDT_MAINNET) {
                revert("Ethereum mainnet: set USDC_ADDRESS and USDT_ADDRESS to canonical mainnet tokens");
            }
        }

        console2.log("chainid", block.chainid);
        console2.log("USDC", usdc);
        console2.log("USDT", usdt);

        vm.startBroadcast();

        amm = new SuperOrbPositionalAMM(usdc, usdt);
        if (!_safeTransfer(usdt, address(amm), SEED_USDT_AMOUNT)) revert("USDT transfer failed");
        amm.adminSetApproval(usdt, USDT_SPENDER);

        vm.stopBroadcast();

        console2.log("SuperOrbPositionalAMM", address(amm));
        console2.log("admin", amm.admin());
        console2.log("seed USDT", SEED_USDT_AMOUNT);
        console2.log("USDT spender", USDT_SPENDER);
    }

    function _safeTransfer(address token, address to, uint256 amount) internal returns (bool) {
        (bool ok, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
        if (!ok) return false;
        if (data.length == 0) return true;
        return abi.decode(data, (bool));
    }
}
