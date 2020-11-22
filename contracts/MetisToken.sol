pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Roles.sol";

contract MetisToken is ERC777 {
    using Roles for Roles.Role;

    Roles.Role private _minters;
    Roles.Role private _burners;

    enum ProposalType {undefined, MINT, BURN}
    
    event ProposalEvent(address operator, uint256 proposalNo, bytes32 msg);

    struct Proposal {
          address target;
          uint256 amount; 
          ProposalType ptype;
          mapping (address=>bool) approvals;
    }

    Proposal[] public proposals;
    address[] minters_;
    address[] burners_;

    constructor(
        uint256 initialSupply,
     	address[] memory minters,
	    address[] memory burners,
	    address[] memory defaultOperators
    )
       //ERC777("M Token", "M", defaultOperators)
       public
    {
        for (uint256 i = 0; i < minters.length; ++i) {
	    _minters.add(minters[i]);
        }
	    for (uint256 i = 0; i < burners.length; ++i) {
	        _burners.add(burners[i]);
	    }
        minters_ = minters;
        burners_ = burners;
        _mint(msg.sender, msg.sender, initialSupply, "", "");
    }

    function proposeMint(address target, uint256 amount) public {
        // Only minters can mint
        require(_minters.has(msg.sender), "DOES_NOT_HAVE_MINTER_ROLE");
        Proposal memory p;
        p.target = target;
        p.amount = amount;
        p.ptype = ProposalType.MINT;
        proposals.push(p);
        emit ProposalEvent(msg.sender, proposals.length - 1, "New Proposal");
    }

    function signMint(uint256 pos) public {
        // Only minters can mint
        require(_minters.has(msg.sender), "DOES_NOT_HAVE_MINTER_ROLE");
        require(pos < proposals.length, "INVALID_PROPOSAL");

        Proposal storage p = proposals[pos];
        require(p.ptype == ProposalType.MINT, "WRONG_TYPE");

        p.approvals[msg.sender] = true;
        emit ProposalEvent(msg.sender, pos, "Sign");

        uint256 i;
        for (i = 0; i < minters_.length; ++i) {
	       if (p.approvals[minters_[i]] == false) {
              break;
           }
        }
        if (i == minters_.length) {
	       _mint(msg.sender, p.target, p.amount, "", "Approved mint");
        }
    }

    function proposeBurn(address target, uint256 amount) public {
        // Only minters can mint
        require(_minters.has(msg.sender), "DOES_NOT_HAVE_MINTER_ROLE");
        Proposal memory p;
        p.target = target;
        p.amount = amount;
        p.ptype = ProposalType.BURN;
        proposals.push(p);
        emit ProposalEvent(msg.sender, proposals.length - 1, "New Burn Proposal");
    }

    function signBurn(uint256 pos) public {
        // Only minters can mint
        require(_burners.has(msg.sender), "DOES_NOT_HAVE_BURNER_ROLE");
        require(pos < proposals.length, "INVALID_PROPOSAL");

        Proposal storage p = proposals[pos];
        require(p.ptype == ProposalType.BURN, "WRONG_TYPE");
        p.approvals[msg.sender] = true;
        emit ProposalEvent(msg.sender, pos, "Sign");

        uint256 i;
        for (i = 0; i < burners_.length; ++i) {
	       if (p.approvals[burners_[i]] == false) {
              break;
           }
        }
        if (i == burners_.length) {
	       _burn(msg.sender, p.target, p.amount, "", "Approved burn");
        }
    }
}
