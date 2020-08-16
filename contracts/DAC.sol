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
     * @dev participants cannot be empty
     * @param participants list of participants
     * @param facilitator_param address of the facilitator, who can resolve disputes. must be payable
     * @param period period in days of time one can raise disputes after a participant requests the exit
     * @param tokenAddr token contract address
     * @param amount amount of pledge requred
     */
    constructor(
        address creator,
        address metisAddr,
        string name,
        string symbol,
        uint256 stake,
        address business
    ) public {
        _metisAddr = metisAddr;
        _name = name;
        _creator = creator;
        _symbol = symbol;
        _business = business;
        _metis = IMetis(metisAddr);
        Profile storage p = _members[creator];
        p.lastUpdateTS = now;
        p.unlocked = stake;
        _adminRole.add(admin);
        _memberArray.push(admin);

        _taskList = new TaskList();
    }

    /**
     * @dev commit funds to the dac. 
     & @param sender address of sender
     */
    function() payable {
    }

    /**
     * @dev commit funds to the dac. 
     & @param sender address of sender
     */
    function stake(address sender) payable{
        Profile storage p = _members[sender];
        uint256 preNumTokens = _metis.getNumTokens(address(this));
        require(_metis.stake.value(msg.value)(sender), "Metis Stake failed");
        uint256 newNumTokens = _metis.getNumTokens(address(this)).sub(preNumTokens);
        uint lockRatio = _metis.lockRatioOf(address(this));

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
    function bal() public view returns (uint256 locked, uint256 unlocked) {
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
        Profile memory p = members[msg.sender];
        uint lockRatio = _metis.lockRatioOf(address(this));
        if (lockRatio != p.lastLockRatio) {
            uint256 bal = MathHelper.mulDiv(p.locked, 100, p.lastLockRatio);
            uint256 extra = p.locked.add(p.unlocked).sub(bal);
            p.locked = MathHelper.mulDiv(bal, lockRatio, 100);
            p.unlocked = bal.sub(locked).add(extra);
            p.lastLockRatio = lockRatio;
            updateReputation(msg.sender);
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
        require(updateBalance(), "Update balance failed");
        (locked, unlocked) = bal();
        require(unlocked >= amount, "INSUFFICIENT_BALANCE");
        
        IERC20(_metis._tokenAddr).transfer(msg.sender, amount);
        emit Transaction(msg.sender, address(this), msg.sender, amount, "Withdraw", "");
    }

    /**
     * @dev tax and dividents from transactions
     * @param sender sender address
     * @param type 0 if staking or 1 if paying
     */
    function newTransaction(address taskOwner, address taskTaker, uint transType) public payable {
        uint256 preNumTokens = _metis.getNumTokens(address(this));
        uint256 preEthDac = _metis._eths[address(this)];
        require(_metis.newTransaction.value(msg.value)(msg.sender), "Metis Transaction failed");
        uint256 newNumTokens = _metis.getNumTokens(address(this)).sub(preNumTokens);
        uint256 newValue = _metis._eths[address(this)].sub(preEthDac);

        require(msg.sender.transfer(newValue), "transfer failed");

        if (transType == 0) {
            Profile storage p = memebers[taskOwner];
            p.unlocked = p.unlocked.add(newNumTokens);
        } else if (transType == 1) {
            Profile storage ownerP = memebers[taskOwner];
            Profile storage workerP = memebers[taskTaker];
            require(ownerP.lastUpdateTS > 0, "Invalid Owner");
            require(workerP.lastUpdateTS > 0, "Invalid Worker");
            ownerAdd = MathHelper.mulDiv(newNumTokens, 25, 100);
            workerAdd = MathHelper.mulDiv(newNumTokens, 55, 100);
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
        return _metis._taxRate;
    }
}
