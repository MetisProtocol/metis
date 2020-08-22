pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol"; 

/**
 * @dev interface of MSC
 */
interface IMetis {
    using SafeMath for uint256;


    event Transaction (address operator, address from, address to, uint256 amount, bytes msg1, bytes msg2);
    struct Balance{
        address dacAddress;
        uint256 lockedValue;
        uint256 unlockedValue;
    }

    /**
     * @dev commit funds to the contract. participants can keep committing after the pledge ammount is reached
     * The sender must authorized this contract to be the operator of senders account before committing
     */
    function stake(address sender) external payable returns(uint256); 

    /**
     * @dev dispense unlocked the token to the recipient
     * @param recipient recipient address
     * @param amount amount of unlocked M Tokens to dispense
     */
    function dispense(address recipient, uint256 amount) external;

    function newTransaction(address sender) external payable returns(uint256, uint256);

    function getNumTokens(address dacAddr) external view returns (uint256);
    function lockRatioOf(address dacAddr) external view returns (uint ratio);
    function getTokenAddr() external view returns (address);
    function getTaxRate() external view returns (uint256);
    function getBalance(address dacAddr) external view returns (uint256);
}
