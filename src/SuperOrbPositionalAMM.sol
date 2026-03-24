// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal ERC20 interface for USDC/USDT operations.
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

/// @title SuperOrbPositionalAMM
/// @notice 1:1 USDC/USDT swaps with a 2% fee; admin manages liquidity and approvals.
contract SuperOrbPositionalAMM {
    IERC20 public immutable USDC;
    IERC20 public immutable USDT;

    address public immutable ADMIN;

    /// @dev 2% fee: output = input * (BPS_DENOMINATOR - FEE_BPS) / BPS_DENOMINATOR
    uint256 public constant FEE_BPS = 200;
    uint256 public constant BPS_DENOMINATOR = 10_000;

    bool private _entered;

    error NotAdmin();
    error Reentrancy();
    error Expired();
    error InvalidPath();
    error InvalidPair();
    error InvalidTo();
    error InsufficientOutput();
    error TransferInFailed();
    error TransferOutFailed();
    error InvalidToken();
    error ZeroAddress();

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
        if (msg.sender != ADMIN) revert NotAdmin();
        _;
    }

    modifier nonReentrant() {
        if (_entered) revert Reentrancy();
        _entered = true;
        _;
        _entered = false;
    }

    constructor(address usdc_, address usdt_) {
        if (usdc_ == address(0) || usdt_ == address(0)) revert ZeroAddress();
        if (usdc_ == usdt_) revert InvalidPair();
        USDC = IERC20(usdc_);
        USDT = IERC20(usdt_);
        ADMIN = msg.sender;
    }

    /// @notice Same signature as Uniswap V2 `Router02.swapExactTokensForTokens`. Path must be `[USDC, USDT]` or `[USDT, USDC]`.
    /// @dev 1:1 rate; 2% fee is taken from the notional (output = amountIn * 9800 / 10000).
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external nonReentrant returns (uint256[] memory amounts) {
        if (block.timestamp > deadline) revert Expired();
        if (path.length != 2) revert InvalidPath();
        if (to == address(0)) revert InvalidTo();

        address tokenIn = path[0];
        address tokenOut = path[1];

        bool usdcToUsdt = tokenIn == address(USDC) && tokenOut == address(USDT);
        bool usdtToUsdc = tokenIn == address(USDT) && tokenOut == address(USDC);
        if (!usdcToUsdt && !usdtToUsdc) revert InvalidPair();

        uint256 amountOut = (amountIn * (BPS_DENOMINATOR - FEE_BPS)) / BPS_DENOMINATOR;
        if (amountOut < amountOutMin) revert InsufficientOutput();

        if (!IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn)) revert TransferInFailed();
        if (!IERC20(tokenOut).transfer(to, amountOut)) revert TransferOutFailed();

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut, to);
    }

    /// @notice Admin sets allowance for another contract to pull USDC or USDT from this contract.
    function adminSetMaxApproval(address tokenAddress, address approved) external onlyAdmin {
        uint256 amount = type(uint256).max;
        IERC20(tokenAddress).approve(approved, amount);
        emit ApprovalSet(tokenAddress, approved, amount);
    }

    function adminSetApproval(address tokenAddress, address approved, uint256 amount) external onlyAdmin {
        if (!IERC20(tokenAddress).approve(approved, amount)) revert TransferOutFailed();
        IERC20(tokenAddress).approve(approved, amount);
        emit ApprovalSet(tokenAddress, approved, amount);
    }

    /// @notice Admin pulls USDC/USDT from their wallet into the pool (same as adding LP inventory).
    function addLiquidity(address token, uint256 amount) external onlyAdmin {
        if (token != address(USDC) && token != address(USDT)) revert InvalidToken();
        if (!IERC20(token).transferFrom(msg.sender, address(this), amount)) revert TransferInFailed();
        emit LiquidityAdded(token, amount, msg.sender);
    }

    /// @notice Admin can withdraw any ERC20 held by this contract.
    function adminWithdraw(address token, uint256 amount, address to) external onlyAdmin {
        if (to == address(0)) revert ZeroAddress();
        if (!IERC20(token).transfer(to, amount)) revert TransferOutFailed();
        emit Withdrawal(token, amount, to);
    }
}
