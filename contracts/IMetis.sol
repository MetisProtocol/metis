pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol"; 

/**
 * @dev interface of MSC
 */
interface IMetis {
    using SafeMath for uint256;

    event Transaction (address operator, address from, address to, uint256 amount, bytes msg1, bytes msg2);
    struct Balance{
        address dacAddress;
        uint256 lockedValue;
        uint256 unlockedValue;
    }

    /**
     * @dev commit funds to the contract. participants can keep committing after the pledge ammount is reached
     * @param amount amount of fund to commit
     * The sender must authorized this contract to be the operator of senders account before committing
     */
    function stake(address dacAddr, address sender) external payable; 

    /**
     * @dev dispense unlocked the token to the recipient
     * @param recipient recipient address
     * @param amount amount of unlocked M Tokens to dispense
     */
    function dispense(address recipient, uint256 amount) external;

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
}
