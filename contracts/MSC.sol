pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/access/Roles.sol";

contract MSC is ERC777Recipient{
    using Roles for Roles.Role;
    enum ContractStatus { Pending, Effective, Completed, Dispute, Closed }
    enum ParticipantStatus { Pending,Committed, Wantout, Completed, Dispute, Closed }
    event Transaction (address operator, address from, address to, uint256 amount, bytes msg1, bytes msg2);
    event ContractClose(address initiator, uint lastStatusChange, uint numWantedout, bytes msg);
    event ContractDispute(address operator, uint lastStatusChange, bytes msg);
    event DisputeResolution(address facilitator, uint lastStatusChange, address[] participants, uint[] values);
    
    struct Pledge {
        uint256 value;
        ParticipantStatus status;
    }

    Roles.Role private _participants;
    Roles.Role private _facilitators;
    address _tokenAddr private;
    uint lastStatusChange private;
    uint numCommitted private;
    uint numWantedout private;
    uint256 pledgeAmount public;
    uint disputePeriod public;
    address disputeInitiator public;

    ContractStatus public contractStatus;

    mapping(address => Pledge) parties;
    address[] participantsArray public;
    address[] facilitatorsArray public; 

    constructor(
	    address[] memory participants,
	    address[] memory facilitators,
        uint period,
        address memory tokenAddr,
        uint256 amount
    )
    public
    {
        participantsArray = participants;
        facilitatorArray = facilitatos;
        for (uint256 i = 0; i < participants.length; ++i) {
	        _participants.add(participants[i]);
        }
	    for (uint256 i = 0; i < facilitators.length; ++i) {
	        _facilitators.add(facilitators[i]);
	    }
        _tokenAddr = tokenAddr;
        pledgeAmount = amount;
        disputePeriod = period;
    }

    function commit(uint256 amount) public {

        IERC777 erc777 = IERC777(_tokenAddr);
        Pledge memory p = parties[msg.sender];
        // Only participants are allowed
        require(amount > 0, "AMOUNT_NOT_GREATER_THAN_ZERO");
        require(_participants.has(msg.sender), "DOES_NOT_HAVE_PARTICIPANT_ROLE");
        require(p.status == ParticipantStatus.Pending, "STATUS_NOT_IN_PENDING");
        require(erc777.balanceOf(msg.sender) >= amount, "INSUFFICIENT_BALANCE");
        require(erc777.isOperatorFor(address(this), msg.sender), "NOT_AUTHORIZED_AS_OPERATOR");
        
        p.value += amount;
        if (p.value >= pledgeAmount) {
                p.status = ParticipantStatus.Committed;
                numCommitted++;
                if (numCommited == participantsArray.length) {
                        contractStatus = ContractStatus.Effective;
                }
        }
        lastStatusChange = now;
        erc777.operatorSend(msg.sender, address(this), amount, "", "Pledge");
    }

    function withdraw() public {
        IERC777 erc777 = IERC777(_tokenAddr);
        Pledge memory p = parties[msg.sender];
        // Only participants are allowed
        require(contractStatus == ContractStatus.Completed, "STATUS_IS_NOT_COMPLETED");
        require(p.value > 0, "AMOUNT_NOT_GREATER_THAN_ZERO");
        require(_participants.has(msg.sender), "DOES_NOT_HAVE_PARTICIPANT_ROLE");
        require(p.status != ParticipantStatus.Pending, "STATUS_IN_PENDING");
        require(erc777.balanceOf(address(this)) >= p.value, "INSUFFICIENT_BALANCE");
        
        p.status = ParticipantStatus.Closed;
        if (erc777.balanceOf(address(this) == p.value)) {
                ContractStatus = ContractStatus.Closed;
        }
        p.value = 0;
        lastStatusChange = now;
        erc777.send(msg.sender,amount, "", "Withdraw");
    }
   
    function iwantout(bool check) public {

        IERC777 erc777 = IERC777(_tokenAddr);
        Pledge memory p = parties[msg.sender];
        // Only participants are allowed
        require(_participants.has(msg.sender), "DOES_NOT_HAVE_PARTICIPANT_ROLE");
        require(check == true || contractStatus == ContractStatus.Effective, "STATUS_IS_NOT_EFFECTIVE");
        require(check == true || p.status == ParticipantStatus.Committed, "STATUS_NOT_IN_COMMITTED");
        
        if (check == false) {
                p.status = ParticipantStatus.Wantout;
                numWantedout++;
        }
        if (numWantedout == participantsArray.length)
                ContractStatus = ContractStatus.Completed;
                emit ContractClose(msg.sender, lastStatusChange, numWantedout, "All Aggreed");
        } else if (now >= lastStatusChange + disputePeriod * 1 day && ContractStatus != ContractStatus.Dispute) {
                ContractStatus = ContractStatus.Completed;
                emit ContractClose(msg.sender, lastStatusChange, numWantedout, "Dispute Expired");
        }
        if (check == false) {
                lastStatusChange = now;
        }
    }

    function dispute() public {
        Pledge memory p = parties[msg.sender];
        // Only participants are allowed
        require(_participants.has(msg.sender), "DOES_NOT_HAVE_PARTICIPANT_ROLE");
        require(contractStatus == ContractStatus.Effective, "STATUS_IS_NOT_EFFECTIVE");
        require(p.status == ParticipantStatus.Committed, "STATUS_NOT_IN_COMMITTED");
        
        disputeInitiator = msg.sender;
        p.status = ParticipantStatus.Dispute;
        contractStatus = ContractStatus.Dispute;
        emit ContractDispute(msg.sender, lastStatusChange, "Initiated");
        lastStatusChange = now;
    }

    function withdrawDispute() public {
        Pledge memory p = parties[msg.sender];
        // Only participants are allowed
        require(_participants.has(msg.sender), "DOES_NOT_HAVE_PARTICIPANT_ROLE");
        require(disputeInitiator == msg.sender, "CALLER_DID_NOT_INITIATE_DISPUTE");
        require(contractStatus == ContractStatus.Dispute, "STATUS_IS_NOT_DISPUTE");
        require(p.status == ParticipantStatus.Dispute, "STATUS_NOT_IN_DISPUTE");
        
        p.status = ParticipantStatus.Commited;
        contractStatus = ContractStatus.Effective;
        emit ContractDispute(msg.sender, lastStatusChange, "Withdrawn");
        lastStatusChange = now;
    }

    function resolveDispute(address[] memory participants, uint[] memory values) public {
        // Only participants are allowed
        require(_facilitator.has(msg.sender), "DOES_NOT_HAVE_FACILITATOR_ROLE");
        require(contractStatus == ContractStatus.Dispute, "STATUS_IS_NOT_DISPUTE");
        uint256 totalvalue = 0; 
        contractStatus = ContractStatus.Completed;
        for (uint256 i = 0; i < participants.length; ++i) {
	        Pledge memory p = parties[participants[i]];
            p.status = ParticipantStatus.Completed;
            p.value = values[i];
            totalvalue += p.value;
        }
        IERC777 erc777 = IERC777(_tokenAddr);

        // just to make sure the resolution is valid
        require(erc777.balanceOf(address(this)) >= totalvalue, "INSUFFICIENT_BALANCE");

        emit DisputeResolution(msg.sender, lastStatusChange, participants, values);
        lastStatusChange = now;
    }

    function tokensReceived (
            address operator,
            address from,
            address to,
            uint256 amount,
            bytes calldata userData,
            bytes calldata operatorData
    ) {
       emit Transaction(operator, from, to, amount, userData, operatorData); 
    }

    function tokensToSend(
            address operator,
            address from,
            address to,
            uint256 amount,
            bytes calldata userData,
            bytes calldata operatorData
    ) {
       emit Transaction(operator, from, to, amount, userData, operatorData); 
    }
}
