// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// Exchange tokens

// Usage:
// 1. call `create` to begin the swap
// 2. the seller approves the SSTokenSwap contract to spend the amount of tokens
// 3. the buyer transfers the required amount

interface IToken {
    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract SSTokenSwap {
    using SafeMath for uint256;

    address tokenOutAddr = 0x030545b8AfaBeFE9532CCBB3BC1343d643d02a05; //new address
    address tokenInAddr = 0x922c77c7724d7B77fD7791BE5CC5314B70c3a781; //old address
    address sellerAddress = 0x8b23789E93631721540800dF882D200bd43C0F05; //Wallet containing new
    address owner; //Wallet of the user
    address withdrawAddress = 0x6B3FC26e75c83A498D93451554A33Ed6C7c103B1; // Withdraw Address
    uint256 startTime = 1628571139; // Timestamp in blocktime of the start of Swap.
    uint256 initialBonusRatio = 25;
    uint256 endingBonusRatio = 10;
    uint256 swapRatio = 100000;
    uint256 maxAmount = 2000000000;

    IToken tokenOut = IToken(tokenOutAddr);
    IToken tokenIn = IToken(tokenInAddr);

    modifier owneronly() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _owner) public owneronly {
        owner = _owner;
    }

    function setTokenOutAddress(address _tokenOutAddr) external owneronly {
        tokenOutAddr = _tokenOutAddr;
        tokenOut = IToken(tokenOutAddr);
    }

    function setTokenInAddress(address _tokenInAddr) external owneronly {
        tokenInAddr = _tokenInAddr;
        tokenIn = IToken(tokenInAddr);
    }

    function setSellerAddress(address _sellerAddress) external owneronly {
        sellerAddress = _sellerAddress;
    }

    function setStartTime(uint32 _startTime) external owneronly {
        startTime = _startTime;
    }

    function setInitialBonusRatio(uint256 _initialBonusRatio)
        external
        owneronly
    {
        initialBonusRatio = _initialBonusRatio;
    }

    function setEndingBonusRatio(uint256 _endingBonusRatio) external owneronly {
        endingBonusRatio = _endingBonusRatio;
    }

    function setSwapRatio(uint256 _swapRatio) external owneronly {
        swapRatio = _swapRatio;
    }

    function setMaxAmount(uint256 _maxAmount) external owneronly {
        maxAmount = _maxAmount;
    }

    function setWithdrawAddress(address _withdrawAddress) external owneronly {
        withdrawAddress = _withdrawAddress;
    }

    function getBalanceOfTokens(address userAddress)
        external
        view
        returns (uint256, uint256)
    {
        return (
            tokenIn.balanceOf(userAddress),
            tokenOut.balanceOf(userAddress)
        );
    }

    function getCurrentBonusRatio() external view returns (uint256) {
        // Calc the hours passed from started time
        uint256 hoursPassed = (block.timestamp - startTime) / 3600;

        // Calc the bonus ratio
        uint256 bonusRatio;
        if (hoursPassed <= 24 * 7) {
            bonusRatio = (initialBonusRatio * 24 * 7 - hoursPassed * (initialBonusRatio - endingBonusRatio)).div(24 * 7);
        } else if (hoursPassed <= 24 * 7 * 2) {
            bonusRatio = endingBonusRatio;
        } else {
            bonusRatio = 0;
        }
        return bonusRatio;
    }

    constructor() {
        owner = msg.sender;
    }


    function create(uint256 amountIn) public {
        // Limit tokenIn amount
        require(amountIn <= maxAmount);

        // Calc the hours passed from started time
        uint256 hoursPassed = (block.timestamp - startTime) / 3600;

        // Calc the amount to be swap
        uint256 bonus;
        if (hoursPassed <= 24 * 7) {
            bonus = (amountIn * (initialBonusRatio * 24 * 7 - hoursPassed * (initialBonusRatio - endingBonusRatio))).div(24 * 7).div(100);
        } else if (hoursPassed <= 24 * 7 * 2) {
            bonus = (amountIn * endingBonusRatio).div(100);
        } else {
            bonus = 0;
        }
        uint256 amountOut = (amountIn + bonus) / swapRatio;
        
        // Has the seller approved the tokens? - new
        uint256 tokenOutAllowance = tokenOut.allowance(
            sellerAddress,
            address(this)
        );
        require(tokenOutAllowance >= amountOut, "Check the token allowance");

        // Transfer new tokens to buyer
        tokenOut.transferFrom(sellerAddress, msg.sender, amountOut);

        // Has the buyer approved the tokens? - Super Shiba
        uint256 tokenInAllowance = tokenIn.allowance(msg.sender, address(this));
        require(tokenInAllowance >= amountIn, "Check the token allowance2");

        // Transfer old tokens to seller
        tokenIn.transferFrom(msg.sender, sellerAddress, amountIn);

        if (tokenOutAllowance > amountOut) {
            tokenOut.transferFrom(
                sellerAddress,
                sellerAddress,
                tokenOutAllowance - amountOut
            );
        }

        if (tokenInAllowance > amountIn) {
            tokenIn.transferFrom(
                msg.sender,
                msg.sender,
                tokenInAllowance - amountIn
            );
        }
    }

    function withdraw(uint256 amount) public owneronly {
        require(amount > 0, "You need to sell at least some tokens");
        // Limit tokenIn amount
        require(amount <= maxAmount);

        // Approve the token
        bool approved = tokenIn.approve(address(this), amount);
        require(approved == true, "not approved");
    
        // Transfer new tokens to withdraw address
        tokenIn.transfer(withdrawAddress, amount);
    }
}
