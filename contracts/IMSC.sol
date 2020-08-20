pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/access/Roles.sol";

/**
 * @dev interface of MSC
 */
interface IMSC {

    event Transaction (address operator, address from, address to, uint256 amount, bytes msg1, bytes msg2);
    event ContractClose(address initiator, uint lastStatusChange, uint numWantedout, bytes msg);
    event ContractDispute(address operator, uint lastStatusChange, bytes msg);
    event ResolutionRequested(address initiator, uint lastStatusChange);
    event DisputeResolution(address facilitator, uint lastStatusChange, address[] participants, uint[] values);
    
    /**
     * @dev commit funds to the contract. participants can keep committing after the pledge ammount is reached
     * @param amount amount of fund to commit
     * The sender must authorized this contract to be the operator of senders account before committing
     */
    function commit(uint256 amount) external; 

    /**
     * @dev transfer pledge value from one participant to another
     * @param to target address
     * @param amount amount of fund to transfer
     * The sender must have enough fund pledged. The method does not trigger status changes.
     * The transaction is not allowed if the contract is in the middle of a dispute.
     */
    function send(address to, uint256 amount) external;

    /**
     * @dev withdraw the pledged fund
     * The sender must have enough fund pledged. Contract will be closed if all funds are withdrawn
     */
    function withdraw() external;
   
    /**
     * @dev signal a participant wants to exit
     * once an exit is signaled, the contract will wait pledgePeriod * 1 days for other participants to react
     * if other participants also signal exits, the contract will change the status to complete and allow withdraws
     * the other participants can choose to dispute, which blocks the withdraws until the dispute is resolved
     * if no dispute is resolved after the pledge period expires, the contract will automatically set to complete
     * and open to withdraws.
     * if exit is already signaled, the call may still cause status update if the pledge period expires
     */
    function iwantout() external;

    /** 
     * @dev raise a dispute
     * only one participant can raise the dispute. it will put the contract status to dispute, blocking all
     * further transactions.
     */
    function dispute() external;

    /**
     * @dev request a facilitator to resolve the dispute*/
    function resolutionRequest() external;
    /** 
     * @dev cancel a dispute
     * the method also reset the status change. the original dispute period continues.
     */
    function withdrawDispute() external;

    /** 
     * @dev resolve a dispute
     * @param participants the list of addresses of participants involved in the resolution
     * @param values the list of resolved values after the resolution
     * Only the facilitator can resolve a dispute.
     * The total amount of values cannot exceed the total funds pledged. The contract status will set to Completed,
     * allowing withdraws.
     */
    function resolveDispute(address[] calldata participants, uint256[] calldata values) external;

}
