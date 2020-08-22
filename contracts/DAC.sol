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
contract DAC is IDAC, Ownable{
    using SafeMath for uint256;

    IMetis private _metis;
    TaskList public _taskList;

    using Roles for Roles.Role;
    enum DACStatus { Pending, Effective, Closed }
    enum MemberStatus { Active, Blocked }

    event Transaction (address operator, address from, address to, uint256 amount, bytes msg1, bytes msg2);
    
    Roles.Role private _adminRole;
    address _creator;
    address _metisAddr;
    string _name;
    string _symbol;
    address _business;

    struct Profile {
        uint256 reputation; 
        uint256 locked;
        uint256 unlocked;
        uint256 dividend;
        uint256 lastLockRatio;
        uint256 lastUpdateTS;
        uint256 numComplaintsReceived;
        uint256 numFinishedTasks;
    }

    mapping(address => Profile) public _members;
    address[] public _memberArray;
    uint256 public _dividendPool;
    uint256 public _totalRep = 0;
    
    /**
     * @dev participants cannot be empty
     */
    constructor(
        address creator,
        address metisAddr,
        string memory name,
        string memory symbol,
        uint256 stake,
        address business
    ) Ownable() public {
        _metisAddr = metisAddr;
        _name = name;
        _creator = creator;
        _symbol = symbol;
        _business = business;
        _metis = IMetis(metisAddr);
        Profile storage p = _members[creator];
        p.lastUpdateTS = now;
        p.unlocked = stake;
        _adminRole.add(creator);
        _memberArray.push(creator);

        _taskList = new TaskList();
    }

    /**
     * @dev commit funds to the dac. 
     */
    function() external payable {
    }

    /**
     * @dev commit funds to the dac. 
     & @param sender address of sender
     */
    function stake(address sender) public payable{
        Profile storage p = _members[sender];

        uint256 newNumTokens = _metis.stake.value(msg.value)(sender);

        if (p.lastUpdateTS == 0) {
            // new memeber
            p.lastLockRatio = 100; //always assume 100% locked
            p.locked = newNumTokens;
        } else {
            uint256 locked = MathHelper.mulDiv(newNumTokens, p.lastLockRatio,100);
            p.locked = p.locked.add(locked);
            p.unlocked = p.unlocked.add(newNumTokens.sub(locked));
        }
        updateBalance(sender);
        emit Transaction(sender, sender, address(this), msg.value, "Stake", "");
    }

    /**
     * @dev return the current balance of the sender
     */
    function getBalance() public view returns (uint256 locked, uint256 unlocked) {
        Profile memory p = _members[msg.sender];
        locked = p.locked;
        unlocked = p.unlocked;
    }

    function updateReputation(address member) public {
        Profile storage p = _members[member];
        _totalRep = _totalRep.sub(p.reputation);
        p.reputation = p.locked.div(10^12).add( 
            MathHelper.mulDiv(p.numFinishedTasks.sub(p.numComplaintsReceived),10, p.numFinishedTasks.add(1)));
        _totalRep = _totalRep.add(p.reputation);
    }

    /**
     * @dev return the current balance of the sender
     */
    function updateBalance() public {
        updateBalance(msg.sender);
    }

    /**
     * @dev return the current balance of the sender
     */
    function updateBalance(address sender) public {
        Profile memory p = _members[sender];
        uint lockRatio = _metis.lockRatioOf(address(this));
        if (lockRatio != p.lastLockRatio) {
            uint256 newLocked = MathHelper.mulDiv(MathHelper.mulDiv(p.locked, 100, p.lastLockRatio), lockRatio, 100);
            uint256 diff = p.locked.sub(newLocked);
            p.locked = newLocked;
            p.unlocked = p.unlocked.add(diff);
            p.lastLockRatio = lockRatio;
            updateReputation(sender);
        }
        p.lastUpdateTS = now;
    }

    /**
     * @dev withdraw the unlocked token
     * The sender must have enough fund pledged. Contract will be closed and selfdestruct if all funds are withdrawn
     * The facilitator will be paid with the gas free up after selfdestruct
     */
    function withdraw(uint256 amount) public {
        Profile storage p = _members[msg.sender];
        require(p.reputation > 0, "NOT_A_MEMBER"); 

        uint256 locked;
        uint256 unlocked;

        updateBalance();
        (locked, unlocked) = getBalance();
        require(unlocked >= amount, "INSUFFICIENT_BALANCE");
        
        p.unlocked = p.unlocked.sub(amount);
        IERC20(_metis.getTokenAddr()).transfer(msg.sender, amount);
        emit Transaction(msg.sender, address(this), msg.sender, amount, "Withdraw", "");
    }

    /**
     * @dev tax and dividents from transactions
     * @param transType 0 if staking or 1 if paying
     */
    function newTransaction(address taskOwner, address taskTaker, uint transType) public payable returns(uint256 newValue){
        uint256 newNumTokens;

        (newNumTokens, newValue) = _metis.newTransaction.value(msg.value)(msg.sender);

        msg.sender.transfer(newValue);

        if (transType == 0) {
            Profile storage p = _members[taskOwner];
            p.unlocked = p.unlocked.add(newNumTokens);
        } else if (transType == 1) {
            Profile storage ownerP = _members[taskOwner];
            Profile storage workerP =_members[taskTaker];
            require(ownerP.lastUpdateTS > 0, "Invalid Owner");
            require(workerP.lastUpdateTS > 0, "Invalid Worker");
            uint256 ownerAdd = MathHelper.mulDiv(newNumTokens, 25, 100);
            uint256 workerAdd = MathHelper.mulDiv(newNumTokens, 55, 100);
            ownerP.unlocked = ownerP.unlocked.add(ownerAdd);
            workerP.unlocked = workerP.unlocked.add(workerAdd);
            _dividendPool = _dividendPool.add(newNumTokens.sub(ownerAdd).sub(workerAdd));
            updateBalance(taskOwner);
            updateBalance(taskTaker);
        }
    }

    /**
     * @dev distribute dividends
     */
    function payDividend() public {
        require(_dividendPool > 0, "Nothing dividends pay");
        uint256 dividendPool = _dividendPool;
        for (uint i = 0; i < _memberArray.length; ++i)
        {
            Profile storage p = _members[_memberArray[i]];
            uint256 dividend = MathHelper.mulDiv(p.reputation, dividendPool, _totalRep);
            p.unlocked = p.unlocked.add(dividend);
            p.dividend = p.dividend.add(dividend);
            _dividendPool = _dividendPool.sub(dividend);
        }
    }

    /**
     * @dev update all balances
     */
    function updateAllBalances() public {
        for (uint i = 0; i < _memberArray.length; ++i)
        {
            updateBalance(_memberArray[i]);
        }
    }

    function createTask(string memory infourl, uint256 expiry, uint256 prize, uint256 stakereq) public {
       Profile memory p = _members[msg.sender];
       require(p.lastUpdateTS > 0, "Invalid member");
       _taskList.addTask(msg.sender, infourl, expiry, prize, stakereq); 
    }

    function takeTask(address taskOwner, uint index) public {
       Profile memory p = _members[msg.sender];
       require(p.lastUpdateTS > 0, "Invalid member");
       _taskList.takeTask(taskOwner, index, msg.sender);
    }

    function getTaxRate() public view returns (uint256) {
        return _metis.getTaxRate();
    }

    function getCreator() public view returns (address) {
        return _creator;
    }

    function setMetis(address metis) public onlyOwner {
        _metis = IMetis(metis);
    }
}
