pragma solidity >=0.4.22 <0.6.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface IRegistrar {
    
    using SafeMath for uint256;

    uint public _version;

    function setMetisAddr(address metis) external;

    function createDAC (address owner, string memory name, string memory symbol, uint256 stake, address business) external;
    function isActive(address dacAddr) external;
    
    function migrateDAC (address dacAddr) external;

    function closeDAC (address dacAddr) external;

    function getLastDAC() external;
}
