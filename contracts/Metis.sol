pragma solidity ^0.5.0;

import "@openzeppelin/contracts/access/Roles.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./MToken.sol";
import "./MathHelper.sol";
import "./IRegistrar.sol";
import "./IMetis.sol";
import "./IDAC.sol";
import "./ABDKMath.sol";

/**
 * @dev interface of MSC
 */
contract Metis is IMetis, Ownable{
    using SafeMath for uint256;
    event Transaction (address operator, address from, address to, uint256 amount, bytes msg1, bytes msg2);
    event Parameter(address operator, address dacAddr, uint256 from, uint256 to, bytes msg1);

    uint public _version = 1; //metis core version

    address public _tokenAddr;
    MToken private _token;
    address private _registrarAddr;
    IRegistrar private _registrar;
    address private _genesisDac;

    //global settings
    uint256 public _lockRatio = 95; // 95%
    uint256 public _taxRate = 30; // 30%

    uint256 public _curPrice = 1e15; // 0.001 * 10^18

    mapping(address=>uint256) public _zvalues; //64x64 fixed point numbers
    mapping(address=>uint256) public _tvls; //per DAC
    mapping(address=>uint256) public _preTvls;// per DAC. last Tvl before the unlock threshold
    mapping(address=>uint256) public _lockRatios; //per dac
    mapping(address=>uint256) public _eths; //per dac

    constructor(address tokenAddr, address registrarAddr) public {
        _tokenAddr = tokenAddr;
        _registrarAddr = registrarAddr;
        _registrar = IRegistrar(_registrarAddr);
        _genesisDac = _registrar.createDAC(msg.sender, "_GENESIS", "OG", 0, address(0)); 
        _token = MToken(_tokenAddr);
        emit Transaction (msg.sender, msg.sender, _genesisDac, 0, "Genesis","Create");
    }

    function isDacRegistered(address dac) public view returns (bool) {
        return _registrar.isActive(dac);
    }

    function createDAC(string memory name, string memory symbol, address business, uint256 stake) public {
        require (business != address(0), "0 address not supported");
        //require (_token.transferFrom(msg.sender, stake), "Stake transfer failed");
        address dacAddr = _registrar.createDAC(msg.sender, name, symbol, stake, business); 
        //_stake(msg.sender, dacAddr, stake);
        emit Transaction (msg.sender, msg.sender, dacAddr, stake, "DAC", "NEW");
    }

    function stake(address sender) public payable returns (uint256){
        return _stake(sender, msg.sender, msg.value);
    }
    /**
     * @dev commit funds to the contract. participants can keep committing after the pledge ammount is reached
     * The sender must authorized this contract to be the operator of senders account before committing
     */
    function _stake(address sender, address dacAddr, uint256 value) private returns(uint256 tokenMinted){
        require(isDacRegistered(dacAddr), "Invalid DAC");

        _eths[_genesisDac].add(value);
        _eths[dacAddr].add(value);

        tokenMinted = MathHelper.mulDiv(value, 10^18, _curPrice); //value * 10^18 / curPrice
        uint256 tokenLocked = MathHelper.mulDiv(tokenMinted, lockRatioOf(dacAddr), 100);

        //mint the token
        _token.mint(dacAddr, tokenMinted);

        // increase the tvl. but store the existing value for later restore.
        uint256 oldTvlDac = _tvls[dacAddr];
        _tvls[dacAddr] = _tvls[dacAddr].add(tokenLocked);
        uint256 preTvl = _tvls[_genesisDac];
        _tvls[_genesisDac] = _tvls[_genesisDac].add(tokenLocked);

        //refresh the zvalue. zvalue is calculated before the unlock modification.
        uint multiplier = 0;
        _zvalues[dacAddr] = MathHelper.mulDiv(_tvls[dacAddr], 100, _tvls[_genesisDac]);
        if (_zvalues[dacAddr] < 2) {   // z < 20%
           multiplier = 15; //1.5
        }else if (_zvalues[dacAddr] > 5) { // z > 50%
           multiplier = 7; //0.7
        } else {
           multiplier = 10; //1
        }

        // the following loop will unlcok the tokens in stages
        while (true) {
            uint256 newTvl = MathHelper.mulDiv(multiplier, _preTvls[dacAddr], 10);
            if (newTvl < _tvls[dacAddr]) {
                _lockRatios[dacAddr] = MathHelper.mulDiv(_lockRatio, _lockRatios[dacAddr], 100);
                _preTvls[dacAddr] = MathHelper.mulDiv(_lockRatio, newTvl,100); 
                _tvls[dacAddr] = MathHelper.mulDiv(_lockRatio, _tvls[dacAddr], 100);
            } else {
                break;
            }
        }

        // the tvl of the dac has been modified. recalculate the total tvl.
        _tvls[_genesisDac] = preTvl.sub(oldTvlDac).add(_tvls[dacAddr]);
        emit Parameter(sender, dacAddr, preTvl, _tvls[_genesisDac], "TVL");

        //finally, calculate the new price
        //Pt = Pt-1 * exp(tvl/pretvl)^0.05
        uint256 prePrice = _curPrice;
        _curPrice = ABDKMath.mulu( ABDKMath.exp(
                ABDKMath.mul(ABDKMath.divu(_tvls[_genesisDac], preTvl), ABDKMath.divu(5, 100))
            ), _curPrice);

        emit Parameter(sender, dacAddr, prePrice, _curPrice, "Price");

    } 

    /**
     * @dev dispense unlocked the token to the recipient
     * @param dacAddr DAC address
     */
    function lockRatioOf(address dacAddr) view public returns (uint ratio){
        require(isDacRegistered(dacAddr), "Invalid DAC");
        ratio = _lockRatios[dacAddr];
    }

    /**
     * @dev process the transaction fee
     */
    function newTransaction(address sender) public payable returns (uint256 numTokens, uint256 afterTax){
        uint256 value = msg.value;
        uint256 tax = MathHelper.mulDiv(value, _taxRate, 100);
        address dacAddr = msg.sender;

        require(isDacRegistered(dacAddr), "Invalid DAC");
        
        numTokens = MathHelper.mulDiv(value.sub(tax), 10^18, _curPrice);
        _token.mint(dacAddr, numTokens);

        afterTax = value.sub(tax);

        msg.sender.transfer(afterTax);

        emit Transaction(dacAddr, sender, _genesisDac, tax, "TAX Deposited", "ETH");
        emit Transaction(dacAddr, sender, _genesisDac, numTokens, "TAX Token Minted", "MToken");
    } 


    function getNumTokens(address dacAddr) public view returns (uint256){
        return _token.balanceOf(dacAddr);
    }


    /**
     * migrate a DAC from a previous version of metis
     * @param source the older metis
     * @param dacAddr the dac to be migrated
     */
    function migrateDAC(address dacAddr, address source) public {
        require(isDacRegistered(dacAddr), "Invalid DAC");
        require(msg.sender == IDAC(dacAddr).getCreator(), "only the creator can initiate a migration");
        // this is the first version. there for there is nothing to be migrated.
        require(source != address(0), "Invalid source");
        _registrar.migrateDAC(dacAddr);
    }


    function getTokenAddr() public view returns (address) {
        return _tokenAddr;
    }

    function getBalance(address dacAddr) public view returns (uint256) {
        require(isDacRegistered(dacAddr), "Invalid DAC");
        return _eths[dacAddr];
    }

    function getTaxRate() public view returns (uint256) {
        return _taxRate;
    }

}
