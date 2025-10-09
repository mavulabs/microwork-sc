# Solidity API

## UserRegistry

### State Variables

#### Role

Different types of role a user can have.

```solidity
enum Role {
  Worker,
  Requester,
  WorkerAndRequester,
  Reviewer
}
```

#### Status

Different types of status of user-onboarding.

```solidity
enum Status {
  Pending,
  Accepted,
  Rejected
}
```

#### UserInfo

Information of a user.

```solidity
struct UserInfo {
  enum UserRegistry.Role role;
  enum UserRegistry.Status status;
}
```

#### userAddressToInfo

Mapping from user addresses to UserInfo struct containing role and status.

```solidity
mapping(address => struct UserRegistry.UserInfo) userAddressToInfo
```

#### userAddresses

Array storing all registered user addresses.

```solidity
address[] userAddresses
```

#### userJobAddresses

Mapping from user addresses to an array of job contract addresses associated with the user.

```solidity
mapping(address => address[]) userJobAddresses
```

#### userPlatformAddresses

Mapping from user addresses to an array of platform contract addresses associated with the user.

```solidity
mapping(address => address[]) userPlatformAddresses
```

### Events

#### UserRegistered

```solidity
event UserRegistered(address userAddress)
```

### Functions

#### registerUser

Registers a new user with the specified role. Emits a UserRegistered event.

```solidity
function registerUser(address _userAddress, enum UserRegistry.Role _role) public
```

#### getUserInfo

Returns the UserInfo struct for a given user address.

```solidity
function getUserInfo(address _userAddress) public view returns (struct UserRegistry.UserInfo)
```

#### getAllUserAddresses

Returns an array of all registered user addresses.

```solidity
function getAllUserAddresses() public view returns (address[])
```

#### getAllJobsOfAUser

Returns an array of job contract addresses associated with a user.

```solidity
function getAllJobsOfAUser(address _userAddress) public view returns (address[])
```

#### changeUserRole

Changes the role of a user.

```solidity
function changeUserRole(address _userAddress, enum UserRegistry.Role _newRole) external
```

#### changeUserStatus

Changes the status of a user.

```solidity
function changeUserStatus(address _userAddress, enum UserRegistry.Role _newStatus) external
```

#### changeUserVerificationHash

Changes the verification hash of a user.

```solidity
function changeUserVerificationHash(address _userAddress, enum UserRegistry.Role _newVerificationHash) external
```
