pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Crowd is Ownable {

    IERC20 token_;
    using SafeMath for uint256;

    constructor(
        address token
    )
       public
    {
        token_ = IERC20(token);
    }

    function distribute(address[] calldata targets, uint[] calldata amounts) external onlyOwner {
        require(targets.length == amounts.length, "not matching");
        for (uint256 i = 0; i < targets.length; ++i) {
            require(token_.transfer(targets[i], amounts[i]), "failed");
        }
    }
}
