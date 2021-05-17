pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract TokenVault is Ownable {

    IERC20 token_;
    using SafeMath for uint;
    enum STATUS {undefined, ARRANGED, PAID}
    event CLAIM(address operator, uint amount);
    uint8 init_;

    mapping(address=>uint[]) public arrangements_;
    mapping(uint8=>uint[]) public timestamps_;
    mapping(address=>uint8) public index_;

    constructor(
        address token
    )
    public
    {
        token_ = IERC20(token);
        timestamps_[0] = [1620903600,1628812800,1636761600,1644710400,1652400000];
        timestamps_[1] = [1620903600,1623542400,1626134400,1628812800,1631491200,1634083200,1636761600,1639353600,1642032000,1644710400,1647129600,1649808000,1652400000];
        timestamps_[2] = [1636761600,1644710400,1652400000,1660348800,1668297600,1676246400,1683936000,1691884800];
        timestamps_[3] = [1620903600];
        timestamps_[4] = [1620903600,1628812800,1636761600,1644710400,1652400000,1660348800,1668297600,1676246400,1683936000];
        timestamps_[5] = [1636761600,1652400000,1660348800,1668297600,1676246400,1683936000];
        timestamps_[6] = [1620903600,1628812800,1636761600,1644710400,1652400000,1623542400,1626134400,1631491200,1634083200,1639353600,1642032000,1647129600,1649808000];
        //special timestamp
        timestamps_[7] = [10,20,99999999999];
    }

    function _add(address target, uint[] memory inputs) internal {
        delete arrangements_[target];
        for (uint i = 0; i < inputs.length; ++i) {
            arrangements_[target].push(inputs[i]);
        }
    }
    function addNew(address target, uint[] calldata  inputs) external onlyOwner{
        _add(target, inputs);
    }

    function addNewBatch(address[] calldata targets, uint[][] calldata inputs) external onlyOwner{
        for (uint i = 0; i < inputs.length; ++i) {
            _add(targets[i], inputs[i]);
        }
    }

    function getAmountIndex(uint8 ts, uint8 i) internal pure returns(uint index){
        if (ts == 5) {
            if (i == 0) {
                index = 0;
            } else if (i == 1) {
                index = 1;
            } else {
                index = 2;
            }
        } else if (ts == 6) {
            if (i == 0) {
                index = 0;
            } else if (i % 3 == 0) {
                index = 2;
            } else {
                index = 1;
            }
        } else if (ts == 2 || ts == 3) {
            index = 0;
        } else {
            if (i == 0) {
                index = 0;
            } else {
                index = 1;
            }
        }

    }
    function claim() external {
        uint[] memory a = arrangements_[msg.sender];
        uint8 ts = uint8(a[a.length - 1]);
        uint[] memory tslist = timestamps_[ts];
        uint8 startIndex = index_[msg.sender];
        uint totalAmount = 0;

        for (uint8 i = startIndex; i < tslist.length; ++i) {
            if (now >= tslist[i]) {
                totalAmount = totalAmount.add(a[getAmountIndex(ts, i)]);
                index_[msg.sender] = i + 1;
            } else {
                break;
            }
        }
        require(token_.transfer(msg.sender, totalAmount), "TRANSFER_FAILED");
        emit CLAIM(msg.sender, totalAmount);
    }

    function checkArrangements() external view returns (string memory result){

        uint[] memory a = arrangements_[msg.sender];
        uint8 ts = uint8(a[a.length - 1]);
        uint[] memory tslist = timestamps_[ts];
        uint8 startIndex = index_[msg.sender];

        for(uint8 i = 0; i < tslist.length; ++i) {
            string memory cur;
            if (i < startIndex) {
                cur = string(abi.encodePacked("Amount:", uint2str(a[getAmountIndex(ts, i)]), " PAID|"));
            } else {
                cur = string(abi.encodePacked("Amount:", uint2str(a[getAmountIndex(ts, i)]), " Available on TS ", uint2str(tslist[i]), " LOCKED|"));
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
