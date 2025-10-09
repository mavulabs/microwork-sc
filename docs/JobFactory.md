# Solidity API

## JobFactory

### State Variables

#### jobContracts

Array of addresses of deployed job contracts.

```solidity
address[] jobContracts
```

### Events

#### JobRegistered

```solidity
event JobRegistered(address jobContract)
```

### Functions

#### registerJob

Registers a new job contract with specified parameters and emits a JobRegistered event.

```solidity
function registerJob(bytes jobDescription, bytes32 typeOfJob, uint256 deadline, address _cusdAddress, address _mavuCoinAddress, address _scoreAddress, uint256 _cusdRewardAmount, uint256 _mavuRewardAmount, uint256 _scoreRewardAmount) public
```

#### getCompletedJobs

Returns an array of addresses representing completed job contracts.

```solidity
function getCompletedJobs() public view returns (address[])
```

#### getInProgressJobs

Returns an array of addresses representing job contracts in progress.

```solidity
function getInProgressJobs() public view returns (address[])
```
