# Solidity API

## UserRegistry

### Role

```solidity
enum Role {
  Worker,
  Requester,
  WorkerAndRequester,
  Reviewer
}
```

### Status

```solidity
enum Status {
  Pending,
  Accepted,
  Rejected
}
```

### UserInfo

```solidity
struct UserInfo {
  enum UserRegistry.Role role;
  enum UserRegistry.Status status;
}
```

### userAddressToInfo

```solidity
mapping(address => struct UserRegistry.UserInfo) userAddressToInfo
```

### userAddresses

```solidity
address[] userAddresses
```

### userJobAddresses

```solidity
mapping(address => address[]) userJobAddresses
```

### userPlatformAddresses

```solidity
mapping(address => address[]) userPlatformAddresses
```

### UserRegistered

```solidity
event UserRegistered(address userAddress)
```

### registerUser

```solidity
function registerUser(address _userAddress, enum UserRegistry.Role _role) public
```

### getUserInfo

```solidity
function getUserInfo(address _userAddress) public view returns (struct UserRegistry.UserInfo)
```

### getAllUserAddresses

```solidity
function getAllUserAddresses() public view returns (address[])
```

### getAllJobsOfAUser

```solidity
function getAllJobsOfAUser(address _userAddress) public view returns (address[])
```

### changeUserRole

```solidity
function changeUserRole(address _userAddress, enum UserRegistry.Role _newRole) external
```

### changeUserStatus

```solidity
function changeUserStatus(address _userAddress, enum UserRegistry.Role _newStatus) external
```

### changeUserVerificationHash

```solidity
function changeUserVerificationHash(address _userAddress, enum UserRegistry.Role _newVerificationHash) external
```

