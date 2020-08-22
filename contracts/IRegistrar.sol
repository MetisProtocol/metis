pragma solidity >=0.4.22 <0.6.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface IRegistrar {
    
    using SafeMath for uint256;

    function setMetisAddr(address metis) external;

    function createDAC (address owner, string calldata name, string calldata symbol, uint256 stake, address business) external returns(address);
    function isActive(address dacAddr) external view returns(bool);
    
    function migrateDAC (address dacAddr) external;

    function closeDAC (address dacAddr) external;

    function getLastDAC() external view returns(address);
}
