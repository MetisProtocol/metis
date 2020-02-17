pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/access/Roles.sol";
import "./IMSC.sol";

/**
 * @dev implementation of MSC
 */
contract MSC is IERC777Recipient, IERC777Sender{
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
    address private _tokenAddr; //token contract address
    uint private lastStatusChange;
    uint private disputeRollBackDays;
    uint private numCommitted;
    uint private numWantedout;
    uint256 public pledgeAmount;
    uint public disputePeriod;
    address public disputeInitiator;

    ContractStatus public contractStatus;

    mapping(address => Pledge) parties;
    address[] public participantsArray;
    address[] public facilitatorsArray; 

    /**
     * @dev participants cannot be empty
     * @param participants list of participants
     * @param facilitators list of facilitators, who can resolve disputes
     * @param period period in days of time one can raise disputes after a participant requests the exit
     * @param tokenAddr token contract address
     * @param amount amount of pledge requred
     */
    constructor(
	    address[] memory participants,
	    address[] memory facilitators,
        uint period,
        address tokenAddr,
        uint256 amount
    )
    public
    {
        participantsArray = participants;
        facilitatorsArray = facilitators;
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

    /**
     * @dev commit funds to the contract. participants can keep committing after the pledge ammount is reached
     * @param amount amount of fund to commit
     * The sender must authorized this contract to be the operator of senders account before committing
     */
    function commit(uint256 amount) public {

        IERC777 erc777 = IERC777(_tokenAddr);
        Pledge memory p = parties[msg.sender];
        // Only participants are allowed
        require(amount > 0, "AMOUNT_NOT_GREATER_THAN_ZERO");
        require(_participants.has(msg.sender), "DOES_NOT_HAVE_PARTICIPANT_ROLE");
        require(erc777.balanceOf(msg.sender) >= amount, "INSUFFICIENT_BALANCE");
        require(erc777.isOperatorFor(address(this), msg.sender), "NOT_AUTHORIZED_AS_OPERATOR");
        
        p.value += amount;
        if (p.value >= pledgeAmount && p.status == ParticipantStatus.Pending) {
                p.status = ParticipantStatus.Committed;
                numCommitted++;
                if (numCommitted == participantsArray.length) {
                        contractStatus = ContractStatus.Effective;
                }
        }
        lastStatusChange = now;
        erc777.operatorSend(msg.sender, address(this), amount, "", "Pledge");
    }

    /**
     * @dev transfer pledge value from one participant to another
     * @param to target address
     * @param amount amount of fund to transfer
     * The sender must have enough fund pledged. The method does not trigger status changes.
     * The transaction is not allowed if the contract is in the middle of a dispute.
     */
    function send(address to, uint256 amount) public {

        Pledge memory p = parties[msg.sender];
        Pledge memory targetP = parties[to];

        // Only participants are allowed
        require(amount > 0, "AMOUNT_NOT_GREATER_THAN_ZERO");
        require(_participants.has(msg.sender), "DOES_NOT_HAVE_PARTICIPANT_ROLE");
        require(_participants.has(to), "TARGET_DOES_NOT_HAVE_PARTICIPANT_ROLE");
        require(contractStatus != ContractStatus.Dispute, "CONTRACT_IS_IN_DISPUTE");
        require(p.value >= amount, "INSUFFICIENT_BALANCE");
        
        p.value -= amount;
        targetP.value += amount;
        emit Transaction(msg.sender, msg.sender, to, amount, "", "Transfer");
    }

    /**
     * @dev withdraw the pledged fund
     * The sender must have enough fund pledged. Contract will be closed if all funds are withdrawn
     */
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
        if (erc777.balanceOf(address(this)) == p.value) {
                contractStatus = ContractStatus.Closed;
        }
        erc777.send(msg.sender,p.value, "Withdraw");

        p.value = 0;
        lastStatusChange = now;
    }
   
    /**
     * @dev signal a participant wants to exit
     * @param check a flag to indicate whether the call is just to check the exit status
     * once an exit is signaled, the contract will wait pledgePeriod * 1 days for other participants to react
     * if other participants also signal exits, the contract will change the status to complete and allow withdraws
     * the other participants can choose to dispute, which blocks the withdraws until the dispute is resolved
     * if no dispute is resolved after the pledge period expires, the contract will automatically set to complete
     * and open to withdraws.
     * if check is true, the call may still cause status update if the pledge period expires
     */
    function iwantout(bool check) public {
        Pledge memory p = parties[msg.sender];
        // Only participants are allowed
        require(_participants.has(msg.sender), "DOES_NOT_HAVE_PARTICIPANT_ROLE");
        require(check == true || contractStatus == ContractStatus.Effective, "STATUS_IS_NOT_EFFECTIVE");
        require(check == true || p.status == ParticipantStatus.Committed, "STATUS_NOT_IN_COMMITTED");
        
        if (check == false) {
                p.status = ParticipantStatus.Wantout;
                numWantedout++;
        }
        if (numWantedout == participantsArray.length) {
                contractStatus = ContractStatus.Completed;
                emit ContractClose(msg.sender, lastStatusChange, numWantedout, "All Aggreed");
        } else if (now >= lastStatusChange + disputePeriod * 1 days && contractStatus != ContractStatus.Dispute) {
                contractStatus = ContractStatus.Completed;
                emit ContractClose(msg.sender, lastStatusChange, numWantedout, "Dispute Expired");
        }
        if (check == false) {
                lastStatusChange = now;
        }
    }

    /** 
     * @dev raise a dispute
     * only one participant can raise the dispute. it will put the contract status to dispute, blocking all
     * further transactions.
     */
    function dispute() public {
        Pledge memory p = parties[msg.sender];
        // Only participants are allowed
        require(_participants.has(msg.sender), "DOES_NOT_HAVE_PARTICIPANT_ROLE");
        require(contractStatus == ContractStatus.Effective, "STATUS_IS_NOT_EFFECTIVE");
        require(p.status == ParticipantStatus.Committed, "STATUS_NOT_IN_COMMITTED");
        
        disputeInitiator = msg.sender;
        p.status = ParticipantStatus.Dispute;
        contractStatus = ContractStatus.Dispute;

        // store how many days spent since the exit was raised
        disputeRollBackDays = now - lastStatusChange;
        emit ContractDispute(msg.sender, lastStatusChange, "Initiated");
        lastStatusChange = now;
    }

    /** 
     * @dev cancel a dispute
     * the method also reset the status change. the original dispute period continues.
     */
    function withdrawDispute() public {
        Pledge memory p = parties[msg.sender];
        // Only participants are allowed
        require(_participants.has(msg.sender), "DOES_NOT_HAVE_PARTICIPANT_ROLE");
        require(disputeInitiator == msg.sender, "CALLER_DID_NOT_INITIATE_DISPUTE");
        require(contractStatus == ContractStatus.Dispute, "STATUS_IS_NOT_DISPUTE");
        require(p.status == ParticipantStatus.Dispute, "STATUS_NOT_IN_DISPUTE");
        
        p.status = ParticipantStatus.Committed;
        contractStatus = ContractStatus.Effective;
        emit ContractDispute(msg.sender, lastStatusChange, "Withdrawn");

        // restore the date so the dispute period continues after the withdraw
        lastStatusChange = now - disputeRollBackDays;
    }

    /** 
     * @dev resolve a dispute
     * @param participants the list of addresses of participants involved in the resolution
     * @param values the list of resolved values after the resolution
     * Only the facilitator can resolve a dispute.
     * The total amount of values cannot exceed the total funds pledged. The contract status will set to Completed,
     * allowing withdraws.
     */
    function resolveDispute(address[] memory participants, uint[] memory values) public {
        // Only participants are allowed
        require(_facilitators.has(msg.sender), "DOES_NOT_HAVE_FACILITATOR_ROLE");
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
    ) external {
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
       emit Transaction(operator, from, to, amount, userData, operatorData); 
    }
}
