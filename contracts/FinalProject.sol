// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MjMarketplace {
    address public owner;
    uint256 public productCount = 0;

    enum OrderStatus{
        Listed,
        Paid,
        Shipped,
        Completed,
        Cancelled
    }

    struct Product {
        uint256 id;
        string name;
        string description;
        string imageUrl; 
        uint256 price;   
        address payable seller;
        address buyer;
        OrderStatus status;
        bytes32 shippingAddressHash;
    }

    mapping(uint256 => Product) public products;

    event ProductCreated(uint256 id, string name, string imageUrl, uint256 price, address seller);
    event ProductPurchased(uint256 id, address buyer, address seller, uint256 price);
    event ProductShipped(uint256 id);
    event DeliveryConfirmed(uint256 id, address buyer, address seller, uint256 price);
    event OrderCancelled(uint256 id, address buyer, uint256 refund);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;

        _seedProduct(
            "Michael Jackson's White Glove",
            "The iconic sparkly white glove worn during the Motown 25 performance. Certified authentic.",
            "https://imgs.smoothradio.com/images/141027?width=1920&crop=16_9&signature=Hbk-Y2nksz9lt1GkyUBtP1fHb1A=",
            0.05 ether
        );
        _seedProduct(
            "Thriller Vinyl - Original 1982",
            "Original gatefold pressing of the best-selling album of all time. Near Mint condition.",
            "https://preview.redd.it/michael-jackson-thriller-1982-hong-kong-pressing-v0-uz6aki5liqxa1.jpg?width=640&crop=smart&auto=webp&s=1d4177334d86e07332c229534c99ccbf0f2e268e",
            0.02 ether
        );
        _seedProduct(
            "Bad World Tour Fedora",
            "Black wool fedora hat, custom-made for the 1987-1989 World Tour. Signed by the King of Pop.",
            "https://www.mjworld.net/wp-content/uploads/billie-jean-bad-tour.jpg",
            0.1 ether
        );
    }

    function _seedProduct(
        string memory _name,
        string memory _description,
        string memory _imageUrl,
        uint256 _price
    ) private {
        productCount++;
        products[productCount] = Product(
            productCount,
            _name,
            _description,
            _imageUrl,
            _price,
            payable(owner),
            address(0),
            OrderStatus.Listed,
            bytes32(0)
        );
        emit ProductCreated(productCount, _name, _imageUrl, _price, owner);
    }

    function createProduct(
        string memory _name, 
        string memory _description, 
        string memory _imageUrl, 
        uint256 _price
    ) public onlyOwner {
        require(_price > 0, "Price must be greater than zero");
        
        productCount++;
        products[productCount] = Product(
            productCount,
            _name,
            _description,
            _imageUrl,
            _price,
            payable(msg.sender),
            address(0),
            OrderStatus.Listed,
            bytes32(0)
        );

        emit ProductCreated(productCount, _name, _imageUrl, _price, msg.sender);
    }

    function purchaseProduct(uint256 _id, bytes32 _shippingAddressHash) public payable {
        Product storage _product = products[_id];

        require(_product.id > 0 && _product.id <= productCount, "Product does not exist");
        require(_product.status == OrderStatus.Listed, "Product is not available for purchase");
        require(msg.value >= _product.price, "Not enough ether sent");
        require(_product.seller != msg.sender, "Seller cannot buy their own product");

        _product.buyer = msg.sender;
        _product.status = OrderStatus.Paid;
        _product.shippingAddressHash = _shippingAddressHash;

        if (msg.value > _product.price) {
            (bool refundOk, ) = payable(msg.sender).call{value: msg.value - _product.price}("");
            require(refundOk, "Overpayment refund failed");
        }

        emit ProductPurchased(_id, msg.sender, _product.seller, _product.price);
    }

    function markAsShipped(uint256 _id) public {
        Product storage _product = products[_id];
        require(_product.status == OrderStatus.Paid, "Order is not in Paid status");
        require(msg.sender == _product.seller, "Only seller can mark as shipped");

        _product.status = OrderStatus.Shipped;
        emit ProductShipped(_id);
    }

    function confirmDelivery(uint256 _id) public {
        Product storage _product = products[_id];
        require(_product.status == OrderStatus.Shipped, "Order has not been shipped yet");
        require(msg.sender == _product.buyer, "Only buyer can confirm delivery");

        _product.status = OrderStatus.Completed;

        (bool success, ) = _product.seller.call{value: _product.price}("");
        require(success, "Transfer to seller failed");

        emit DeliveryConfirmed(_id, _product.buyer, _product.seller, _product.price);
    }

    function cancelOrder(uint256 _id) public {
        Product storage _product = products[_id];
        require(_product.status == OrderStatus.Paid, "Order can only be cancelled before shipping");
        require(msg.sender == _product.buyer, "Only buyer can cancel this order");

        address refundTo = _product.buyer;
        uint256 refundAmount = _product.price;

        _product.status = OrderStatus.Listed;
        _product.buyer = address(0);
        _product.shippingAddressHash = bytes32(0);

        (bool success, ) = payable(refundTo).call{value: refundAmount}("");
        require(success, "Refund failed");

        emit OrderCancelled(_id, refundTo, refundAmount);
    }

    function getAllProducts() public view returns (Product[] memory) {
        Product[] memory allProducts = new Product[](productCount);
        for (uint256 i = 1; i <= productCount; i++) {
            allProducts[i - 1] = products[i];
        }
        return allProducts;
    }
}