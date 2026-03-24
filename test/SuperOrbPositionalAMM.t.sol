// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SuperOrbPositionalAMM} from "../src/SuperOrbPositionalAMM.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract SuperOrbPositionalAMMTest is Test {
    SuperOrbPositionalAMM internal amm;
    MockERC20 internal usdc;
    MockERC20 internal usdt;

    address internal admin = address(this);
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    uint256 internal constant FEE_BPS = 200;
    uint256 internal constant BPS = 10_000;

    event Swap(
        address indexed sender,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address to
    );

    function setUp() public {
        usdc = new MockERC20("USDC");
        usdt = new MockERC20("USDT");
        amm = new SuperOrbPositionalAMM(address(usdc), address(usdt));

        usdc.mint(alice, 1_000_000e6);
        usdt.mint(alice, 1_000_000e6);
        usdc.mint(address(amm), 500_000e6);
        usdt.mint(address(amm), 500_000e6);
    }

    function test_constructor_sets_immutables_and_admin() public view {
        assertEq(address(amm.USDC()), address(usdc));
        assertEq(address(amm.USDT()), address(usdt));
        assertEq(amm.ADMIN(), admin);
        assertEq(amm.FEE_BPS(), FEE_BPS);
    }

    function test_constructor_reverts_zero_usdc() public {
        vm.expectRevert(SuperOrbPositionalAMM.ZeroAddress.selector);
        new SuperOrbPositionalAMM(address(0), address(usdt));
    }

    function test_constructor_reverts_zero_usdt() public {
        vm.expectRevert(SuperOrbPositionalAMM.ZeroAddress.selector);
        new SuperOrbPositionalAMM(address(usdc), address(0));
    }

    function test_constructor_reverts_same_token() public {
        vm.expectRevert(SuperOrbPositionalAMM.InvalidPair.selector);
        new SuperOrbPositionalAMM(address(usdc), address(usdc));
    }

    function test_swap_usdc_to_usdt() public {
        uint256 amountIn = 100e6;
        uint256 expectedOut = (amountIn * (BPS - FEE_BPS)) / BPS;

        vm.startPrank(alice);
        usdc.approve(address(amm), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(usdt);

        uint256 bobBefore = usdt.balanceOf(bob);
        vm.expectEmit(true, true, true, true);
        emit Swap(alice, address(usdc), address(usdt), amountIn, expectedOut, bob);

        uint256[] memory amounts = amm.swapExactTokensForTokens(amountIn, expectedOut, path, bob, block.timestamp);
        vm.stopPrank();

        assertEq(amounts[0], amountIn);
        assertEq(amounts[1], expectedOut);
        assertEq(usdt.balanceOf(bob) - bobBefore, expectedOut);
        assertEq(usdc.balanceOf(address(amm)), 500_000e6 + amountIn);
    }

    function test_swap_usdt_to_usdc() public {
        uint256 amountIn = 50e6;
        uint256 expectedOut = (amountIn * (BPS - FEE_BPS)) / BPS;

        vm.startPrank(alice);
        usdt.approve(address(amm), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(usdc);

        uint256[] memory amounts = amm.swapExactTokensForTokens(amountIn, expectedOut, path, alice, block.timestamp);
        vm.stopPrank();

        assertEq(amounts[1], expectedOut);
        assertEq(usdt.balanceOf(alice), 1_000_000e6 - amountIn);
        assertEq(usdc.balanceOf(alice), 1_000_000e6 + expectedOut);
    }

    function test_swap_reverts_insufficient_output() public {
        uint256 amountIn = 100e6;
        uint256 expectedOut = (amountIn * (BPS - FEE_BPS)) / BPS;

        vm.startPrank(alice);
        usdc.approve(address(amm), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(usdt);

        vm.expectRevert(SuperOrbPositionalAMM.InsufficientOutput.selector);
        amm.swapExactTokensForTokens(amountIn, expectedOut + 1, path, bob, block.timestamp);
        vm.stopPrank();
    }

    function test_swap_reverts_expired() public {
        uint256 amountIn = 10e6;
        address[] memory path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(usdt);

        vm.startPrank(alice);
        usdc.approve(address(amm), amountIn);

        vm.expectRevert(SuperOrbPositionalAMM.Expired.selector);
        amm.swapExactTokensForTokens(amountIn, 0, path, bob, block.timestamp - 1);
        vm.stopPrank();
    }

    function test_swap_reverts_invalid_path_length() public {
        vm.startPrank(alice);
        address[] memory path = new address[](1);
        path[0] = address(usdc);

        vm.expectRevert(SuperOrbPositionalAMM.InvalidPath.selector);
        amm.swapExactTokensForTokens(1e6, 0, path, bob, block.timestamp);
        vm.stopPrank();
    }

    function test_swap_reverts_invalid_pair() public {
        MockERC20 other = new MockERC20("OTHER");
        vm.startPrank(alice);

        address[] memory path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(other);

        vm.expectRevert(SuperOrbPositionalAMM.InvalidPair.selector);
        amm.swapExactTokensForTokens(1e6, 0, path, bob, block.timestamp);
        vm.stopPrank();
    }

    function test_swap_reverts_invalid_to() public {
        vm.startPrank(alice);
        usdc.approve(address(amm), 1e6);

        address[] memory path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(usdt);

        vm.expectRevert(SuperOrbPositionalAMM.InvalidTo.selector);
        amm.swapExactTokensForTokens(1e6, 0, path, address(0), block.timestamp);
        vm.stopPrank();
    }

    function test_add_liquidity_only_admin() public {
        usdc.mint(alice, 100e6);
        vm.startPrank(alice);
        usdc.approve(address(amm), 100e6);

        vm.expectRevert(SuperOrbPositionalAMM.NotAdmin.selector);
        amm.addLiquidity(address(usdc), 100e6);
        vm.stopPrank();
    }

    function test_add_liquidity() public {
        usdc.mint(admin, 200e6);
        usdc.approve(address(amm), 200e6);

        uint256 beforeBal = usdc.balanceOf(address(amm));
        amm.addLiquidity(address(usdc), 200e6);

        assertEq(usdc.balanceOf(address(amm)), beforeBal + 200e6);
    }

    function test_add_liquidity_reverts_invalid_token() public {
        MockERC20 other = new MockERC20("OTHER");
        vm.expectRevert(SuperOrbPositionalAMM.InvalidToken.selector);
        amm.addLiquidity(address(other), 1);
    }

    function test_admin_withdraw() public {
        uint256 bal = usdc.balanceOf(address(amm));
        amm.adminWithdraw(address(usdc), bal, bob);
        assertEq(usdc.balanceOf(bob), bal);
        assertEq(usdc.balanceOf(address(amm)), 0);
    }

    function test_admin_withdraw_reverts_zero_to() public {
        vm.expectRevert(SuperOrbPositionalAMM.ZeroAddress.selector);
        amm.adminWithdraw(address(usdc), 1, address(0));
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

    function test_admin_set_approval_reverts_invalid_token() public {
        MockERC20 other = new MockERC20("OTHER");
        vm.expectRevert(SuperOrbPositionalAMM.InvalidToken.selector);
        amm.adminSetApproval(address(other), alice);
    }

    function test_admin_set_approval_reverts_zero_spender() public {
        vm.expectRevert(SuperOrbPositionalAMM.ZeroAddress.selector);
        amm.adminSetApproval(address(usdc), address(0));
    }

    function test_non_admin_cannot_set_approval() public {
        vm.prank(alice);
        vm.expectRevert(SuperOrbPositionalAMM.NotAdmin.selector);
        amm.adminSetApproval(address(usdc), bob);
    }

    function testFuzz_swap_output_matches_fee(uint128 amountIn) public {
        amountIn = uint128(bound(amountIn, 1, 100_000e6));

        uint256 expectedOut = (uint256(amountIn) * (BPS - FEE_BPS)) / BPS;

        vm.startPrank(alice);
        usdc.approve(address(amm), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(usdt);

        uint256[] memory amounts = amm.swapExactTokensForTokens(amountIn, expectedOut, path, bob, block.timestamp);
        vm.stopPrank();

        assertEq(amounts[1], expectedOut);
    }
}
