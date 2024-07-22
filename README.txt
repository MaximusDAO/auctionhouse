# Gainful Auction Protocol

The Gainful Auction Protocol introduces a format for trustless auctions designed to:

- reward auction participation
- drive engagement around the auctioned item
- efficiently establish auction settlement price

This is achieved through a simple yet powerful proceeds sharing model where any given bidder either wins the auction or gets their money back, plus a premium.

### How it works

- The Auctioneer starts an auction by defining:
    1. The prize, such as an NFT
    2. The minimum starting bid amount
    3. The Minimum Bid Increment as a percent
    4. The Bid Difference Split as a percent
    5. The auction duration as a number of hours
    6. The auction extension period as a number of hours 
- Each new bid must be larger than the prior bid by the Minimum Bid Increment.
- When a new bid is placed, the prior bidder gets back their bid amount. Then, the difference between the new bid and the prior bid is distributed between  the auctioneer and the prior bidder per the Bid Difference Split of that auction.
- If a new bid occurs during the Auction Extension Period, which is the last X hours of the auction as defined by the auctioneer, The auction is extended by X hours. This may be repeated until no new bids are placed.

![In this example, in an auction with a bid difference split of 50%, the prior bid of 5 ETH was outbid by a new bid of 5.5 ETH. The 0.5 ETH difference is split between the prior bidder and the auctioneer. The prior bidder gets their 5 ETH back plus 0.25 ETH premium, netting a 5% return on their bid. ](https://prod-files-secure.s3.us-west-2.amazonaws.com/ffd7d877-a7ee-48a3-ac90-a600779dcddb/1770c084-4610-479b-a992-10dc3a4f0e6c/52670E35-A0B5-4A2A-A99B-0E17FB720778.png)

In this example, in an auction with a bid difference split of 50%, the prior bid of 5 ETH was outbid by a new bid of 5.5 ETH. The 0.5 ETH difference is split between the prior bidder and the auctioneer. The prior bidder gets their 5 ETH back plus 0.25 ETH premium, netting a 5% return on their bid. 

### Example Story

Gizmo Furnandez decides to publish his poem about a long lost lover as an NFT and wants to auction it off. So he deploys a smart contract which follows the Gainful Auction protocol. 

Through this smart contract he starts an auction with the parameters:

- Auction duration: 48 hours
- Extension Period Duration: 2 hours
- Minimum Starting Bid: 1 ETH
- Minimum Bid Increment: 10%
- Bid Difference Split: 40%
    - This means that 40% of the difference goes to the prior bidder and 60% goes to the auctioneer.

Next, his friend Rusty decides to place the initial bid of 1 ETH. Since there are no prior bids, Gizmo gets sent the 1 ETH.  

Then Camo sees the auction and doesn’t necessarily want the NFT but he speculates that someone else will and would bid after him, so he bids the new minimum bid of 1.1 ETH, so Rusty gets his original 1 ETH plus 0.04 ETH (initial bid amount plus 40% of the difference in bids) and Gizmo gets 0.06 ETH. 

Minty then decides to flex and bids 4 ETH, a difference in 2.9 ETH from Camo’s bid! So Gizmo gets 1.74 ETH and Camo gets 2.26 ETH (his original 1.1 ETH bid plus 40% of the difference between 4 and 1.1). When people bid much higher than the minimum, the prior bidder experiences higher than normal premium. 

With 1 hour left in the auction, Neon decides to bid 4.4 ETH. Gizmo gets 0.24 ETH and Minty gets back 4.16 ETH. Since the bid is within the 2 hour Auction Extension Period, the new end of auction deadline is extended by 2 hours from the original end deadline. This means from the moment Neon’s bid went through there are now 3 hours left in the auction (1 hour originally remaining plus 2 hours extended). 

moments later Minty bids again with 4.84 ETH so Gizmo receives 0.264 ETH and Neon receives 4.576 ETH. Since this bid is not within the Auction Extension Period the auction is not extended. 

No further bids were cast so the auction ended with the NFT being minted to the wallet Minty was bidding from. She gloated in her victory, reminding the others “was it even a question whether or not I would win?” 

Key Takeaways:

- In total the auctioneer receives an amount equal to: **Minimum Starting Bid + [(1 - Bid Difference Split)*(Final Winning Bid - Minimum Starting Bid)]**
- All participants who didn’t win the auction get their money back plus a premium which is at least the Bid Difference Split times the Minimum Bid Increment, but can be higher if the next bid is higher than the Minimum Bid Increment.