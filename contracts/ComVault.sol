pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract ComVault is Ownable {

    IERC20 token_;
    IERC20 _metisToken;
    using SafeMath for uint256;
    enum STATUS {undefined, ARRANGED, FUNDED}
    event NEW(address target, uint256 amount, uint256 metisAmount);
    event FUND(address target, uint256 amount, uint256 timestamp);
    event CLAIM(address operator, uint256 amount);
    event TGE(uint256 timestamp, uint256 tge);
    uint256 _tge;
    uint256 _interval;

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
        address token,
        address metisToken
    )
    public
    {
        token_ = IERC20(token);
        _metisToken = IERC20(metisToken);
        _interval = 30 days;
    }

    function withdrawFund(address target) external onlyOwner {
        token_.transfer(target, token_.balanceOf(address(this)));
    }

    function fund(address target, uint256 amount) external {
        ARRANGEMENT storage a = arrangements_[target];
        require(a.aStatus == STATUS.ARRANGED, "sender not arranged or already funded");
        require(token_.transferFrom(msg.sender, address(this), amount), "token transfer failed");
        require(amount + a.amount <= a.targetAmount, "token transfer failed");

        a.amount += amount;
        if (a.amount == a.targetAmount) {
           a.aStatus = STATUS.FUNDED;
        }
        emit FUND(msg.sender, amount, now);
    }

    function setTge(uint256 tge) external onlyOwner {

        emit TGE(_tge, tge);
        _tge = tge;
    }
    function _add(address target, uint256 targetamount, uint256 metisAmount) internal {
        ARRANGEMENT storage a = arrangements_[target];
        require (a.aStatus == STATUS.undefined, "target already arranged");
        a.targetAmount = targetamount;
        a.aStatus = STATUS.ARRANGED;
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

        ARRANGEMENT storage a = arrangements_[msg.sender];

        require(a.aStatus == STATUS.FUNDED, "not funded");
        require(a.metisPaid < a.metisAmount, "all paid");

        uint256 totalAmount = 0;
        uint256 curIndex = (now - _tge) / _interval + 1;

        if (curIndex >= 12) {
            totalAmount = a.metisAmount - a.metisPaid;
            a.metisPaid = a.metisAmount;
        }else {
           for (uint i = a.claimIndex; i < curIndex; ++i) {
               totalAmount += a.metisAmount / 12; // unlock 1/12 every 30 days
           }
           a.metisPaid += totalAmount;
        }

        a.claimIndex = curIndex;

        require(_metisToken.transfer(msg.sender, totalAmount), "TRANSFER_FAILED");
        emit CLAIM(msg.sender, totalAmount);
    }
}
