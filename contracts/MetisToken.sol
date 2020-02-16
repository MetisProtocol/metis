pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Roles.sol";

contract MetisToken is ERC777 {
    using Roles for Roles.Role;

    Roles.Role private _minters;
    Roles.Role private _burners;
    constructor(
        uint256 initialSupply,
	address[] memory minters,
	address[] memory burners,
	address[] memory defaultOperators
    )
       ERC777("MetisToken", "MTS", defaultOperators)
       public
    {
        for (uint256 i = 0; i < minters.length; ++i) {
	    _minters.add(minters[i]);
        }
	for (uint256 i = 0; i < burners.length; ++i) {
	    _burners.add(burners[i]);
	}
        _mint(msg.sender, msg.sender, initialSupply, "", "");
    }

    function mint(address to, uint256 amount) public {
        // Only minters can mint
        require(_minters.has(msg.sender), "DOES_NOT_HAVE_MINTER_ROLE");
	_mint(msg.sender, to, amount, "", "");
    }
    function burn(address from, uint256 amount) public {
        // Only burners can burn
	require(_burners.has(msg.sender), "DOES_NOT_HAVE_BURNER_ROLE");
	_burn(msg.sender, from, amount, "", "");
    }
}