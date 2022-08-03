// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts@4.5.0/utils/cryptography/MerkleProof.sol";

contract Test is ERC721A {
    //Owner will be set to the deployer of the address
    address payable owner;

    //Custom Errors
    error Test_NotEnoughEther();
    error Test_ExceededLimit();
    error Test_TransferFailed();
    error Test_OnlyOwner();
    error Test_MintInactive();
    error Test_PresaleIsOver();
    error Test_MintTwoIsInactive();
    error Test_AllTokensHaveBeenMinted();

    bool mintOne;
    bool mintTwo;

    bytes32 immutable public merkleRoot;

    uint256 private constant PRICE = 0.05 ether;
    uint256 private constant MAXMINTPERWALLET = 2;
    uint256 private constant _MAXMINTPERTRANSACTIONMINTONE = 4;
    uint256 private constant _MAXMINTPERTRANSACTIONMINTTWO = 6;
    uint256 private timestamp;
    uint256 private timestampTwo;
    uint256 private tokenCounterMintOne;
    uint256 private tokenCounterMintTwo;
    /***The number here is in seconds,you can calculate how long you want the mint to be
     and convert it to seconds**/

    uint256 private constant DURATIONONE = 90;
    uint256 private constant DURATIONTWO = 120;
    
   //input the hex hash of the whitelisted addresses
    constructor (bytes32 _merkleRoot) ERC721A("Test", "TESTNFT") {
        owner = payable(msg.sender);
        merkleRoot = _merkleRoot;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Test_OnlyOwner();
        }
        _;
    }

    
    //This function will revert after 90seconds
    // The caller of the transaction will have to submit a proof (This will be sorted on the client side)
    function firstMint (uint256 quantity, bytes32[] calldata proof) external payable {
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of whitelist!");
        if( mintOne != true) {
            revert Test_MintInactive();
        }

        if (tokenCounterMintOne == _MAXMINTPERTRANSACTIONMINTONE) {
            revert Test_AllTokensHaveBeenMinted();
        }

        if(block.timestamp > timestamp + DURATIONONE) {
            revert Test_PresaleIsOver(); 
        }
    
        //If ether sent is less than the price * quatity,the function reverts
        if(msg.value < quantity * PRICE ) {
            revert Test_NotEnoughEther();
        }
       //If the caller has exceeded it's MAXMINTPERWALLET the function will revert
        if(quantity + _numberMinted(msg.sender) > MAXMINTPERWALLET ) {
            revert Test_ExceededLimit();
        }
        tokenCounterMintOne = tokenCounterMintOne + quantity;
        _mint(msg.sender,quantity);

    }
    //This function is locked till,you openMintTwo
    //Also it will revert in 120seconds you can increase the time to test well
    // Addresses that minted tokens in the first mint can't mint in the second mint
    function secondMint (uint256 quantity, bytes32[] calldata proof) external payable {
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of whitelist");
        
        if( mintTwo != true) {
            revert Test_MintInactive();
         }

        if(block.timestamp > timestampTwo + DURATIONTWO) {
            revert Test_PresaleIsOver(); 
        }

        if (tokenCounterMintTwo == _MAXMINTPERTRANSACTIONMINTTWO) {
            revert Test_AllTokensHaveBeenMinted();
        }
        // If openMintTwo hasn't been called  the owner
         
        //If ether sent is less than the price * quatity,the function reverts
        if(msg.value < quantity * PRICE ) {
            revert Test_NotEnoughEther();
        }
       //If the caller has exceeded it's MAXMINTPERWALLET the function will revert
        if(quantity + _numberMinted(msg.sender) > MAXMINTPERWALLET) {
            revert Test_ExceededLimit();
        }
        _mint(msg.sender,quantity);
        tokenCounterMintTwo = tokenCounterMintTwo + quantity;
    }

    //opens MintOne
    //Please Call this function once
    function openMintOne() external onlyOwner {
        timestamp = block.timestamp;
        mintOne = true;
    }

    //You can't call "openMintTwo" without calling openMintOne
    function openMintTwo() external onlyOwner  {
        if(mintOne != true) {
            revert Test_MintTwoIsInactive();
        }

        timestampTwo = block.timestamp;
        mintTwo = true; 
    }

    function totalSupplyMintOne() external view returns (uint) {
        return tokenCounterMintOne;
    }

    function totalSupplyMintTwo() external view returns (uint) {
        return tokenCounterMintTwo;
    }
    
    function withdrawBalance() external onlyOwner {
        (bool success,) = owner.call{value : address(this).balance} ("");
        require(success, "Fail");
    }

    function isValid(bytes32[] calldata proof, bytes32 leaf) private view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }
}






