pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/access/Roles.sol";

contract MToken is ERC20, ERC20Detailed, Ownable {
    using Roles for Roles.Role;

    Roles.Role private _minters;
    address[] minters_;

    constructor(
     	address[] memory minters
    )
       ERC20Detailed("Metis Token", "Metis", 18)
       public
    {
        for (uint256 i = 0; i < minters.length; ++i) {
	    _minters.add(minters[i]);
        }
        minters_ = minters;
    }

    function mint(address target, uint256 amount) external {
        require(_minters.has(msg.sender), "ONLY_MINTER_ALLOWED_TO_DO_THIS");
        _mint(target, amount);
    }

    function burn(address target, uint256 amount) external {
        require(_minters.has(msg.sender), "ONLY_MINTER_ALLOWED_TO_DO_THIS");
        _burn(target, amount);
    }
    function addMinter(address minter) external onlyOwner {
        require(!_minters.has(minter), "HAVE_MINTER_ROLE_ALREADY");
        _minters.add(minter);
        minters_.push(minter);
    }


    function removeMinter(address minter) external onlyOwner {
        require(_minters.has(msg.sender), "HAVE_MINTER_ROLE_ALREADY");
        _minters.remove(minter);
        uint256 i;
        for (i = 0; i < minters_.length; ++i) {
            if (minters_[i] == minter) {
                minters_[i] = address(0);
                break;
            }
        }
    }
}
