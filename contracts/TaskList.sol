pragma solidity >=0.4.22 <0.6.0;

contract TaskList {
    
    
    enum STATUS {NONE, OPEN, EXECUTING, REVIEW, REJECT, DONE}
    
    struct Task {
        string infourl; // wiki link to the task details
        uint timestamp; //timestamp of the last status update
        STATUS status;
        uint expiry; // must finish before the expiry
        uint stakereq; // stake requirement
        address taskowner;  // owner of this task
        address delegate;  // taker of the task;
        string resulturl;
        uint prize;
    }
    
    enum ROLE {NONE, TASKOWNER, SERVICE, ADMIN}

    address owner;
    mapping (address => Task[]) public tasklist;
    mapping (address => bool) taskownerlist;
    mapping (address => bool) servicelist;
    mapping (address => bool) adminlist;
    
    address[] public taskaddresses;

    constructor() public {
        owner = msg.sender;
    }

    function transferOwner (address newOwner) public {
        if (msg.sender == owner) {
            owner = newOwner;
        }
    }
    
    function addTaskOwner (address entity) public {
        if (msg.sender == owner || adminlist[msg.sender]) {
            taskownerlist[entity] = true;
        }
    }
    
    function addService (address entity) public {
        if (msg.sender == owner || adminlist[msg.sender]) {
            servicelist[entity] = true;
        }
    }
    
    function addAdmin (address entity) public {
        if (msg.sender == owner) {
            adminlist[entity] = true;
        }
    }
    /// add a new task to the list
    function addTask (string memory infourl, uint expiry, uint prize, address delegate) public returns (int) {
        if (taskownerlist[msg.sender] == false) {
            return -1;
        }
        Task[] storage tasks = tasklist[msg.sender];
        uint index = 0;
        
        for (index = 0; index < tasks.length; index++) {
            if (tasks[index].status == STATUS.DONE) break;
        }
        
        Task memory task;
        
        task.infourl = infourl;
        task.timestamp = block.timestamp;
        task.expiry = expiry;
        task.prize = prize;
        task.taskowner = msg.sender;
        task.delegate = delegate;
        task.status = STATUS.OPEN;
        if (index == tasks.length) {
            // 5 concurrent jobs per address only
            if (index == 5) return -2;
            if (index == 0) {
                // new owner
                taskaddresses.push(msg.sender);
            }
            tasks.push(task);   
        } else {
            tasks[index] = task;
        }
        return int(index);
    }
    
    /// take the task
    function takeTask (address taskowner, uint index) public returns (bool)  {
        if (servicelist[msg.sender] == false) {
            return false;
        }
        if (index >= tasklist[taskowner].length) return false;
        Task storage task = tasklist[taskowner][index];
        if (task.status == STATUS.OPEN && (task.delegate == address(0) || task.delegate == msg.sender)) {
            task.timestamp = block.timestamp;
            task.delegate = msg.sender;
            task.status = STATUS.EXECUTING;
            return true;
        }
        return false;
    }
    
    /// put the task to review
    function finshTask (address taskowner, uint index, string memory resulturl) public returns (bool)  {
        if (servicelist[msg.sender] == false) {
            return false;
        }
        if (index >= tasklist[taskowner].length) return false;
        Task storage task = tasklist[taskowner][index];
        if (task.delegate == msg.sender && (task.status == STATUS.EXECUTING || task.status == STATUS.REJECT)) {
            task.resulturl = resulturl;
            task.status = STATUS.REVIEW;
            return true;
        }
        return false;
    }
    
    /// review verdict
    function reviewTask(uint index, bool verdict) public returns (bool)  {
        if (taskownerlist[msg.sender] == false) return false;
        if (index >= tasklist[msg.sender].length) return false;
        Task storage task = tasklist[msg.sender][index];
        if (task.status == STATUS.REVIEW) {
            if (verdict == true) {
                task.status = STATUS.DONE;
            }
            else {
                task.status = STATUS.REJECT;
            }
            return true;
        }
        return false;
    }
    
    function getNumTaskLists() public view returns (uint) {
        return taskaddresses.length;
    }
    
    function getNumTaskByAddress(address taskowner) public view returns (uint) {
        return tasklist[taskowner].length;
    }
}
