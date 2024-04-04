// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract UserRegistry {
    enum Role {
        Worker,
        Requester,
        Both
    }
    enum Status {
        Pending,
        Accepted,
        Rejected
    }
    struct UserInfo {
        Role role;
        Status status;
        bytes32 userVerificationHash;
    }
    mapping(address => UserInfo) userAddressToInfo;
    address[] userAddresses;
    mapping(address => address[]) userJobAddresses;
    mapping(address => address[]) userPlatformAddresses;

    event UserRegistered(address indexed userAddress);

    function registerUser(
        address _userAddress,
        Role _role,
        bytes32 _verificationHash
    ) public {
        userAddressToInfo[_userAddress] = UserInfo(
            _role,
            Status.Pending,
            _verificationHash
        );
        userAddresses.push(_userAddress);

        emit UserRegistered(_userAddress);
    }

    function getUserInfo(
        address _userAddress
    ) public view returns (UserInfo memory) {
        return userAddressToInfo[_userAddress];
    }

    function getAllUserAddresses() public view returns (address[] memory) {
        return userAddresses;
    }
}
