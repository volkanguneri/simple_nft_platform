// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
	ExampleExternalContract public exampleExternalContract;

	mapping(address => uint256) public balances;
	uint256 public constant threshold = 1 ether;
	uint256 public deadline;

	bool public openForWithdraw;
	bool public executed;

	error NoEtherInBalance();

	event Stake(address indexed user, uint256 amount);

	constructor(address exampleExternalContractAddress) {
		exampleExternalContract = ExampleExternalContract(
			exampleExternalContractAddress
		);
		deadline = block.timestamp + 72 days;
	}

	// Modifier to check if the contract has not been completed
	modifier notCompleted() {
		require(
			!exampleExternalContract.completed(),
			"Contract already completed."
		);
		_;
	}

	// Modifier to check if the deadline has passed
	modifier beforeDeadline() {
		require(block.timestamp < deadline, "Staking period has ended.");
		_;
	}

	// Modifier to check if the deadline has passed
	modifier afterDeadline() {
		require(block.timestamp >= deadline, "Deadline not reached yet.");
		_;
	}
	// Modifier to check if the deadline has passed
	modifier Executed() {
		require(executed, "Execute before withdraw");
		_;
	}
	// Modifier to check if the deadline has passed
	modifier OpenForWithdraw() {
		require(openForWithdraw, "Not open for withdraw");
		_;
	}

	// Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
	function stake() public payable beforeDeadline {
		if (msg.value == 0) {
			revert NoEtherInBalance();
		}
		balances[msg.sender] += msg.value;
		emit Stake(msg.sender, msg.value);
	}

	// After some `deadline` allow anyone to call an `execute()` function
	function execute() public notCompleted afterDeadline {
		executed = true;

		if (address(this).balance == 0) {
			revert NoEtherInBalance();
		}

		if (address(this).balance < threshold) {
			openForWithdraw = true;
		} else {
			exampleExternalContract.complete{ value: address(this).balance }();
		}
	}

	// If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
	function withdraw()
		external
		notCompleted
		afterDeadline
		Executed
		OpenForWithdraw
	{
		uint256 userBalance = balances[msg.sender];
		if (userBalance == 0) {
			revert NoEtherInBalance();
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
