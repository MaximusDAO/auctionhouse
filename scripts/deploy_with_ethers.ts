// This script can be used to deploy the "Storage" contract using ethers.js library.
// Please make sure to compile "./contracts/1_Storage.sol" file before running this script.
// And use Right click -> "Run" from context menu of the file to run the script. Shortcut: Ctrl+Shift+S

import { deploy } from './ethers-lib'

(async () => {
  try {
    const uri = "https://super-chief-sandwich.anvil.app/_/api/metadata/";
    const auctioneer = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
    const name = "GOFURS AuctionHouse";
    const symbol = "AUCTIONHOUSE";
    const protocol = "0xfDF2e77F113a87D419b25659E8787AB019e5e0DA";
    const bid_fee=0;
    const result = await deploy('GainfulAuctionSeries2', [uri, name, symbol, auctioneer, protocol,bid_fee])
    console.log(`address: ${result.address}`)
    const auction_name = "nft";
    const starting_price = "1000000000000000000000000";
    const uri_path  = "nft.json";
    const extensionPeriodHours = 1;
    const auction_duration = 12;
    const minimum_bid_increment = 12000000;
    const maximum_bid_increment = "12001000000000000000000000";
    const bds = 5000;
    const token = "0x0000000000000000000000000000000000000000";

    await result.startAuction(auction_name, starting_price, uri_path, auction_duration, extensionPeriodHours, minimum_bid_increment, bds,token, maximum_bid_increment);
    //(string memory auction_name,uint256 starting_price,string memory uri_path, uint256 auctionDurationHours, uint256 extensionPeriodHours, uint256 minimumBidIncrement, uint256 bidDifferenceSplit, address bidToken
  } catch (e) {
    console.log(e.message)
  }
})()