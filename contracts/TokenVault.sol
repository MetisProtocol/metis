pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract TokenVault is Ownable {

    IERC20 token_;
    using SafeMath for uint256;
    enum STATUS {undefined, ARRANGED, PAID}
    event NEW(address target, uint index, uint256 amount, uint256 timestamp);
    event DATED(address target, uint index, uint256 timestamp);
    event CLAIM(address operator, uint256 amount);

    struct ARRANGEMENT{
        uint256 amount;
        uint256 timestamp;
        STATUS aStatus;

    }
    mapping(address=>ARRANGEMENT[]) public arrangements_;

    constructor(
        address token
    )
    public
    {
        token_ = IERC20(token);
    }

    function addNew(address target, uint256 amount, uint256 timestamp) external onlyOwner {
        ARRANGEMENT[] storage alist = arrangements_[target];
        ARRANGEMENT memory a;
        a.amount = amount;
        a.timestamp = timestamp;
        a.aStatus = STATUS.ARRANGED;
        alist.push(a);
        emit NEW(target, alist.length - 1, amount, timestamp);
    }

    function addNewPending(address target, uint256 amount) external onlyOwner {
        ARRANGEMENT[] storage alist = arrangements_[target];
        ARRANGEMENT memory a;
        a.amount = amount;
        a.aStatus = STATUS.undefined;
        alist.push(a);
        emit NEW(target, alist.length - 1, amount, 0);
    }

    function addNewPendings(address[] calldata targets, uint256[] calldata amounts) external onlyOwner {
        require(targets.length == amounts.length, "amount length mistmatch");

        for (uint i = 0; i < targets.length; ++i) {
            address target = targets[i];
            uint256 amount = amounts[i];
            ARRANGEMENT[] storage alist = arrangements_[target];
            ARRANGEMENT memory a;
            a.amount = amount;
            a.aStatus = STATUS.undefined;
            alist.push(a);
            emit NEW(target, alist.length - 1, amount, 0);
        }
    }

    function setDate(address target, uint index, uint256 timestamp) external onlyOwner {
        require(index < arrangements_[target].length, "invalid index");

        ARRANGEMENT[] storage alist = arrangements_[target];
        ARRANGEMENT storage a = alist[index];
        a.timestamp = timestamp;
        a.aStatus = STATUS.ARRANGED;
        emit DATED(target, index, timestamp);
    }

    function setDates(address[] calldata targets, uint[] calldata indexs, uint256[] calldata timestamps) external onlyOwner {
        require(targets.length == indexs.length, "index length mismatch");
        require(targets.length == timestamps.length, "timestamp length mismatch");

        for (uint i = 0; i < targets.length; ++i) {
            uint index = indexs[i];
            address target = targets[i];
            uint256 timestamp = timestamps[i];
            require(index < arrangements_[target].length, "invalid index");
            ARRANGEMENT[] storage alist = arrangements_[target];
            ARRANGEMENT storage a = alist[index];
            a.timestamp = timestamp;
            a.aStatus = STATUS.ARRANGED;
            emit DATED(target, index, timestamp);
        }
    }

    function claim() external {
        ARRANGEMENT[] storage a = arrangements_[msg.sender];
        uint256 totalAmount = 0;
        for (uint i = 0; i < a.length; ++i) {
            if (a[i].aStatus != STATUS.ARRANGED) {
                continue;
            }
            else if (now >= a[i].timestamp) {
                a[i].aStatus = STATUS.PAID;
                totalAmount += a[i].amount;
            }
        }
        require(token_.transfer(msg.sender, totalAmount), "TRANSFER_FAILED");
        emit CLAIM(msg.sender, totalAmount);
    }

    function checkArrangement(uint index) external view returns (string memory result){
        require(index < arrangements_[msg.sender].length, "invalid index");
        ARRANGEMENT memory a = arrangements_[msg.sender][index];
        if (a.aStatus == STATUS.PAID) {
            return string(abi.encodePacked("Amount:", uint2str(a.amount), " Available on TS ", uint2str(a.timestamp), " PAID"));
        } else if (a.aStatus == STATUS.ARRANGED) {
            return string(abi.encodePacked("Amount:", uint2str(a.amount), " Available on TS ", uint2str(a.timestamp), " ARRANGED"));
        } else {
            return string(abi.encodePacked("Amount:", uint2str(a.amount), " Available on TS ", uint2str(a.timestamp), " LOCKED"));
        }
     }

    function checkArrangements() external view returns (string memory result){
        for(uint index = 0; index < arrangements_[msg.sender].length; ++index) {
            ARRANGEMENT memory a = arrangements_[msg.sender][index];
            string memory cur;
            if (a.aStatus == STATUS.PAID) {
                cur = string(abi.encodePacked("Amount:", uint2str(a.amount), " Available on TS ", uint2str(a.timestamp), " PAID"));
            } else if (a.aStatus == STATUS.ARRANGED) {
                cur = string(abi.encodePacked("Amount:", uint2str(a.amount), " Available on TS ", uint2str(a.timestamp), " ARRANGED"));
            } else {
                cur = string(abi.encodePacked("Amount:", uint2str(a.amount), " Available on TS ", uint2str(a.timestamp), " LOCKED"));
            }
            result = string(abi.encodePacked(result, "\n", cur));
        }
     }

     function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
         if (_i == 0) {
             return "0";
         }
         uint j = _i;
         uint len;
         while (j != 0) {
            len++;
            j /= 10;
         }
         bytes memory bstr = new bytes(len);
         uint k = len - 1;
         while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
         }
         return string(bstr);
    }
}
