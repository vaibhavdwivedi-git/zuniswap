//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

//Importing ERC20 interface
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//For every trading pair we will have seperate exchange contract
contract Exchange is ERC20 {
    //Address of token whose exchange we want to form- trading pair
    address public tokenAddress;

    //Saving address of token whose exchange we want to make
    //Added Functionality of liquidity provider tokens
    constructor(address _token) ERC20("Zuniswap-V1", "ZUNI-v1") {
        require(_token != address(0), "Invalid token address");
        tokenAddress = _token;
    }

    //Basic function to allow liquidity to the exchange pool
    //We send some ether and token amount we want to deposit
    function addLiquidity(
        uint256 _tokenAmount
    ) public payable returns (uint256) {
        if (getReserve() == 0) {
            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), _tokenAmount);

            // Will send same number of lp token as eth deposited
            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);

            return liquidity;
        } else {
            //Subtracting amount of eth added by msg.sender
            uint ethReserve = address(this).balance - msg.value;
            uint tokenReserve = getReserve();

            uint tokenAmount = (msg.value * tokenReserve) / ethReserve;
            require(_tokenAmount >= tokenAmount, "Insufficient Token Amount");

            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), tokenAmount);

            uint256 liquidity = (msg.value * totalSupply()) / ethReserve;
            _mint(msg.sender, liquidity);

            return liquidity;
        }
    }

    //Remove Liquidity Token
    function removeLiquidity(
        uint256 _amount
    ) public returns (uint256, uint256) {
        require(_amount > 0, "invalid amount");

        uint256 ethAmount = (address(this).balance * _amount) / totalSupply();
        uint256 tokenAmount = (getReserve() * _amount) / totalSupply();

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

        return (ethAmount, tokenAmount);
    }

    //Tell amount of tokens are in contract deposit
    function getReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    //Give amount of token we will get by giving eth we want to sold
    function getTokenAmount(uint _ethSold) public view returns (uint256) {
        require(_ethSold > 0, "ethSold is too small");
        uint256 tokenReserve = getReserve();
        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    //Give amount of eth we will get by giving token we want to sold
    function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
        require(_tokenSold > 0, "tokenSold is too small");
        uint256 tokenReserve = getReserve();
        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }

    //Allow eth to token swap
    function ethToTokenSwap(uint256 _minTokens) public payable {
        uint256 tokenReserve = getReserve();

        uint256 tokensBought = getAmount(
            msg.value,
            address(this).balance,
            tokenReserve
        );

        require(tokensBought >= _minTokens, "Insufficient Output Amount");

        IERC20(tokenAddress).transfer(msg.sender, tokensBought);
    }

    //Allow token to eth swap
    function tokenToEthSwap(uint _tokensSold, uint256 _minEth) public {
        uint256 tokenReserve = getReserve();

        uint ethBought = getAmount(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );

        require(ethBought >= _minEth, "Insufficient Output Amount");

        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );

        payable(msg.sender).transfer(ethBought);
    }

    //Tell the amount of token/ether we recieve when we swap ether/token
    // We will take 1% fees
    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Invalid Reserves");

        uint256 inputAmountWithFee = inputAmount * 99;

        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;
    }
}
