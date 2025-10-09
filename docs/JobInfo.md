# Solidity API

## JobInfo

### State Variables

#### cusdToken

Instance of the cUSD token contract.

```solidity
contract IERC20 cusdToken
```

#### mavuToken

Instance of the MAVU token contract.

```solidity
contract IERC20 mavuToken
```

#### scoreToken

Instance of the SCORE token contract.

```solidity
contract IERC20 scoreToken
```

#### cusdRewardAmount

Amount of cUSD reward for completing the job.

```solidity
uint256 cusdRewardAmount
```

#### mavuRewardAmount

Amount of MAVU token reward for completing the job.

```solidity
uint256 mavuRewardAmount
```

#### scoreRewardAmount

Amount of SCORE token reward for completing the job.

```solidity
uint256 scoreRewardAmount
```

#### jobDescription

Description of the job.

```solidity
bytes jobDescription
```

#### typeOfJob

Type of the job.

```solidity
bytes32 typeOfJob
```

#### deadline

Deadline timestamp for completing the job.

```solidity
uint256 deadline
```

#### tasks

Array holding task IDs associated with the job.

```solidity
uint256[] tasks
```

#### jobStatus

Status of the job (true for in progress, false for done).

```solidity
bool jobStatus
```

#### TaskInfo

Information of a task.

```solidity
struct TaskInfo {
  address taskAssignee;
  uint256 assignmentEndTime;
  uint256 taskStatus;
}
```

#### taskIdToInfo

Mapping from task ID to TaskInfo struct containing task details.

```solidity
mapping(uint256 => struct JobInfo.TaskInfo) taskIdToInfo
```

### Events

#### AssigneeChanged

```solidity
event AssigneeChanged(address newAssignedTo)
```

#### DeadlineUpdated

```solidity
event DeadlineUpdated(uint256 newDeadline)
```

#### TaskCreated

```solidity
event TaskCreated(uint256 taskId, address assignee)
```

#### TaskAssigned

```solidity
event TaskAssigned(uint256 taskId, address assignee)
```

### Functions

#### constructor

Initializes the contract with job details and reward parameters.

```solidity
constructor(bytes _jobDescription, bytes32 _typeOfJob, uint256 _deadline, address _cusdAddress, address _mavuCoinAddress, address _scoreAddress, uint256 _cusdRewardAmount, uint256 _mavuRewardAmount, uint256 _scoreRewardAmount) public
```

#### getJobInfo

Returns job details including description, status, type, and deadline.

```solidity
function getJobInfo() public view returns (bytes, bool, bytes32, uint256, uint256, uint256, uint256)
```

#### startTask

Starts a new task associated with the job.

```solidity
function startTask(address _assignedTo, uint256 _deadline, uint256 _taskStatus) public
```

#### getTaskInfo

Returns details of a specific task identified by its ID.

```solidity
function getTaskInfo(uint256 _taskId) public view returns (struct JobInfo.TaskInfo)
```

#### updateTaskStatus

Updates the status of a task and potentially sends rewards if the task is completed successfully.

```solidity
function updateTaskStatus(uint256 _taskId, uint256 _statusNo) external
```

0 = Not assigned, 1 = Assigned, 2 = In progress , 3 = Completed, 4 = In review process,
5 = Reviewed & Successful, 6 = Reviewed & Require modification, 7 = Reviewed & Failed

#### sendRewards

Sends rewards to the task assignee upon successful task completion.

```solidity
function sendRewards(address _userAddress, uint256 _taskId) internal
```

#### setRewardsAmount

Sets new reward amounts for cUSD, MAVU, and SCORE tokens.

```solidity
function setRewardsAmount(uint256 _cusdRewardAmount, uint256 _mavuRewardAmount, uint256 _scoreRewardAmount) external
```
