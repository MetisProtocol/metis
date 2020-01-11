pragma solidity >=0.4.22 <0.6.0;

contract TaskList {
    
    
    enum STATUS {NONE, OPEN, EXECUTING, REVIEW, REJECT, DONE}
    
    struct Task {
        string infourl;
        uint timestamp;
        STATUS status;
        uint expiry;
        address taskowner;
        address delegate;
        string resulturl;
        uint prize;
    }
    
    enum ROLE {NONE, TASKOWNER, SERVICE, ADMIN}

    address owner;
    mapping (address => ROLE) rolelist;
    mapping (address => Task) public tasklist;

    constructor() public {
        owner = msg.sender;
    }

    function addRole (address entity, ROLE _role) public {
        if (msg.sender == owner) {
            rolelist[entity] = _role;
        }
    }
    /// add a new task to the list
    function addTask (string memory infourl, uint expiry, uint prize) public returns (bool)  {
        if (rolelist[msg.sender] != ROLE.TASKOWNER) {
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
        if (rolelist[msg.sender] != ROLE.SERVICE) return false;
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
        if (rolelist[msg.sender] != ROLE.SERVICE) return false;
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
        if (rolelist[msg.sender] != ROLE.TASKOWNER) return false;
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
    
    function getRole (address ad) view public returns (ROLE) {
        if (msg.sender == owner) return rolelist[ad];
    }
    
}
