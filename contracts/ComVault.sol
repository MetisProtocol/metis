pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./MathHelper.sol";

contract ComVault is Ownable {
    IERC20 _metisToken;
    using SafeMath for uint256;
    enum STATUS {undefined, ARRANGED, FUNDED}
    event NEW(address target, uint256 amount, uint256 metisAmount);
    event CLAIM(address operator, uint256 amount);
    event TGE(uint256 timestamp, uint256 tge);
    uint256 _tge;
    uint256 _interval;
    address _tokenaddr;

    struct ARRANGEMENT{
        uint256 amount;
        uint256 targetAmount;
        uint256 metisAmount;
        uint256 metisPaid;
        uint claimIndex;
        STATUS aStatus;
    }
    mapping(address=>ARRANGEMENT) public arrangements_;

    constructor(
        address metisToken
    )
    public
    {
        _metisToken = IERC20(metisToken);
        _interval = 30 days;
        _tokenaddr = metisToken;
    }

    function setTge(uint256 tge) external onlyOwner {
        //require(_tge == 0, 'TGE is already set');
        emit TGE(_tge, tge);
        _tge = tge;
    }
    function _add(address target, uint256 targetamount, uint256 metisAmount) internal {
        ARRANGEMENT storage a = arrangements_[target];
        //require (a.aStatus == STATUS.undefined, "target already arranged");
        a.targetAmount = targetamount;
        a.aStatus = STATUS.FUNDED;
        a.amount = targetamount;
        a.metisAmount = metisAmount;
        emit NEW(target, targetamount, metisAmount);
    }

    function addNew(address target, uint256 targetamount, uint256 metisAmount) external onlyOwner {
        _add(target, targetamount, metisAmount);
    }

    function addNewBatch(address[] calldata targets, uint256[] calldata amounts, uint256[] calldata metisAmounts) external onlyOwner {
        require(targets.length == amounts.length, "amount length mistmatch");

        for (uint i = 0; i < targets.length; ++i) {
            _add(targets[i], amounts[i], metisAmounts[i]);
        }
    }

    function claim() external {
        require(_tge > 0, "TGE not set");
        require(now >= _tge, "TGE has not arrived yet");

        ARRANGEMENT storage a = arrangements_[msg.sender];

        require(a.aStatus == STATUS.FUNDED, "not funded");
        require(a.metisPaid < a.metisAmount, "all paid");

        uint256 totalAmount = 0;
        uint256 curIndex = (now - _tge) / _interval ;

        if (a.claimIndex == 0 && a.metisPaid == 0) {
            //first time, after TGE unlock 10%
            totalAmount = totalAmount.add(MathHelper.mulDiv(a.metisAmount, 1, 10));
        }

        if (curIndex > 12) {
           totalAmount = a.metisAmount.sub(a.metisPaid);
        } else if (curIndex > a.claimIndex ) {
           totalAmount = totalAmount.add(MathHelper.mulDiv(MathHelper.mulDiv(a.metisAmount, 9, 10), curIndex - a.claimIndex , 12));
        }
        a.metisPaid = a.metisPaid.add(totalAmount);
        a.claimIndex = curIndex;

        //require(totalAmount > 0, "Nothing to claim");
        require(_metisToken.transfer(msg.sender, totalAmount), "TRANSFER_FAILED");

        emit CLAIM(msg.sender, totalAmount);
    }
}
