// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// Exchange tokens

// Usage:
// 1. call `create` to begin the swap
// 2. the seller approves the TokenSwap contract to spend the amount of tokens
// 3. the buyer transfers the required amount

interface IToken {
    function allowance(address _owner, address _spender)
        external
        returns (uint256 remaining);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}

contract SSTokenSwap {
    address owner;
    uint256 startTime; // Timestamp of started time.
    uint16 bounsRatio;

    modifier owneronly {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _owner) public owneronly {
        owner = _owner;
    }

    constructor(uint swapStartedTime, uint16 initialBonusRatio) {
        owner = msg.sender;
        startTime = swapStartedTime;
        bounsRatio = initialBonusRatio;
    }

    struct Swap {
        address token; // Address of the token contract - SuperShiva
        uint256 amount; // Number of tokens requested
        address tokenIn; // Price to be paid by buyer - Ethos
        uint256 amountIn;
        address payable seller; // Seller's address (holder of tokens)
        address buyer; // Address to receive the tokens
    }

    mapping(address => Swap) public Swaps;

    function create(
        address token,
        uint256 amount,
        address tokenIn,
        address payable seller,
        address buyer
    ) public {
        // Ensure a Swap with the buyer does not exist already
        Swap storage swap = Swaps[buyer];
        require(swap.token == address(0));

        // Calc the hours passed from started time
        uint256 hoursPassed = (block.timestamp - startTime) / 3600;

        // Calc the amount to be swap
        uint256 amountIn = amount + amount * (bounsRatio / (hoursPassed + 1)) / 100;

        // Add a new Swap to storage
        Swaps[buyer] = Swap(token, amount, tokenIn, amountIn, seller, buyer);
    }

    function conclude() public payable {
        // Ensure the Swap has been initialised
        // by calling `create`
        Swap storage swap = Swaps[msg.sender];
        require(swap.token != address(0));

        // Has the seller approved the tokens?
        IToken token = IToken(swap.token);
        uint256 tokenAllowance = token.allowance(swap.seller, address(this));
        require(tokenAllowance >= swap.amount);

        // Ensure message value is above agreed amount
        require(msg.value >= swap.amountIn);

        // Transfer tokens to buyer
        token.transferFrom(swap.seller, swap.buyer, swap.amount);

        // Transfer new tokens to seller
        IToken tokenIn = IToken(swap.tokenIn);
        uint256 tokenInAllowance = tokenIn.allowance(swap.buyer, address(this));
        require(tokenInAllowance >= swap.amountIn);
        tokenIn.transferFrom(swap.buyer, swap.seller, swap.amountIn);

        if (tokenAllowance > swap.amount) {
            token.transferFrom(
                swap.seller,
                swap.seller,
                tokenAllowance - swap.amount
            );
        }

        if (tokenInAllowance > swap.amountIn) {
            token.transferFrom(
                swap.buyer,
                swap.buyer,
                tokenInAllowance - swap.amount
            );
        }

        // Clean up storage
        delete Swaps[msg.sender];
    }
}
