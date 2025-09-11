// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface ISTAKE {
    function votingPower(address account) external view returns (uint256); 
}

contract Vestrans is ERC1155, Ownable, ERC1155Supply {

    event Buy(address indexed account, uint256 tokenId, uint256 amount, uint256 sendEth, uint256 refundEth);
    event Price(uint256 tokenId, uint256 price, uint256 newPrice);

    using Strings for uint256;

    string public name;
    string public symbol;
    uint256 public totalEthSold;

    address immutable public stakeAddress;
    uint256 constant PRO_WOTING = 200;
    uint256 constant REG_WOTING = 1;

    bool public isOwnerMint;
    uint256 public lastTokenId;

    modifier onlyUser() {
        require(msg.sender == tx.origin, "Not allowed");
        _;
    }

    modifier onlyTokenIdRange(uint256 tokenId) {
        require(tokenId > 0 && tokenId <= lastTokenId, "Unknown token ID");
        _;
    }

    struct NftInfo {
        string name;
        uint256 maxSupply;
        uint256 price;
        uint256 point;
        uint256 maxAllocation;
        uint256 totalMinted;
    }
    
    mapping(uint256 => NftInfo) private _nftInfo;
    mapping(address => mapping (uint256 => uint256)) private _mintCounts;


    constructor(address initialOwner, address daoStake, string memory startUri, string memory tokenName, string memory tokenSymbol) ERC1155(startUri) Ownable(initialOwner) {
        stakeAddress = daoStake;
        name = tokenName;
        symbol = tokenSymbol;
    }


    function setNFTDetails(string memory tierName, uint256 maxSupply, uint256 price, uint256 point, uint256 maxAllocation) external onlyOwner(){
        require(maxSupply > 0 && price > 0 && point > 0 && maxAllocation > 0, "Zero values are not allowed");
        require(lastTokenId < 4, "Max tokenId reached");

        lastTokenId++;
        _nftInfo[lastTokenId].name = tierName;
        _nftInfo[lastTokenId].maxSupply = maxSupply;
        _nftInfo[lastTokenId].price = price;
        _nftInfo[lastTokenId].point = point;
        _nftInfo[lastTokenId].maxAllocation = maxAllocation;
    }


    function buyToMint(uint256 tokenId, uint256 amount) external payable onlyUser() onlyTokenIdRange(tokenId) {
        NftInfo memory info = _nftInfo[tokenId];

        uint256 price = userPrice(msg.sender, tokenId);

        uint256 totalPrice = price * amount;
        require(msg.value >= totalPrice, "Insufficient ETH amount");
        require(totalSupply(tokenId) + amount <= info.maxSupply, "Exceeds max supply");
        require(mintCounts(msg.sender, tokenId) + amount <= info.maxAllocation, "Max purchase limit exceeded");

        _mintCounts[msg.sender][tokenId] += amount; 

        _mint(msg.sender, tokenId, amount, "");

        if(msg.value > totalPrice){
            (bool success, ) = msg.sender.call{value: (msg.value -  totalPrice) }("");
            require(success, "ETH refund failed");
        }

        totalEthSold += totalPrice;

        emit Buy(msg.sender, tokenId, amount, msg.value, (msg.value -  totalPrice));
    }

    function votingPower(address account) public view returns(uint256){
        return ISTAKE(stakeAddress).votingPower(account);
    }
    
    function userPrice(address account, uint256 tokenId) public view returns(uint256){
        uint256 vp = votingPower(account);
        uint256 price = _nftInfo[tokenId].price;
        uint256 discount;
        if(vp == PRO_WOTING){
            discount = (price * 10) / 100;
        }else if(vp == REG_WOTING){
            discount = (price * 5) / 100;
        }
        return (price - discount);
    }

    function ownerMint() external onlyOwner(){
        require(!isOwnerMint, "Owner has already minted");
        require(lastTokenId == 4, "Not all categories are defined");

        for (uint i = 0; i < lastTokenId; i++) {
            _mint(owner(), i+1, (_nftInfo[i+1].maxSupply * 5) / 100, ""); 
        }

        isOwnerMint = true;
    }

    function setPrice(uint256 tokenId, uint256 newPrice) external onlyOwner onlyTokenIdRange(tokenId) {
        uint256 price = _nftInfo[tokenId].price;
        _nftInfo[tokenId].price = newPrice;
        emit Price(tokenId, price, newPrice);
    }


    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }


    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "No balance available");
        (bool success, ) = owner().call{value: amount }(""); 
        require(success, "ETH refund failed");
    }


    function getUserNFTs(address account) public view returns (uint256[] memory _userNfts) {
        _userNfts = new uint256[](lastTokenId);   
        for (uint i = 0; i < lastTokenId; i++) {
            _userNfts[i] = balanceOf(account, i + 1);
        }
    }

    function getUserTotalPoints(address account) external view returns (uint256 totalPoints) {
        uint256[] memory  userToken = getUserNFTs(account);
        for (uint i = 0; i < userToken.length; i++) {
            totalPoints += (userToken[i] * _nftInfo[i + 1].point);
        }
    }

    function uri(uint256 tokenId) public view override onlyTokenIdRange(tokenId) returns (string memory) { 
        return string(abi.encodePacked(super.uri(tokenId), Strings.toString(tokenId)));
    }
    
    function nftInfo(uint256 tokenId) public view onlyTokenIdRange(tokenId) returns(NftInfo memory info){
        info = _nftInfo[tokenId];
        info.totalMinted = totalSupply(tokenId);
    }

    function mintCounts(address account, uint256 tokenId) public view onlyTokenIdRange(tokenId) returns(uint256){
        return _mintCounts[account][tokenId];
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }

    receive() external payable {}
}