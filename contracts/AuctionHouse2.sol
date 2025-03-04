// SPDX-License-Identifier: None
pragma solidity ^0.8.20;
import "@openzeppelin/contracts@5.0.1/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@5.0.1/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@5.0.1/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract GainfulAuctionSeries2 is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    // NFT Infrastructure
    uint256 private _nextTokenId;
    string public baseURI;
    function _baseURI() internal view override returns (string memory) {return baseURI;}
    function setBaseURI(string memory uri) public onlyOwner {baseURI = uri;}
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){ return super.tokenURI(tokenId); }
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) { return super.supportsInterface(interfaceId);}
    constructor(string memory base_uri, string memory series_name, string memory series_symbol, address auctioneer, address protocol, uint256 bid_fee) ERC721(series_name, series_symbol) Ownable(auctioneer) ReentrancyGuard() {
        baseURI = base_uri;
        GAINFUL_AUCTION_PROTOCOL_ADDRESS=protocol;
        BID_FEE=bid_fee;
        }

    event AuctionStarted(string indexed auction_name,address indexed starter,uint256 starting_bid,uint256 timestamp);
    event Bid(string indexed auction_name, address indexed bidder,uint256 bid,uint256 timestamp);
    event AuctionEnded(string indexed auction_name, address indexed ender, address indexed winner,uint256 winning_bid);
    event MintNFT(address indexed owner, string indexed auction_name, uint256 nft_id);

    struct AuctionData {
        uint256 auctionEndTimestamp; // updated with bids made within 60 minutes of end.
        address latestBidder; // updated with each bid, finalized after auctionEndTimestamp
        uint256 bidAmount; // updated with each bid, finalized after auctionEndTimestamp
        uint256 bidDifferenceSplit; // the basis points of bid difference shared with prior bidder.
        bool auctionStarted; // Set to true when auction starts
        bool auctionEnded; // set to true when auction ends
        string uriPath; // token uri for NFT
        uint256 startingPrice; // this is the minimum starting bid, is never updated
        uint256 auctionDurationHours; // the number of hours until the auction ends, is never updated.
        uint256 extensionPeriodHours; // the number of hours an auction is extended by if the bid comes in within the last extensionPeriodHours of the auction.
        uint256 minimumBidIncrement; // number divided by 10,000,000. For example, to require a 10% increase on each bid means the new bid is 1.1 times the prior bid so minimumBidIncrement would be 11,000,000
        address bidToken; 
        uint256 maximumBidIncrement;
    }
    address public GAINFUL_AUCTION_PROTOCOL_ADDRESS;
    uint256 public BID_FEE;
    mapping(string => AuctionData) public AUCTION_DATABASE; // Record of Auctions

    /**
        @notice Starts an auction for an NFT with auction parameters.
        @param auction_name The name of the auction to be started.
        @param starting_price The initial minimum bid.
        @param uri_path The nft uri path
        @param auctionDurationHours Number of Hours the auction is scheduled to last
        @param extensionPeriodHours The number of hours until auctionEndTimestamp during which a new bid extends the auction end time by extensionPeriodHours. For example if it is 1, if a new bid comes in during the last hour, the auctionEndTimestamp is pushed later by an hour.
        @param minimumBidIncrement the minimum amount that each consecutive bid must be relative to the prior bid. Percent when divided by 10,000,000.
        @param bidDifferenceSplit The basis points of bid difference shared with prior bidder.
        */
    function startAuction(string memory auction_name,uint256 starting_price,string memory uri_path, uint256 auctionDurationHours, uint256 extensionPeriodHours, uint256 minimumBidIncrement, uint256 bidDifferenceSplit, address bidToken, uint256 maximumBidIncrement) external nonReentrant onlyOwner {
        AuctionData storage td = AUCTION_DATABASE[auction_name];
        require(td.auctionStarted == false, "This auction has already started");
        require(bidDifferenceSplit<=10000-BID_FEE);
        td.auctionStarted = true;
        td.bidAmount = 0;
        td.latestBidder = msg.sender;
        td.auctionEndTimestamp = block.timestamp + (auctionDurationHours * 1 hours);
        td.uriPath = uri_path;
        td.startingPrice = starting_price;
        td.auctionDurationHours = auctionDurationHours;
        td.extensionPeriodHours = extensionPeriodHours;
        td.minimumBidIncrement = minimumBidIncrement;
        td.maximumBidIncrement = maximumBidIncrement;
        td.bidDifferenceSplit = bidDifferenceSplit;
        td.bidToken = bidToken;
        emit AuctionStarted(auction_name,msg.sender,starting_price,block.timestamp);
    }
    function getMinBid(string memory auction_name) public view returns (uint256 ){
        AuctionData storage td = AUCTION_DATABASE[auction_name];
        if (td.bidAmount==0) {
            return td.startingPrice;
        }
        else {
            return td.bidAmount * td.minimumBidIncrement / 10000000;
        }
    }

    /**
        @notice Places a bid on an ongoing auction with a specified bid amount.
        @dev This function allows a user to bid on an ongoing auction.
        It requires that the auction has already started, and has not already ended.
        The bid amount must be at least 10% larger than the previous bid.
        The function checks if the current time is within the auction duration and extends the duration if a bid is placed within the extension period.
        The latest latestBidder receives their bid amount back, plus half the difference between the new bid and their latest bid. For example, if you bid 100 and then someone else bids 110, the difference is 10 so you get back 105 (your original 100 + 10/2 and the auctioneer getsthe remaining 5. 
        The function updates the auction details in the AUCTION_DATABASE mapping and emits a Bid event.
        @param auction_name The name of the auction for which the bid is placed.

        */
    function bid(string memory auction_name, uint256 bidAmount) external payable nonReentrant {
        AuctionData storage td = AUCTION_DATABASE[auction_name]; // Get auction data
        uint256 bid_amount;
        bool is_eth = (td.bidToken==address(0));
        if (is_eth) { bid_amount = msg.value;}
        else { bid_amount = bidAmount; }
        
        require(td.auctionStarted == true,"This auction must have been started already"); // Ensure that the auction has already started.
        require(td.auctionEnded == false, "This auction must not have been ended."); // Ensure that the auction has not already ended.
        require(bid_amount >= td.startingPrice, "Must exceed starting bid.");
        uint256 minimum_bid = td.bidAmount * td.minimumBidIncrement / 10000000;
        uint256 maximum_bid;
        if (td.bidAmount==0) {
            maximum_bid = td.startingPrice;
        }
        else {
            maximum_bid = td.bidAmount * td.maximumBidIncrement / 10000000;
        }
        
        
        require(bid_amount >= minimum_bid ,"Bid must be larger than prior bid, in an amount defined by minimumBidIncrement."); // Ensure that the bid meets the size requirement.
        require(bid_amount<=maximum_bid, "Bid must be smaller than prior bid, in an amount defined by maximumBidIncrement");
        require(block.timestamp <= td.auctionEndTimestamp, "Auction is over"); // Ensure that the auction has not exceeded its deadline.
        uint256 extension_seconds = td.extensionPeriodHours * 1 hours;
        if (td.auctionEndTimestamp - block.timestamp < extension_seconds) { //If new bid comes in during the extension period...
            td.auctionEndTimestamp += extension_seconds;// ... extend the auction by the number of seconds equal to the extension period.
        }
        uint256 to_last_bidder;
        uint256 to_protocol;
        uint256 to_auctioneer;
        (to_last_bidder, to_protocol, to_auctioneer) = calculateDistribution(bid_amount, td.bidAmount, td.bidDifferenceSplit);
        if (is_eth) {
            sendIt(payable(GAINFUL_AUCTION_PROTOCOL_ADDRESS), to_protocol);
            sendIt(payable(td.latestBidder), td.bidAmount + to_last_bidder); // send last bidder their bid back plus half the difference between their bid and the new bid.
            sendIt(payable(owner()), to_auctioneer); // send auctioneer the other half of the difference between bids.
        }
        else {
            IERC20 token = IERC20(td.bidToken);
            token.safeTransferFrom(msg.sender, address(this), bid_amount);
            token.transfer(GAINFUL_AUCTION_PROTOCOL_ADDRESS, to_protocol);
            token.transfer(td.latestBidder, td.bidAmount + to_last_bidder); 
            token.transfer(owner(), to_auctioneer);
        }
        td.bidAmount = bid_amount; // update the bid record
        td.latestBidder = msg.sender; // set the new bidder to be the latestBidder.
        emit Bid(auction_name, msg.sender, bid_amount, block.timestamp);
    }
    
    function calculateDistribution(uint256 bid_amount, uint256 latest_bid, uint256 bid_difference_split) public view returns (uint256 _to_last_bidder, uint256 _to_protocol, uint256 _to_auctioneer ) {
        uint256 s=10**8;
        uint256 difference = bid_amount - latest_bid; // measure difference between new bid and latest bid.
        uint256 to_last_bidder_scaled = s * difference * bid_difference_split /10000; // prior top bidder gets half of the difference between new bid and prior bid.
        uint256 to_last_bidder = to_last_bidder_scaled / s;
        uint256 to_protocol_scaled = s* difference * BID_FEE/10000;
        uint256 to_protocol = to_protocol_scaled / s;
        uint256 to_auctioneer = difference - (to_last_bidder+to_protocol);  // auctioneer gets half of the difference between new bid and prior bid.
        return (to_last_bidder, to_protocol, to_auctioneer);
    }

    function sendIt(address payable _to, uint256 amount) private {
        (bool sent, ) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    /**
        @notice Ends an ongoing auction.
        @dev This function ends an auction that has already started and has reached its deadline.
        The function marks the auction as ended, mints an NFT for the winning bidder (the latestBidder),
        and emits an AuctionEnded and MintNFT events.
        This function can only be called after the auction has ended and cannot be called if the auction has already been marked as ended.
        @param auction_name The name of the auction to be ended.
        */
    function endAuction(string memory auction_name) public nonReentrant {
        AuctionData storage td = AUCTION_DATABASE[auction_name];
        require(td.auctionStarted == true,"Auction must have already started.");
        require(block.timestamp > td.auctionEndTimestamp,"Auction must be over to end.");
        require(td.auctionEnded == false, "Auction has already been ended.");
        uint256 nft_id = mintNft(td.latestBidder, td.uriPath);
        td.auctionEnded = true;
        //IERC20 token = IERC20(td.bidToken);
        //token.transfer(td.latestBidder, token.balanceOf(address(this)));
        emit AuctionEnded(auction_name, msg.sender, td.latestBidder, td.bidAmount);
        emit MintNFT(td.latestBidder, auction_name, nft_id);
    }
    
    function mintNft(address to, string memory uri) private returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }
}
interface iGOFURS {
    function ownerOf(uint256 id) external view returns (address owner);
    function minted() external view returns (uint256);
}

