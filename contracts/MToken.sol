pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/access/Roles.sol";

contract MToken is ERC20, ERC20Detailed, Ownable {
    using Roles for Roles.Role;

    Roles.Role private _minters;
    Roles.Role private _metis;

    enum ProposalType {undefined, MINT, BURN}
    
    event ProposalEvent(address operator, uint256 proposalNo, bytes32 msg);

    struct Proposal {
          address target;
          uint256 amount; 
          ProposalType ptype;
          mapping (address=>bool) approvals;
          bool finish;
    }

    Proposal[] public proposals;
    address[] minters_;

    constructor(
     	address[] memory minters
    )
       ERC20Detailed("METIS Token", "METIS", 18)
       public
    {
        for (uint256 i = 0; i < minters.length; ++i) {
	    _minters.add(minters[i]);
        }
        minters_ = minters;
    }

    function addMetis(address metis) external onlyOwner {
        require(!_metis.has(metis), "HAVE_METIS_ALREADY");
        _metis.add(metis);
    }

    function removeMetis(address metis) external onlyOwner {
        require(_metis.has(metis), "NO_METIS");
        _metis.remove(metis);
    }

    function mint(address target, uint256 amount) external {
        require(_metis.has(msg.sender), "ONLY_METIS_ALLOWED_TO_DO_THIS");
        _mint(target, amount);
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
    function proposeMint(address target, uint256 amount) external{
        // Only minters can mint
        require(_minters.has(msg.sender), "DOES_NOT_HAVE_MINTER_ROLE");
        Proposal memory p;
        p.target = target;
        p.amount = amount;
        p.ptype = ProposalType.MINT;
        p.finish = false;
        proposals.push(p);
        emit ProposalEvent(msg.sender, proposals.length - 1, "New Proposal");
    }

    function signMint(uint256 pos) external {
        // Only minters can mint
        require(_minters.has(msg.sender), "DOES_NOT_HAVE_MINTER_ROLE");
        require(pos < proposals.length, "INVALID_PROPOSAL");

        Proposal storage p = proposals[pos];
        require(p.ptype == ProposalType.MINT, "WRONG_TYPE");
        require(p.finish == false, "MINTED");

        p.approvals[msg.sender] = true;
        emit ProposalEvent(msg.sender, pos, "Sign");

        uint256 i;
        for (i = 0; i < minters_.length; ++i) {
            if (minters_[i] == address(0)) {
                continue;
            }
	       if (p.approvals[minters_[i]] == false) {
              break;
           }
        }
        if (i == minters_.length) {
            p.finish = true;
	       _mint(p.target, p.amount);
        }
    }

    function proposeBurn(address target, uint256 amount) external {
        // Only minters can mint
        require(_minters.has(msg.sender), "DOES_NOT_HAVE_MINTER_ROLE");
        Proposal memory p;
        p.target = target;
        p.amount = amount;
        p.ptype = ProposalType.BURN;
        proposals.push(p);
        emit ProposalEvent(msg.sender, proposals.length - 1, "New Burn Proposal");
    }

    function signBurn(uint256 pos) external {
        // Only minters can mint
        require(_minters.has(msg.sender), "DOES_NOT_HAVE_MINTER_ROLE");
        require(pos < proposals.length, "INVALID_PROPOSAL");

        Proposal storage p = proposals[pos];
        require(p.ptype == ProposalType.BURN, "WRONG_TYPE");
        require(p.finish == false, "BURNED");

        p.approvals[msg.sender] = true;
        emit ProposalEvent(msg.sender, pos, "Sign");

        uint256 i;
        for (i = 0; i < minters_.length; ++i) {
            if (minters_[i] == address(0)) {
                continue;
            }
	       if (p.approvals[minters_[i]] == false) {
              break;
           }
        }
        if (i == minters_.length) {
            p.finish = true;
	       _burn(p.target, p.amount);
        }
    }
}
