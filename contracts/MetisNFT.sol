pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721MetadataMintable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/drafts/Counters.sol";

contract MetisNFT is ERC721Full, ERC721MetadataMintable, ERC721Pausable, ERC721Burnable {
   using Counters for Counters.Counter;
   enum QUALITY {SILVER, GOLD, PLATIUM, DIAMOND, GENESIS}
   Counters.Counter private _tokenIds;
   mapping(uint256=>string) public _md5s;
   mapping(uint256=>QUALITY) public _quality;
   event AWARD(address operator, address to, uint256 tokenID, QUALITY quality, string md5, string tokenURI);
   event UPDATE(address operator, uint256 tokenID, string md5);
   event BASEURI(address operator, string baseURI);

   constructor() ERC721Full("Metis Badge", "MB") public {
   }

   function awardItem(address player, QUALITY quality, string memory tokenMetaDataURI, string memory md5) public onlyMinter returns (uint256) {
      _tokenIds.increment();

      uint256 newItemId = _tokenIds.current();
      mintWithTokenURI(player, newItemId, tokenMetaDataURI);
      _md5s[newItemId] = md5;
      _quality[newItemId] = quality;
      emit AWARD(msg.sender, player, newItemId, quality, md5, tokenMetaDataURI);

      return newItemId;
   }

   function updateMD5(uint256 tokenID, string memory md5) public onlyMinter {
      _md5s[tokenID] = md5;
      emit UPDATE(msg.sender, tokenID, md5);
   }

   function md5(uint256 tokenID) public view returns(string memory) {
      return _md5s[tokenID];
   }

   function quality(uint256 tokenID) public view returns(QUALITY) {
       return _quality[tokenID];
   }

   function setBaseURI(string memory baseURI) public onlyMinter {
       _setBaseURI(baseURI);
       emit BASEURI(msg.sender, baseURI);
   }
}
