pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Cashier is Ownable {

    IERC20 token_;
    using SafeMath for uint256;
    enum PAYTYPE {undefined, ETHER, TOKEN}
    uint256 totalToken_;
    uint256 totalEther_;

    struct PAYMENT {
        PAYTYPE ptype;
        uint256 amount;
    }
    mapping(string=>PAYMENT) public payments_;

    constructor(
        address token
    )
    public
    {
        token_ = IERC20(token);
    }

    function payToken(string calldata invoiceid, uint256 amount) external {
        require(payments_[invoiceid].ptype != PAYTYPE.ETHER, "payment already started with ether");
        require(token_.transferFrom(msg.sender, address(this), amount), "token transfer failed");
        payments_[invoiceid].ptype = PAYTYPE.TOKEN;
        payments_[invoiceid].amount += amount;
        totalToken_ += amount;
    }

    function payEther(string calldata invoiceid) external payable{
        require(payments_[invoiceid].ptype != PAYTYPE.TOKEN, "payment already started with token");
        totalEther_ += msg.value;
    }

    function withdraw(address payable target) external onlyOwner {
        uint amounta = totalToken_;
        uint amountb = totalEther_;
        totalToken_ = 0;
        totalEther_ = 0;
        require(token_.transfer(target, amounta), "token transfer failed");
        (bool success, ) = target.call.value(amountb)('');
        require(success, "ether tranfer failed");
    }

    function withdrawTokenAmount(address target, uint256 amount) external onlyOwner {
        require(token_.transfer(target, amount), "token transfer failed");
    }

    function withdrawEtherAmount(address payable target, uint256 amount) external onlyOwner {
        (bool success, ) = target.call.value(amount)('');
        require(success, "ether tranfer failed");
    }

    function checkPayment(string calldata invoiceid) external view returns (PAYTYPE ptype, uint256 amount){
        return (payments_[invoiceid].ptype, payments_[invoiceid].amount);

    }
}
