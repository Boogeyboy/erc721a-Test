// SPDX License-Identifier :UNNLICENSED

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Test is ERC721A,Ownable {

    //Custom Errors
    error Test_NotEnoughEther();
    error Test_ExceededLimit();
    error Test_TransferFailed();

    // Variables
    bytes32 internal root;
    string internal BASEURI = "ipfs://QmbjphRaAqqThpRNnKqyuo8Uu62fmUZ94WsoRREGRpg5Fx";
    uint256 private constant PRICE = 0.05 ether;
    uint256 private constant MAXMINTPERWALLET= 2;

    constructor (bytes32 _root) ERC721A("Test", "TESTNFT") {
        root = _root;
    }

    function mint(uint256 quantity,bytes32[] memory proof) public payable {
        //checks if caller is part of the whitelist
        require(isValid(proof ,keccak256(abi.encodePacked(msg.sender))), "Not Whitelisted");
        //If ether sent is less than the price * quatity,the function reverts
        if(msg.value < quantity * PRICE ) {
            revert Test_NotEnoughEther();
        }
       //If the caller has exceeded it's MAXMINTPERWALLET the function will revert
        if(quantity + _numberMinted(msg.sender) > MAXMINTPERWALLET ) {
            revert Test_ExceededLimit();
        }
        _mint(msg.sender,quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return BASEURI;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) internal view returns (bool) {
        return MerkleProof.verify(proof,root,leaf);
    }

    //This function allows the owner of this contract to withdraw ether
    function withdrawBalance() external onlyOwner {
        (bool success,) = payable(owner).call{value:address(this).balance}("");
        if (!success) {
            revert Test_TransferFailed();
        }

  

    }




}