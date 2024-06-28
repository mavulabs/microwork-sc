# Solidity API

## JobInfo

### cusdToken

```solidity
contract IERC20 cusdToken
```

### mavuToken

```solidity
contract IERC20 mavuToken
```

### scoreToken

```solidity
contract IERC20 scoreToken
```

### cusdRewardAmount

```solidity
uint256 cusdRewardAmount
```

### mavuRewardAmount

```solidity
uint256 mavuRewardAmount
```

### scoreRewardAmount

```solidity
uint256 scoreRewardAmount
```

### jobDescription

```solidity
bytes jobDescription
```

### typeOfJob

```solidity
bytes32 typeOfJob
```

### deadline

```solidity
uint256 deadline
```

### tasks

```solidity
uint256[] tasks
```

### jobStatus

```solidity
bool jobStatus
```

### TaskInfo

```solidity
struct TaskInfo {
  address taskAssignee;
  uint256 assignmentEndTime;
  uint256 taskStatus;
}
```

### taskIdToInfo

```solidity
mapping(uint256 => struct JobInfo.TaskInfo) taskIdToInfo
```

### AssigneeChanged

```solidity
event AssigneeChanged(address newAssignedTo)
```

### DeadlineUpdated

```solidity
event DeadlineUpdated(uint256 newDeadline)
```

### TaskCreated

```solidity
event TaskCreated(uint256 taskId, address assignee)
```

### TaskAssigned

```solidity
event TaskAssigned(uint256 taskId, address assignee)
```

### constructor

```solidity
constructor(bytes _jobDescription, bytes32 _typeOfJob, uint256 _deadline, address _cusdAddress, address _mavuCoinAddress, address _scoreAddress, uint256 _cusdRewardAmount, uint256 _mavuRewardAmount, uint256 _scoreRewardAmount) public
```

### getJobInfo

```solidity
function getJobInfo() public view returns (bytes, bool, bytes32, uint256, uint256, uint256, uint256)
```

### startTask

```solidity
function startTask(address _assignedTo, uint256 _deadline, uint256 _taskStatus) public
```

### getTaskInfo

```solidity
function getTaskInfo(uint256 _taskId) public view returns (struct JobInfo.TaskInfo)
```

### updateTaskStatus

```solidity
function updateTaskStatus(uint256 _taskId, uint256 _statusNo) external
```

0 = Not assigned, 1 = Assigned, 2 = In progress , 3 = Completed, 4 = In review process,
 5 = Reviewed & Successful, 6 = Reviewed & Require modification, 7 = Reviewed & Failed

### sendRewards

```solidity
function sendRewards(address _userAddress, uint256 _taskId) internal
```

### setRewardsAmount

```solidity
function setRewardsAmount(uint256 _cusdRewardAmount, uint256 _mavuRewardAmount, uint256 _scoreRewardAmount) external
```

