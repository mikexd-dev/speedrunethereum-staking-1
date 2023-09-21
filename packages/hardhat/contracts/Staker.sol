// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  event Stake(address staker, uint256 amount);

  ExampleExternalContract public exampleExternalContract;
  // track individual balances with a mapping
  mapping (address => uint256) public balances;

  // track constant threshold at 1 ether
  uint256 public constant threshold = 1 ether;

  bool openForWithdraw = false;

  // set deadline of block.timestamp + 30 seconds
  uint256 public deadline = block.timestamp + 72 hours;

  // create a modifier called notCompleted that checks if the contract has not been completed yet
  modifier notCompleted() {
    require(exampleExternalContract.completed() == false, "Contract has been completed");
    _;
  }

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
  function stake() public payable {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public notCompleted {
    require(timeLeft() == 0, "Deadline has not passed");
    if(address(this).balance >= threshold){
      exampleExternalContract.complete{value: address(this).balance}();
    } else{
      openForWithdraw = true;
      // revert("Threshold has not been met, open for withdraw");
    }    
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  function withdraw() public notCompleted {
    // require(timeLeft() == 0, "Deadline has not passed");
    // require(address(this).balance < threshold, "Threshold has been met");
    require(openForWithdraw == true, "Contract is not open for withdraw");
    require(balances[msg.sender] > 0, "No balance to withdraw");

    balances[msg.sender] = 0;
    payable(msg.sender).transfer(balances[msg.sender]);
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns(uint256){
    if(block.timestamp >= deadline){
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
