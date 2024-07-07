pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
	YourToken public yourToken;
	uint256 public constant tokensPerEth = 100;

	event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
	event SellTokens(
		address seller,
		uint256 amountOfTokens,
		uint256 amountOfEth
	);

	error InsufficientTokenBalance();
	error VendorHasInsufficientETHBalance();
	error ApproveBefore();
	error InsufficiantAllowance();

	constructor(address tokenAddress) {
		yourToken = YourToken(tokenAddress);
	}

	function buyTokens() external payable {
		uint256 _amountOfTokens = msg.value * tokensPerEth;
		yourToken.transfer(msg.sender, _amountOfTokens);
		emit BuyTokens(msg.sender, msg.value, _amountOfTokens);
	}

	function withdraw() external onlyOwner {
		uint256 balance = address(this).balance;
		(bool success, ) = owner().call{ value: balance }("");
		require(success, "Withdraw failed");
	}

	// function approve(address spender, uint256 amount) external override returns (bool) {

	// }

	function sellTokens(uint256 amount) external {
		// Check if the seller contract has enough token to sell
		if (yourToken.balanceOf(msg.sender) < amount) {
			revert InsufficientTokenBalance();
		}

		// ETH amount to pay to the seller
		uint256 ethAmount = amount / tokensPerEth;

		// Check if the vendor contract has enough ETH to pay for the tokens
		if (address(this).balance < ethAmount) {
			revert VendorHasInsufficientETHBalance();
		}

		if (!yourToken.approve(address(this), amount)) {
			revert ApproveBefore();
		}

		if (yourToken.allowance(msg.sender, address(this)) < amount) {
			revert InsufficiantAllowance();
		}

		// Transfer tokens from sender to the contract
		yourToken.transferFrom(msg.sender, address(this), amount);

		// Send ETH from contract to the sender
		(bool success, ) = msg.sender.call{ value: ethAmount }("");
		require(success, "ETH transfer failed");

		emit SellTokens(msg.sender, amount, ethAmount);
	}

	// Special receive function to accept ETH
	receive() external payable {}
}
