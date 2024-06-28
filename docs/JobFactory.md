# Solidity API

## JobFactory

### jobContracts

```solidity
address[] jobContracts
```

### JobRegistered

```solidity
event JobRegistered(address jobContract)
```

### registerJob

```solidity
function registerJob(bytes jobDescription, bytes32 typeOfJob, uint256 deadline, address _cusdAddress, address _mavuCoinAddress, address _scoreAddress, uint256 _cusdRewardAmount, uint256 _mavuRewardAmount, uint256 _scoreRewardAmount) public
```

### getCompletedJobs

```solidity
function getCompletedJobs() public view returns (address[])
```

### getInProgressJobs

```solidity
function getInProgressJobs() public view returns (address[])
```

