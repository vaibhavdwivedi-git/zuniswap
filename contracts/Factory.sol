//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

//Importing Exchange Contract
import "./Exchange.sol";

//This is to keep eye on different exchanges also create them
//Also enable token-tokeen swap
contract Factory {
    //Registry of each token address with its exchange address as each exchange swap only one token with ether
    mapping(address => address) public tokenToExchange;

    //This function is to create exchange taking token address
    function createExchange(address _tokenAddress) public returns (address) {
        require(_tokenAddress != address(0), "Invalid Token Address");
        require(
            tokenToExchange[_tokenAddress] == address(0),
            "Exchange Already Exists"
        );

        Exchange exchange = new Exchange(_tokenAddress);
        tokenToExchange[_tokenAddress] = address(exchange);

        return address(exchange);
    }

    //Giving exchange address in return of token address
    function getExchange(address _tokenAddress) public view returns (address) {
        return tokenToExchange[_tokenAddress];
    }
}
