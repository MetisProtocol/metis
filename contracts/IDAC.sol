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

    IMetis private _metis;
    TaskList public _taskList;

    using Roles for Roles.Role;
    enum DACStatus { Pending, Effective, Closed }
    enum MemberStatus { Active, Blocked }

    event Transaction (address operator, address from, address to, uint256 amount, bytes msg1, bytes msg2);
    
    Roles.Role private _adminRole;

    struct Profile {
        uint256 reputation; 
        uint256 locked;
        uint256 unlocked;
        uint256 lastUnlockStage;
        uint256 lastUpdateTS;
        uint256 numComplaintsReceived;
        uint256 numFinishedTasks;
    }

    mapping(address => Profile) public _members;
    address[] public _memberArray;
    uint256 public _dividendPool;
    uint256 public _totalRep = 0;

    /**
     * @dev commit funds to the dac. 
     & @param sender address of sender
     */
    function stake(address sender) payable external;

    /**
     * @dev return the current balance of the sender
     */
    function balance() external view returns (uint256 locked, uint256 unlocked); 

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
    function newTransaction(address taskOwner, address taskTaker, uint transType) external;

    /**
     * @dev distribute dividends
     */
    function payDividend() external;

    /**
     * @dev update all balances
     */
    function updateAllBalances() external;

    function createTask(string memory infourl, uint256 expiry, uint256 prize, uint256 stakereq) external;

    function takeTask(address taskOwner, uint index) external;

    function getTaxRate() external view returns (uint256);
}
