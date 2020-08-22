pragma solidity >=0.4.22 <0.6.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./DAC.sol";

contract Registrar is Ownable{
    
    using SafeMath for uint256;

    uint public _version = 1;

    event NewDAC(address owner, address dacAddr); 
    event FinishTask(address owner, uint256 index); 
    event ReviewTask(address owner, uint256 index, bool verdict); 

    enum STATUS {NONE, ACTIVE, DISPUTE, CLOSED}


    mapping (address => STATUS) public _dacList;
    mapping (string => bool) public _nameList;
    address[] _dacArray;
    address _metis;

    constructor() public {
    }

    function setMetisAddr(address metis) public onlyOwner {
        _metis = metis;
    }

    /// add a new task to the list
    /// pass address(0) in delegate to open the task for all
    function createDAC (address owner, string memory name, string memory symbol, uint256 stake, address business) public   returns (address newDac){

        require(msg.sender == _metis, "only metis can create DAC");
        require(_nameList[name] == false, "The name is already taken");
        
        _nameList[name] = true;

        //deploy MSC
        newDac = address(new DAC(owner, _metis, name, symbol, stake, business));
        _dacList[newDac] = STATUS.ACTIVE;
        _dacArray.push(newDac);   

        emit NewDAC(owner, newDac);
    }
    function isActive(address dacAddr) view public returns(bool){
        return _dacList[dacAddr] == STATUS.ACTIVE;
    }
    
    /// take the task
    function migrateDAC (address payable dacAddr) public {
        require(msg.sender == _metis, "only the current metis can call this method");
        require(isActive(dacAddr), "This DAC is not active");

        DAC(dacAddr).setMetis(_metis);
    }

    /// take the task
    function closeDAC (address dacAddr) public {
        require(msg.sender == _metis, "only the current metis can call this method");
        require(isActive(dacAddr), "This DAC is not active");

        _dacList[dacAddr] = STATUS.CLOSED;
    }

    function getLastDAC() view public returns(address) {
        return _dacArray[_dacArray.length - 1];
    }

}
