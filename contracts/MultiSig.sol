pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/access/Roles.sol";

/**
 * @dev implementation of MSC
 */
contract MultiSig is IERC777Recipient, IERC777Sender{
    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    using Roles for Roles.Role;

    event Propose (address operator, address to, uint256 amount, bytes msg1, bytes msg2);
    event Transaction (address operator, address from, address to, uint256 amount, bytes msg1, bytes msg2);
    
    struct Proposal{
        uint256 value; 
        mapping(address => bool) approvals;
        uint256 numApproves;
    }

    Roles.Role private _participants;
    address private _tokenAddr; //token contract address
    IERC777 private _token;

    mapping(address => Proposal) public proposals;
    address[] public participantsArray;

    /**
     * @dev participants cannot be empty
     * @param participants list of participants
     * @param tokenAddr token contract address
     */
    constructor(
	    address[] memory participants,
        address tokenAddr
    )
    public
    {
        _tokenAddr = tokenAddr;
        _token = IERC777(tokenAddr);
        _erc1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));

        participantsArray = participants;
        for (uint256 i = 0; i < participants.length; ++i) {
	        _participants.add(participants[i]);
            _token.authorizeOperator(participants[i]);
        }
    }

    /**
     * @dev propose a transfer
     * if all participants submitted the same proposal, the proposal is approved. the token transfer will be executed
     * send a proposal with a different amount will override the previous one and reset the approvals
     */
    function _propose(address operator, address to, uint256 amount, bytes memory usermsg) private {
        Proposal storage p = proposals[to];
        // Only participants are allowed
        require(_participants.has(operator), "DOES_NOT_HAVE_PARTICIPANT_ROLE");
        require(amount > 0, "AMOUNT_NOT_GREATER_THAN_ZERO");
        require(_token.balanceOf(address(this)) >= amount, "INSUFFICIENT_BALANCE");

        // if someone propose a new amount, override
        if (p.value != amount) {
           for (uint256 i = 0; i < participantsArray.length; ++i) {
              // clear the approval
              p.approvals[participantsArray[i]] = false;
           }
           //init the rest;
           p.numApproves = 1;
           p.approvals[operator] = true;
           p.value = amount;
           emit Propose (operator, to, amount, "New Proposal", usermsg);
        } else {
                if (p.approvals[operator] == false) {
                        p.numApproves++;
                        p.approvals[operator] = true;
                        emit Propose (operator, to, amount, "Approve", usermsg);
                }
        }

        if (p.numApproves == participantsArray.length) {
                _token.send(to, amount, "Approved Transfer");
        }
    }
    function propose(address to, uint256 amount, bytes memory usermsg) public{
            _propose(msg.sender, to, amount, usermsg);
    }
   
    function tokensReceived (
            address operator,
            address from,
            address to,
            uint256 amount,
            bytes calldata userData,
            bytes calldata operatorData
    ) external {
       require(msg.sender == _tokenAddr, "Invalid token");

       emit Transaction(operator, from, to, amount, userData, operatorData); 
    }

    function tokensToSend (
            address operator,
            address from,
            address to,
            uint256 amount,
            bytes calldata userData,
            bytes calldata operatorData
    ) external {
       require(_token.balanceOf(address(this)) >= amount, "INSUFFICIENT_BALANCE");
       require(amount > 0, "AMOUNT_IS_ZERO");
       require(from == address(this), "SOURCE_IS_NOT_MYSELF");
       require(msg.sender == _tokenAddr, "Invalid token");
       
       Proposal storage p = proposals[to];

       require(p.numApproves == participantsArray.length, "INCOMPLETE_APPROVAL");
       require(p.value == amount, "VALUE_UNMATCHED_WITH_PROPOSAL");

       for (uint256 i = 0; i < participantsArray.length; ++i) {
              require(p.approvals[participantsArray[i]], "UNAPPROED_BY_SOMEONE");
              // clear the approval
              p.approvals[participantsArray[i]] = false;
       }
       //clear the rest;
       p.numApproves = 0;
       p.value = 0;
       
       emit Transaction(operator, from, to, amount, userData, operatorData); 
    }
}
