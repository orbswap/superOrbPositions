// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev Minimal ERC20 surface used by this contract.
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;
    function approve(address spender, uint256 amount) external;
}

/// @title SuperOrbPositionalAMM
/// @notice Very simple USDC/USDT AMM: fixed pair, 1:1 swaps with a 3% fee.
contract SuperOrbPositionalAMM {
    IERC20 public immutable usdc;
    IERC20 public immutable usdt;
    address public immutable admin;

    uint256 public constant FEE_BPS = 300;
    uint256 public constant BPS_DENOMINATOR = 10_000;

    error NotAdmin();
    error InsufficientOutput();
    error TransferInFailed();
    error TransferOutFailed();
    error InvalidToken();

    event Swap(
        address indexed sender,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address to
    );
    event LiquidityAdded(address indexed token, uint256 amount, address indexed from);
    event Withdrawal(address indexed token, uint256 amount, address indexed to);
    event ApprovalSet(address indexed token, address indexed spender, uint256 amount);

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    constructor(address usdcToken, address usdtToken) {
        usdc = IERC20(usdcToken);
        usdt = IERC20(usdtToken);
        admin = msg.sender;
    }

    /// @notice Swap USDC<->USDT at 1:1 minus 3% fee.
    /// @param tokenIn Must be `usdc` or `usdt`.
    /// @param amountIn Input amount.
    /// @param amountOutMin Minimum acceptable output.
    /// @param to Receiver of output token.
    /// @return amountOut Output amount after fee.
    function swap(address tokenIn, uint256 amountIn, uint256 amountOutMin, address to)
        external
        returns (uint256 amountOut)
    {
        address tokenOut;
        if (tokenIn == address(usdc)) {
            tokenOut = address(usdt);
        } else if (tokenIn == address(usdt)) {
            tokenOut = address(usdc);
        } else {
            revert InvalidToken();
        }

        amountOut = (amountIn * (BPS_DENOMINATOR - FEE_BPS)) / BPS_DENOMINATOR;
        if (amountOut < amountOutMin) revert InsufficientOutput();

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(to, amountOut);

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut, to);
    }

    /// @notice Approve spender for this contract's USDC/USDT balance.
    function adminSetApproval(address tokenAddress, address approved) external onlyAdmin {
        uint256 max = type(uint256).max;
        IERC20(tokenAddress).approve(approved, max);

        emit ApprovalSet(tokenAddress, approved, max);
    }

    function addLiquidity(address token, uint256 amount) external onlyAdmin {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit LiquidityAdded(token, amount, msg.sender);
    }

    function adminWithdraw(address token, uint256 amount, address to) external onlyAdmin {
        IERC20(token).transfer(to, amount);
        emit Withdrawal(token, amount, to);
    }
}
