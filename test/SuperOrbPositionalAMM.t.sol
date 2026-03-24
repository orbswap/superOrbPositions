// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SuperOrbPositionalAMM} from "../src/SuperOrbPositionalAMM.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract SuperOrbPositionalAMMTest is Test {
    SuperOrbPositionalAMM internal amm;
    MockERC20 internal usdc;
    MockERC20 internal usdt;

    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function setUp() public {
        usdc = new MockERC20("USDC");
        usdt = new MockERC20("USDT");
        amm = new SuperOrbPositionalAMM(address(usdc), address(usdt));

        usdc.mint(alice, 1_000_000e6);
        usdt.mint(alice, 1_000_000e6);
        usdc.mint(address(amm), 500_000e6);
        usdt.mint(address(amm), 500_000e6);
    }

    function test_constructor() public view {
        assertEq(address(amm.usdc()), address(usdc));
        assertEq(address(amm.usdt()), address(usdt));
        assertEq(amm.admin(), address(this));
        assertEq(amm.FEE_BPS(), 300);
    }

    function test_swap_usdc_to_usdt() public {
        uint256 amountIn = 100e6;
        uint256 expectedOut = (amountIn * 9700) / 10_000;

        vm.startPrank(alice);
        usdc.approve(address(amm), amountIn);
        uint256 amountOut = amm.swap(address(usdc), amountIn, expectedOut, bob);
        vm.stopPrank();

        assertEq(amountOut, expectedOut);
        assertEq(usdt.balanceOf(bob), expectedOut);
    }

    function test_swap_reverts_invalid_token() public {
        MockERC20 other = new MockERC20("OTHER");
        vm.startPrank(alice);
        vm.expectRevert(SuperOrbPositionalAMM.InvalidToken.selector);
        amm.swap(address(other), 1e6, 0, bob);
        vm.stopPrank();
    }

    function test_swap_reverts_insufficient_output() public {
        uint256 amountIn = 10e6;
        uint256 expectedOut = (amountIn * 9700) / 10_000;

        vm.startPrank(alice);
        usdc.approve(address(amm), amountIn);
        vm.expectRevert(SuperOrbPositionalAMM.InsufficientOutput.selector);
        amm.swap(address(usdc), amountIn, expectedOut + 1, bob);
        vm.stopPrank();
    }

    function test_add_liquidity() public {
        usdc.mint(address(this), 200e6);
        usdc.approve(address(amm), 200e6);
        amm.addLiquidity(address(usdc), 200e6);
        assertEq(usdc.balanceOf(address(amm)), 500_200e6);
    }

    function test_admin_withdraw() public {
        uint256 bal = usdc.balanceOf(address(amm));
        amm.adminWithdraw(address(usdc), bal, bob);
        assertEq(usdc.balanceOf(bob), bal);
        assertEq(usdc.balanceOf(address(amm)), 0);
    }

    function test_non_admin_cannot_withdraw() public {
        vm.prank(alice);
        vm.expectRevert(SuperOrbPositionalAMM.NotAdmin.selector);
        amm.adminWithdraw(address(usdc), 1, bob);
    }

    function test_admin_set_approval() public {
        address spender = makeAddr("spender");
        amm.adminSetApproval(address(usdc), spender);
        assertEq(usdc.allowance(address(amm), spender), type(uint256).max);
    }

    function test_non_admin_cannot_set_approval() public {
        vm.prank(alice);
        vm.expectRevert(SuperOrbPositionalAMM.NotAdmin.selector);
        amm.adminSetApproval(address(usdc), bob);
    }
}
