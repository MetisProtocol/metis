pragma solidity ^0.5.0;

import "@openzeppelin/contracts/access/Roles.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./MathHelper.sol";
import "./IRegistrar.sol";
import "./IMetis.sol";
import "./ABDKMath.sol";

/**
 * @dev interface of MSC
 */
contract Metis is IMetis, Ownable{
    using SafeMath for uint256;
    event Transaction (address operator, address from, address to, uint256 amount, bytes msg1, bytes msg2);
    event Parameter(address operator, address dacAddr, uint256 from, uint256 to, bytes msg1);

    address public _tokenAddr;
    address private _registrar;
    address private _genesisDac;

    //global settings
    uint256 public _lockRatio = 95; // 95%
    uint256 public _taxRate = 30; // 30%

    uint256 public _curPrice = 1e15; // 0.001 * 10^18

    mapping(address=>int128) public _zvalues; //64x64 fixed point numbers
    mapping(address=>uint256) public _tvls; //per DAC
    mapping(address=>uint256) public _preTvls;// per DAC. last Tvl before the unlock threshold
    mapping(address=>uint256) public _lockRatios; //per dac
    mapping(address=>uint256) public _eths; //per dac

    constructor(address tokenAddr, address registrar) {
        _tokenAddr = tokenAddr;
        _registrar = registrar;
        _genesisDac = IRegistrar(_registrar).createNew([msg.sender], address(this), "GENESIS", "OG"); 
        emit Transaction (msg.sender, msg.sender, _genesisDac, 0, "Genesis","");
    }

    function isDacRegistered(address dac) view returns (bool) {
        return IRegistrar(_registrar).isActive(dac);
    }

    /**
     * @dev commit funds to the contract. participants can keep committing after the pledge ammount is reached
     * @param amount amount of fund to commit
     * The sender must authorized this contract to be the operator of senders account before committing
     */
    function stake(address sender) payable{
        address dacAddr = msg.sender;
        require(isDacRegistered(dacAddr), "Invalid DAC");
        uint256 storage z = _zvalues[dacAddr];
        uint256 storage tvl = _tvls[_genesisDac];
        uint256 storage tvlDac = _tvls[dacAddr];
        uint256 storage preTvlDac = _preTvls[dacAddr];
        uint256 storage lockRatioDac = _lockRatios[dacAddr];
        uint256 storage totalEth = _eths[_genesisDac];
        uint256 storage ethDac = _eths[dacAddr];
        uint256 value = msg.value;
        totalEth.add(value);
        ethDac.add(value);
        uint256 tokenMinted = MathHelper.mulDiv(value, 10^18, _curPrice); //value * 10^18 / curPrice
        uint256 tokenLocked = MathHelper.mulDiv(tokenMinted, lockRatioOf(dacAddr), 100);

        //mint the token
        IERC20 token = IERC20(_tokenAddr);
        token._mint(dacAddr, tokenMinted);

        // increase the tvl. but store the existing value for later restore.
        preTvlDac = tvlDac;
        tvlDac = tvlDac.add(tokenLocked);
        preTvl = tvl;
        tvl = tvl.add(tokenLocked);

        //refresh the zvalue. zvalue is calculated before the unlock modification.
        uint multiplier = 0;
        z = MathHelper.mulDiv(tvlDac, 100, tvl);
        if (z < 2) {   // z < 20%
           multiplier = 15; //1.5
        }else if (z>5) { // z > 50%
           multiplier = 7; //0.7
        } else {
           multiplier = 10; //1
        }

        // the following loop will unlcok the tokens in stages
        while (true) {
            newTvl = MathHelper.mulDiv(multiplier, preTvlDac, 10);
            if (newTvl < tvlDac) {
                lockRatioDac = MathHelper.mulDiv(_lockRatio, lockRatioDac, 100);
                preTvlDac = MathHelper.mulDiv(_lockRatio, newTvl,100); 
                tvlDac = MathHelper.mulDiv(_lockRatio, tvlDac, 100);
            } else {
                break;
            }
        }
        // the tvl of the dac has been modified. recalculate the total tvl.
        tvl = preTvl.sub(preTvlDac).add(tvlDac);
        emit Parameter(sender, dacAddr, preTvl, tvl, "TVL");

        //finally, calculate the new price
        //Pt = Pt-1 * exp(tvl/pretvl)^0.05
        prePrice = _curPrice;
        _curPrice = _curPrice * ABDKMath.pow(
            ABDKMath.exp(
                ABDKMath.divu(tvl, preTvl)
            ),
            ABDKMath.divu(5, 100));

        emit Parameter(sender, dacAddr, prePrice, _cuRprice, "Price");

    } 

    /**
     * @dev dispense unlocked the token to the recipient
     * @param dacAddr DAC address
     * @param recipient recipient address
     * @param amount amount of unlocked M Tokens to dispense
     */
    function lockRatioOf(address dacAddr) view returns (uint ratio){
        require(isDacRegistered(dacAddr), "Invalid DAC");
        ratio = _lockRatios[dacAddr];
    }

    /**
     * @dev process the transaction fee
     */
    function newTransaction(address sender) payable {
        uint256 value = msg.value;
        uint256 tax = MathHelper.mulDiv(value, _taxRate, 100);
        address dacAddr = msg.sender;
        uint256 ethDac = _eths[dacAddr];

        require(isDacRegistered(dacAddr), "Invalid DAC");
        
        numTokens = MathHelper.mulDiv(value.sub(tax), 10^18, _curPrice);
        IERC20 token = IERC20(_tokenAddr);
        token._mint(dacAddr, tokenMinted);
        ethDac = ethDac.add(value.sub(tax));

        require(msg.sender.transfer(value.sub(tax)), "transfer failed");

        emit Transaction(dacAddr, sender, _genesisDac, tax, "TAX Deposited", "ETH");
        emit Transaction(dacAddr, sender, _genesisDac, numTokens, "TAX Token Minted", "MToken");
    } 


    function getNumTokens(address dacAddr) returns (uint256){
        return IERC20(_tokenAddr).balanceOf(dacAddr);
    }
}
