// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error NotEnoughCost();
error NotEnoughPice();
error NotId();
contract Ebay{
    struct Auction{
        uint256 id;
        address payable seller;
        string name;
        string description;
        uint256 min;
        uint256 bestOfferId;
        uint256[] offerIds;
    }

    struct Offer{
        uint256 id;
        uint256 auctionId;
        uint256 price;
        address payable buyer;
    }

    mapping(uint256 => Auction) public auctionMap;
    mapping(uint256 => Offer) public offerMap;
    mapping(address => uint256[]) public AuctionList;
    mapping(address => uint256[]) public OfferList;

    uint256 newAuctionId =1;
    uint256 newofferId =1;

    modifier minEth(uint256 _min){
       if(_min<=0){
           revert NotEnoughCost();
       }
       _;
    }

    function createAuction(string calldata _name, string calldata _description, uint256 _min) external minEth(_min) {
        uint256[] memory _offerIds = new uint256[](0);
        auctionMap[newAuctionId] = Auction(newAuctionId, payable(msg.sender), _name, _description, _min, 0, _offerIds);
        AuctionList[msg.sender].push(newAuctionId);
        newAuctionId++;
    }

    modifier minPrice(uint256 _AuctionId){
        Auction storage newAuction = auctionMap[_AuctionId];
        Offer storage NewOffer = offerMap[newAuction.bestOfferId];
        if(msg.value < newAuction.min && msg.value < NewOffer.price){
            revert  NotEnoughPice();
        }
        _;
    }

    function createOffer(uint256 _AuctionId) public payable minPrice(_AuctionId) auctionExists(_AuctionId) {
        Auction storage newAuction = auctionMap[_AuctionId];
        // Offer storage NewOffer = offerMap[newAuction.bestOfferId];

        // require(msg.value>= newAuction.min && msg.value > NewOffer.price);
        newAuction.bestOfferId=newofferId;
        newAuction.offerIds.push(newofferId);

        offerMap[newofferId] = Offer(newofferId, _AuctionId, msg.value, payable(msg.sender));

        OfferList[msg.sender].push(newofferId);
        newofferId++;
    }

    function transfer(uint256 _AuctionId) public payable auctionExists(_AuctionId){
        Auction storage _Auction = auctionMap[_AuctionId];
        Offer storage _Offer = offerMap[_Auction.bestOfferId];
        // uint256[] memory _offerIds= newAuction.offerIds;

        for(uint256 i =0; i< _Auction.offerIds.length; i++){
           uint256  _offerId = _Auction.offerIds[i]; 
           if(_offerId != _Auction.bestOfferId){
              Offer storage offer = offerMap[_offerId];
            //   offer.buyer.transfer(offer.price);   
              (bool _callSuccess,)=  offer.buyer.call{value: offer.price}("");
              require(_callSuccess, "Call failed");
           }
        }
        // _Auction.seller.transfer(_Offer.price);
        (bool callSuccess,)=  _Auction.seller.call{value: _Offer.price}("");
        require(callSuccess, "Call failed");
    }

    function getAuctions() public view returns(Auction[] memory){
         Auction[] memory _Auction = new Auction[](newAuctionId-1);
         
         for(uint256 i=1 ; i<=_Auction.length ; i++){
             _Auction[i-1] = auctionMap[i];
         }

         return _Auction;
    }

    function getUserAuctions(address _user) public view returns(Auction[] memory){
      uint256[] storage userAuctionIds = AuctionList[_user];
    Auction[] memory _auctions = new Auction[](userAuctionIds.length);

    for(uint256 i=0; i<userAuctionIds.length; i++){
        uint256 auctionId = userAuctionIds[i];
        _auctions[i]= auctionMap[auctionId];
    }
    return _auctions;
    }

    function getuserOffers(address _user) external view returns(Offer[] memory){
    uint[] storage userOfferIds = OfferList[_user];

    Offer[] memory _offers = new Offer[](userOfferIds.length);

    for(uint i=0; i<userOfferIds.length; i++){
        uint offerId = userOfferIds[i];
        _offers[i]=offerMap[offerId];
    }

    return _offers;
}

modifier auctionExists(uint _auctionId){
    // require(_auctionId>0 && _auctionId <newAuctionId, "Auction does not exist!");
    if(_auctionId<0 && _auctionId >newAuctionId-1){
     revert NotId();
    }
    _;
}

}
