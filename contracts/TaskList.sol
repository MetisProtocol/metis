pragma solidity >=0.4.22 <0.6.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./MSC.sol";

contract TaskList is Ownable{
    
    using SafeMath for uint256;

    event NewTask(address owner, uint256 index); 
    event FinishTask(address owner, uint256 index); 
    event ReviewTask(address owner, uint256 index, bool verdict); 

    enum STATUS {NONE, OPEN, STAKING, EXECUTING, REVIEW, REJECT, DONE}
    
    struct Task {
        string infourl; // wiki link to the task details
        uint256 timestamp; //timestamp of the last status update
        STATUS status;
        uint256 expiry; // must finish before the expiry
        uint256 stakereq; // stake requirement
        address taskowner;  // owner of this task
        address delegate;  // taker of the task;
        string resulturl;
        uint256 prize;
        MSC msc;
    }
    
    mapping (address => Task[]) public tasklist;
    
    constructor() public {
    }

    /// add a new task to the list
    /// pass address(0) in delegate to open the task for all
    function addTask (address owner, string memory infourl, uint256 expiry, uint256 prize, uint256 stakereq) public onlyOwner {
        Task[] storage tasks = tasklist[owner];
        
        Task memory task;
        
        task.infourl = infourl;
        task.timestamp = block.timestamp;
        task.expiry = expiry;
        task.prize = prize;
        task.stakereq = stakereq;
        task.taskowner = owner;
        task.status = STATUS.OPEN;
        tasks.push(task);   

        //deploy MSC
        task.msc = new MSC(owner, address(0) , msg.sender, 30 days, address(this), stakereq, prize, msg.sender);

        emit NewTask(owner, tasks.length - 1);
    }
    
    /// take the task
    function takeTask (address taskowner, uint256 index, address taker) public onlyOwner {
        require(index < tasklist[taskowner].length, "Index out of bound");

        Task storage task = tasklist[taskowner][index];
        require(task.status == STATUS.OPEN, "Task is not open");
        require(task.msc.contractStatus() == MSC.ContractStatus.Pending, "Contract is not open");

        task.timestamp = block.timestamp;
        task.delegate = taker;
        task.status = STATUS.STAKING;

        task.msc.assignTaker(taker);
    }

    /// reopen the task
    function reopenTask (address taskowner, uint256 index) public {
        require(index < tasklist[taskowner].length, "Index out of bound");
        require(taskowner == msg.sender, "Not a task owner");

        Task storage task = tasklist[taskowner][index];
        require(task.status == STATUS.STAKING, "Task is not in staking");
        require(task.msc.contractStatus() == MSC.ContractStatus.Pending, "Contract is not open");
        task.timestamp = block.timestamp;
        task.delegate = address(0);
        task.status = STATUS.OPEN;
    }

    /// reopen the task
    function startTask (address taskowner, uint256 index) public {
        require(index < tasklist[taskowner].length, "Index out of bound");
        require(taskowner == msg.sender, "Not a task owner");

        Task storage task = tasklist[taskowner][index];
        require (task.status == STATUS.STAKING, "Task is not in staking");
        require(task.msc.contractStatus() == MSC.ContractStatus.Effective, "Contract is not effective");
        task.timestamp = block.timestamp;
        task.status = STATUS.EXECUTING;
    }
    
    /// put the task to review
    function finshTask (address taskowner, uint256 index, string memory resulturl) public {
        require(index < tasklist[taskowner].length, "Index out of bound");

        Task storage task = tasklist[taskowner][index];
        require(task.delegate == msg.sender, "Not a task taker");
        require (task.status == STATUS.EXECUTING || task.status == STATUS.REJECT, "Task is not ready for review");
        require(task.msc.contractStatus() == MSC.ContractStatus.Effective, "Contract is not effective");
        task.timestamp = block.timestamp;
        task.status = STATUS.REVIEW;
        task.resulturl = resulturl;
        emit FinishTask(taskowner, index);
    }
    
    /// review verdict
    function reviewTask(uint256 index, bool verdict) public {
        address taskowner = msg.sender;

        require(index < tasklist[taskowner].length, "Index out of bound");

        Task storage task = tasklist[msg.sender][index];
        require (task.status == STATUS.REVIEW, "Task is not in review-pending");
        require(task.msc.contractStatus() == MSC.ContractStatus.Effective, "Contract is not effective");

        if (verdict == true) {
            task.status = STATUS.DONE;
            emit ReviewTask(taskowner, index, true);
        }
        else {
            task.status = STATUS.REJECT;
            emit ReviewTask(taskowner, index, false);
        }
    }
    
    function getNumTaskByAddress(address taskowner) public view returns (uint) {
        return tasklist[taskowner].length;
    }

    function getMSCByTask(address taskowner, uint index) public view returns(address) {
        return address(tasklist[taskowner][index].msc);
    }
}
