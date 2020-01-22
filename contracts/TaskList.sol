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
    mapping (address => Task) public tasklist;
    mapping (address => bool) taskownerlist;
    mapping (address => bool) servicelist;
    mapping (address => bool) adminlist;

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
    function addTask (string memory infourl, uint expiry, uint prize) public returns (bool)  {
        if (taskownerlist[msg.sender] == false) {
            return false;
        }
        Task storage task = tasklist[msg.sender];
        if (task.status == STATUS.NONE || task.status == STATUS.DONE) {
            task.infourl = infourl;
            task.timestamp = block.timestamp;
            task.expiry = expiry;
            task.prize = prize;
            task.status = STATUS.OPEN;
            return true;
        }
        return false;
    }
    
    /// take the task
    function takeTask (address taskowner) public returns (bool)  {
        if (servicelist[msg.sender] == false) {
            return false;
        }
        Task storage task = tasklist[taskowner];
        if (task.status == STATUS.OPEN) {
            task.timestamp = block.timestamp;
            task.delegate = msg.sender;
            task.status = STATUS.EXECUTING;
            return true;
        }
        return false;
    }
    
    /// put the task to review
    function finshTask (address taskowner, string memory resulturl) public returns (bool)  {
        if (servicelist[msg.sender] == false) {
            return false;
        }
        Task storage task = tasklist[taskowner];
        if (task.delegate == msg.sender && (task.status == STATUS.EXECUTING || task.status == STATUS.REJECT)) {
            task.resulturl = resulturl;
            task.status = STATUS.REVIEW;
            return true;
        }
        return false;
    }
    
    /// review verdict
    function reviewTask(bool verdict) public returns (bool)  {
        if (taskownerlist[msg.sender] == false) return false;
        Task storage task = tasklist[msg.sender];
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
}
