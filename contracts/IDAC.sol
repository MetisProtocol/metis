pragma solidity ^0.5.0;

import "@openzeppelin/contracts/access/Roles.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./MathHelper.sol";
import "./IDAC.sol";
import "./IMetis.sol";
import "./TaskList.sol";

/**
 * @dev implementation of MSC
 */
interface IDAC {
    using SafeMath for uint256;

    /**
     * @dev commit funds to the dac. 
     & @param sender address of sender
     */
    function stake(address sender) payable external;

    /**
     * @dev return the current balance of the sender
     */
    function getBalance() external view returns (uint256 locked, uint256 unlocked); 

    function updateReputation(address member) external;

    /**
     * @dev return the current balance of the sender
     */
    function updateBalance() external; 

    /**
     * @dev withdraw the unlocked token
     * The sender must have enough fund pledged. Contract will be closed and selfdestruct if all funds are withdrawn
     * The facilitator will be paid with the gas free up after selfdestruct
     */
    function withdraw(uint256 amount) external;

    /**
     * @dev tax and dividents from transactions
     * @param taskOwner sender address
     * @param taskTaker address
     * @param transType 0 if staking or 1 if paying
     */
    function newTransaction(address taskOwner, address taskTaker, uint transType) external payable returns (uint256);

    /**
     * @dev distribute dividends
     */
    function payDividend() external;

    /**
     * @dev update all balances
     */
    function updateAllBalances() external;

    function createTask(string calldata infourl, uint256 expiry, uint256 prize, uint256 stakereq) external;

    function takeTask(address taskOwner, uint index) external;

    function getTaxRate() external view returns (uint256);
    function getCreator() external view returns (address);
}
