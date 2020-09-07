pragma solidity ^0.5.0;

import "@openzeppelin/contracts/access/Roles.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IMSC.sol";
import "./IDAC.sol";

/**
 * @dev implementation of MSC
 */
contract MSCMulti is Ownable {
    using SafeMath for uint256;

    using Roles for Roles.Role;
    enum ContractStatus { Pending, SemiCommitted, Effective, Completed, Dispute, Requested, Closed }
    enum ParticipantStatus { Pending,Committed, Wantout, Completed, Dispute, Closed }

    event Transaction (address operator, address from, address to, uint256 amount, bytes msg1, bytes msg2);
    event ContractClose(address initiator, uint lastStatusChange, uint numWantedout, bytes msg);
    event ContractDispute(address operator, uint lastStatusChange, bytes msg);
    event ResolutionRequested(address initiator, uint lastStatusChange);
    event DisputeResolution(address facilitator, uint lastStatusChange, address[] participants, uint[] values);
    
    struct Pledge {
        uint256 value; 
        uint256 stakedValue; 
        ParticipantStatus status;
    }

    Roles.Role private _participants;
    address public _starter; // starter of the contract
    address public _taker;
    address private _tokenAddr; //token contract address
    uint private lastStatusChange;
    uint private disputeRollBackDays;
    uint private numCommitted;
    uint private numWantedout;
    uint256 public pledgeAmount;
    uint256 public _prizeAmount;
    uint256 public _afterTax; //afterTax value of the current transaction.
    uint public disputePeriod;
    uint public numWithdraws;
    address public disputeInitiator;
    address payable public facilitator;
    address public _dacAddr; // address to the dac

    ContractStatus public contractStatus;

    mapping(address => Pledge) public parties;
    mapping(address => bool) public withdraworder;
    address[] public participantsArray;

    /**
     * @dev participants cannot be empty
     * @param participants list of participants
     * @param facilitator_param address of the facilitator, who can resolve disputes. must be payable
     * @param period period in days of time one can raise disputes after a participant requests the exit
     * @param tokenAddr token contract address
     */
    constructor(
        address starter,
	    address[] memory participants,
	    address payable facilitator_param,
        uint period,
        address tokenAddr,
        uint256 stakeAmount,
        uint256 prizeAmount,
        address dacAddr
    )
    public
    {
        _participants.add(starter);
        _starter = starter;
        participantsArray = participants;
        for (uint256 i = 0; i < participants.length; ++i) {
	        _participants.add(participants[i]);
        }
	    facilitator = facilitator_param;
        _tokenAddr = tokenAddr;
        pledgeAmount = stakeAmount;
        _prizeAmount = prizeAmount;
        disputePeriod = period;
        _dacAddr = dacAddr;
    }

    /**
     * @dev add a participant. only possible when the contract is still in pending state
     * @param p the participant
     */
    function addParticipant(address p) public onlyOwner {
        require(contractStatus < ContractStatus.Effective, "STATUS_IS_NOT_PENDING");
        require(!(_participants.has(msg.sender)), "Already a participant");
	    _participants.add(p);
        participantsArray.push(p);
    }

    /**
     * @dev commit funds to the contract. participants can keep committing after the pledge ammount is reached
     * @param amount amount of fund to commit
     * @param from the address of sender
     * The sender must authorized this contract to be the operator of senders account before committing
     */
    function _commit(address from, uint256 amount) private {
        Pledge storage p = parties[from];
        p.value = p.value.add(amount);
        p.stakedValue = p.stakedValue.add(amount);
        uint256 threshold = pledgeAmount;
        if (from == _starter) {
            threshold = pledgeAmount.add(_prizeAmount);
        }
        if (from != _starter && p.value >= threshold && p.status == ParticipantStatus.Pending) {
                p.status = ParticipantStatus.Committed;
                numCommitted++;
                if (numCommitted == participantsArray.length) {
                        contractStatus = ContractStatus.Effective;
                } else {
                    contractStatus = ContractStatus.SemiCommitted;
                }
        }
        lastStatusChange = now;
    }

    /**
     * @dev commit funds to the contract. participants can keep committing after the pledge ammount is reached
     * @param amount amount of fund to commit
     * The sender must authorized this contract to be the operator of senders account before committing
     */
    function commit(uint256 amount, address sender) public payable{
        // Only participants are allowed
        require(amount > 0, "AMOUNT_NOT_GREATER_THAN_ZERO");
        require(_participants.has(sender), "DOES_NOT_HAVE_PARTICIPANT_ROLE");
        
        _commit(sender, amount);
    }

    function() external payable {
        // this means we have the after tax ether value
        if (msg.sender == _dacAddr) {
            _afterTax = msg.value;
        }
    }

    /**
     * @dev transfer pledge value from one participant to another
     * @param to target address
     * @param amount amount of fund to transfer
     * The sender must have enough fund pledged. The method does not trigger status changes.
     * The transaction is not allowed if the contract is in the middle of a dispute.
     */
    function send(address to, uint256 amount) public {

        Pledge storage p = parties[msg.sender];
        Pledge storage targetP = parties[to];

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
     * The sender must have enough fund pledged. Contract will be closed and selfdestruct if all funds are withdrawn
     * The facilitator will be paid with the gas free up after selfdestruct
     */
    function withdraw(address to) public { 
        Pledge storage p = parties[to];
        require(contractStatus == ContractStatus.Completed, "STATUS_IS_NOT_COMPLETED");
        require(p.value > 0, "AMOUNT_NOT_GREATER_THAN_ZERO");
        
        p.status = ParticipantStatus.Closed;
        lastStatusChange = now;
        numWithdraws++;

        IDAC(_dacAddr).newTransaction.value(p.value)(_starter, msg.sender, 1);
        uint256 valueToSend = _afterTax;

        p.value = 0;
        msg.sender.transfer(valueToSend);

        // indicate withdraw order is initiated. otherwise, the send will be blocked
        withdraworder[msg.sender] = true;

        if ( numWithdraws == participantsArray.length ) {
                contractStatus = ContractStatus.Closed;
                //selfdestruct(facilitator);
        }
    }
   
    /**
     * @dev signal a participant wants to exit
     * once an exit is signaled, the contract will wait pledgePeriod * 1 days for other participants to react
     * if other participants also signal exits, the contract will change the status to complete and allow withdraws
     * the other participants can choose to dispute, which blocks the withdraws until the dispute is resolved
     * if no dispute is resolved after the pledge period expires, the contract will automatically set to complete
     * and open to withdraws.
     */
    function iwantout() public {
        Pledge storage p = parties[msg.sender];
        // Only participants are allowed
        require(_participants.has(msg.sender), "DOES_NOT_HAVE_PARTICIPANT_ROLE");
        require(contractStatus == ContractStatus.Effective, "STATUS_IS_NOT_EFFECTIVE");
        require(p.status == ParticipantStatus.Committed || p.status == ParticipantStatus.Wantout, "STATUS_NOT_IN_COMMITTED_OR_WANTOUT");
        
        if (p.status != ParticipantStatus.Wantout) {
                p.status = ParticipantStatus.Wantout;
                numWantedout++;
                lastStatusChange = now;
        }
        if (numWantedout == participantsArray.length) {
                contractStatus = ContractStatus.Completed;
                emit ContractClose(msg.sender, lastStatusChange, numWantedout, "All Agreed");
        } else if (now >= lastStatusChange + disputePeriod * 1 days && contractStatus != ContractStatus.Dispute) {
                contractStatus = ContractStatus.Completed;
                emit ContractClose(msg.sender, lastStatusChange, numWantedout, "Dispute Expired");
        }
    }

    /** 
     * @dev raise a dispute
     * only one participant can raise the dispute. it will put the contract status to dispute, blocking all
     * further transactions.
     */
    function dispute() public {
        Pledge storage p = parties[msg.sender];
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
        Pledge storage p = parties[msg.sender];
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
     * @dev request a facilitator to resolve the dispute
     */
    function resolutionRequest() public {
        require(_participants.has(msg.sender), "DOES_NOT_HAVE_PARTICIPANT_ROLE");
        require(contractStatus == ContractStatus.Dispute, "STATUS_IS_NOT_DISPUTE");

        emit ResolutionRequested(msg.sender, lastStatusChange);
        contractStatus = ContractStatus.Requested;
    }
    /** 
     * @dev resolve a dispute
     * @param participants the list of addresses of participants involved in the resolution
     * @param values the list of resolved values after the resolution
     * Only the facilitator can resolve a dispute upon request
     * The total amount of values cannot exceed the total funds pledged. The contract status will set to Completed,
     * allowing withdraws.
     */
    function resolveDispute(address[] memory participants, uint256[] memory values) public {
        // Only participants are allowed
        require(facilitator == msg.sender, "DOES_NOT_HAVE_FACILITATOR_ROLE");
        require(contractStatus == ContractStatus.Requested, "STATUS_IS_NOT_REQUESTED");
        uint256 totalvalue = 0; 
        contractStatus = ContractStatus.Completed;
        for (uint256 i = 0; i < participants.length; ++i) {
	        Pledge storage p = parties[participants[i]];
            p.status = ParticipantStatus.Completed;
            p.value = values[i];
            totalvalue += p.value;
        }

        emit DisputeResolution(msg.sender, lastStatusChange, participants, values);
        lastStatusChange = now;
    }

}
