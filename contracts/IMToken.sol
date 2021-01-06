pragma solidity ^0.5.0;

interface IMToken {
    function mint(address target, uint256 amount) external;
    function burn(address target, uint256 amount) external;
    function addMinter(address minter) external;
    function removeMinter(address minter) external;
}
