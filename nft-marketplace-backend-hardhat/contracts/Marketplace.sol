// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error Marketplace__PriceLowerThanZero();
error Marketplace__NotApproved();
error Marketplace__AlreadyListed(address contractAddress, uint256 tokenId);
error Marketplace__NotOwner();
error Marketplace__NotListed(address contractAddress, uint256 tokenId);
error Marketplace__NotEnoughEth(address contractAddress, uint256 tokenId, uint256 price);
error Marketplace__NoProceeds();
error Marketplace__TransferFailed();

contract Marketplace is ReentrancyGuard {
    constructor() {}

    // TYPES DECLARATION
    struct Listing {
        uint256 price;
        address seller;
    }

    // EVENTS
    event ItemListed(
        address indexed seller,
        address indexed contractAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemBought(
        address indexed seller,
        address indexed contractAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemCancelled(address indexed seller, address indexed contractAddress, uint256 tokenId);

    // STATE VARIABLES
    mapping(address => mapping(uint256 => Listing)) private s_listings; // contract => id => listing(price, seller)
    mapping(address => uint256) private s_proceeds; // seller => balance

    // MODIFIERS
    modifier notListed(
        address contractAddress,
        uint256 tokenId,
        address owner
    ) {
        Listing memory listing = s_listings[contractAddress][tokenId];
        if (listing.price > 0) revert Marketplace__AlreadyListed(contractAddress, tokenId);
        _;
    }

    modifier isOwner(
        address contractAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(contractAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) revert Marketplace__NotOwner();
        _;
    }

    modifier isListed(address contractAddress, uint256 tokenId) {
        Listing memory listing = s_listings[contractAddress][tokenId];
        if (listing.price <= 0) revert Marketplace__NotListed(contractAddress, tokenId);
        _;
    }

    // MAIN FUNCTIONS
    /**
     * @notice List your NFT on the marketplace
     * @param contractAddress: Address of the NFT contract
     * @param tokenId: TokenId of the owned NFT
     * @param price: Price the NFT is sold at
     */
    function listItem(
        address contractAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        notListed(contractAddress, tokenId, msg.sender)
        isOwner(contractAddress, tokenId, msg.sender)
    {
        if (price <= 0) revert Marketplace__PriceLowerThanZero();
        IERC721 nft = IERC721(contractAddress);
        if (nft.getApproved(tokenId) != address(this)) revert Marketplace__NotApproved();

        s_listings[contractAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, contractAddress, tokenId, price);
    }

    /**
     * @notice Buy an NFT on the marketplace
     * @param contractAddress: Address of the NFT contract
     * @param tokenId: TokenId of the NFT
     */
    function buyItem(address contractAddress, uint256 tokenId)
        external
        payable
        nonReentrant
        isListed(contractAddress, tokenId)
    {
        Listing memory listing = s_listings[contractAddress][tokenId];
        if (msg.value < listing.price)
            revert Marketplace__NotEnoughEth(contractAddress, tokenId, listing.price);

        s_proceeds[listing.seller] = s_proceeds[listing.seller] + msg.value;
        delete (s_listings[contractAddress][tokenId]);

        IERC721(contractAddress).safeTransferFrom(listing.seller, msg.sender, tokenId);
        emit ItemBought(msg.sender, contractAddress, tokenId, listing.price);
    }

    /**
     * @notice Cancel NFT listing on the marketplace
     * @param contractAddress: Address of the NFT contract
     * @param tokenId: TokenId of the owned NFT
     */
    function cancelListing(address contractAddress, uint256 tokenId)
        external
        isOwner(contractAddress, tokenId, msg.sender)
        isListed(contractAddress, tokenId)
    {
        delete (s_listings[contractAddress][tokenId]);
        emit ItemCancelled(msg.sender, contractAddress, tokenId);
    }

    /**
     * @notice Update your NFT listing on the marketplace
     * @param contractAddress: Address of the NFT contract
     * @param tokenId: TokenId of the owned NFT
     * @param newPrice: New price the NFT is sold at
     */
    function updateListing(
        address contractAddress,
        uint256 tokenId,
        uint256 newPrice
    ) external isListed(contractAddress, tokenId) isOwner(contractAddress, tokenId, msg.sender) {
        s_listings[contractAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, contractAddress, tokenId, newPrice);
    }

    /**
     * @notice Withdraw all proceeds accumulated on the marketplace
     */
    function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender];
        if (proceeds <= 0) revert Marketplace__NoProceeds();

        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        if (!success) revert Marketplace__TransferFailed();
    }

    // GETTER FUNCTIONS
    function getListing(address contractAddress, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return s_listings[contractAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }
}
