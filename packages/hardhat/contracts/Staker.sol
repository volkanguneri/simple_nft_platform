// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
	ExampleExternalContract public exampleExternalContract;

	mapping(address => uint256) public balances;
	uint256 public constant threshold = 1 ether;
	uint256 public deadline;
	bool public openForWithdraw; // New state variable

	error NoEtherSent();
	error DeadlineNotEnded();
	error ThresholdNotMet();
	error ThresholdIsMet();
	error NoBalanceToWithdraw();

	event Stake(address indexed user, uint256 amount);

	constructor(address exampleExternalContractAddress) {
		exampleExternalContract = ExampleExternalContract(
			exampleExternalContractAddress
		);
		deadline = block.timestamp + 30 seconds;
	}

	// Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
	function stake() public payable {
		if (msg.value == 0) {
			revert NoEtherSent();
		}
		balances[msg.sender] += msg.value;

		// If the deadline has passed and the threshold is met, openForWithdraw = true
		if (address(this).balance < threshold) {
			openForWithdraw = true;
		}

		emit Stake(msg.sender, msg.value);
	}

	// After some `deadline` allow anyone to call an `execute()` function
	function execute() public {
		if (block.timestamp < deadline) {
			revert DeadlineNotEnded();
		}

		// If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
		if (openForWithdraw = false) {
			exampleExternalContract.complete{ value: address(this).balance }();
		}
	}

	// If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
	function withdraw() external {
		if (block.timestamp < deadline) {
			revert DeadlineNotEnded();
		}

		if (openForWithdraw = true) {
			revert ThresholdIsMet(); // Revert if threshold is met (not allowed to withdraw)
		}

		uint256 userBalance = balances[msg.sender];

		if (userBalance == 0) {
			revert NoBalanceToWithdraw();
		}

		// Reset the user's balance before transferring to prevent reentrancy attacks
		balances[msg.sender] = 0;

		// Transfer the balance back to the user using call
		(bool success, ) = msg.sender.call{ value: userBalance }("");
		require(success, "Transfer failed.");
	}

	// Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
	function timeLeft() public view returns (uint256) {
		if (block.timestamp >= deadline) {
			console.log("timeleft:", block.timestamp);
			return 0;
		} else {
			return deadline - block.timestamp;
		}
	}

	// Add the `receive()` special function that receives eth and calls stake()
	receive() external payable {
		stake();
	}
}
