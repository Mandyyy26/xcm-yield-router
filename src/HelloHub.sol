// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract HelloHub {
    string public message;
    address public deployer;
    uint256 public deployedAt;

    event MessageUpdated(string oldMsg, string newMsg, address by);

    constructor(string memory _message){
        message = _message;
        deployer = msg.sender;
        deployedAt = block.timestamp;
    }

    function updateMessage(string calldata _newMessage) public {
        emit MessageUpdated(message, _newMessage, msg.sender);
        message = _newMessage;
    }

    function getInfo() external view returns(string memory _message, address _deployer, uint256 _deployedAt, uint256 _chainId){
        uint256 id;
        assembly { id := chainid() }
        return (message, deployer, deployedAt, id);
    }

}
