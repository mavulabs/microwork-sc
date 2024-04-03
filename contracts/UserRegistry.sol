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
    mapping(address => UserInfo) public userAddressToInfo;
    address[] public userAddresses;
    mapping(address => address[]) public userJobAddresses;
    mapping(address => address[]) public userPlatformAddresses;

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
}
