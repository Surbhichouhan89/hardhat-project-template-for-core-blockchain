// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SupplyChainTracker
 * @dev A smart contract for tracking products in a supply chain
 */
contract SupplyChainTracker {
    address public owner;
    
    struct Product {
        uint256 id;
        string name;
        string manufacturer;
        uint256 manufactureDate;
        uint256 expiryDate;
        address currentOwner;
        Stage currentStage;
        mapping(uint256 => LocationHistory) locationHistory;
        uint256 locationCount;
    }
    
    struct LocationHistory {
        string location;
        uint256 timestamp;
        address handler;
    }
    
    enum Stage { 
        Manufactured,
        InTransit,
        Delivered,
        Sold
    }
    
    mapping(uint256 => Product) public products;
    uint256 public productCount;
    
    event ProductCreated(uint256 indexed productId, string name, address manufacturer);
    event ProductLocationUpdated(uint256 indexed productId, string location, address handler);
    event ProductStageChanged(uint256 indexed productId, Stage newStage);
    
    constructor() {
        owner = msg.sender;
        productCount = 0;
    }
    
    /**
     * @dev Creates a new product in the supply chain
     * @param _name Name of the product
     * @param _manufacturer Manufacturer's name
     * @param _expiryDate Expiry date as Unix timestamp
     */
    function createProduct(
        string memory _name,
        string memory _manufacturer,
        uint256 _expiryDate,
        string memory _initialLocation
    ) public returns (uint256) {
        require(_expiryDate > block.timestamp, "Expiry date must be in the future");
        
        productCount++;
        uint256 productId = productCount;
        
        Product storage newProduct = products[productId];
        newProduct.id = productId;
        newProduct.name = _name;
        newProduct.manufacturer = _manufacturer;
        newProduct.manufactureDate = block.timestamp;
        newProduct.expiryDate = _expiryDate;
        newProduct.currentOwner = msg.sender;
        newProduct.currentStage = Stage.Manufactured;
        
        // Add initial location
        newProduct.locationHistory[0] = LocationHistory({
            location: _initialLocation,
            timestamp: block.timestamp,
            handler: msg.sender
        });
        newProduct.locationCount = 1;
        
        emit ProductCreated(productId, _name, msg.sender);
        emit ProductLocationUpdated(productId, _initialLocation, msg.sender);
        
        return productId;
    }
    
    /**
     * @dev Updates the location of a product in the supply chain
     * @param _productId The product ID
     * @param _newLocation New location information
     */
    function updateProductLocation(uint256 _productId, string memory _newLocation) public {
        require(_productId > 0 && _productId <= productCount, "Invalid product ID");
        
        Product storage product = products[_productId];
        
        product.locationHistory[product.locationCount] = LocationHistory({
            location: _newLocation,
            timestamp: block.timestamp,
            handler: msg.sender
        });
        product.locationCount++;
        
        emit ProductLocationUpdated(_productId, _newLocation, msg.sender);
    }
    
    /**
     * @dev Changes the current stage of a product in the supply chain
     * @param _productId The product ID
     * @param _newStage New stage of the product
     */
    function updateProductStage(uint256 _productId, Stage _newStage) public {
        require(_productId > 0 && _productId <= productCount, "Invalid product ID");
        
        Product storage product = products[_productId];
        require(uint8(_newStage) > uint8(product.currentStage), "Cannot revert to a previous stage");
        
        product.currentStage = _newStage;
        
        emit ProductStageChanged(_productId, _newStage);
    }
    
    /**
     * @dev Get product details
     * @param _productId The product ID
     * @return id Product ID
     * @return name Product name
     * @return manufacturer Manufacturer name
     * @return manufactureDate Date of manufacture
     * @return expiryDate Expiry date
     * @return currentOwner Current owner address
     * @return currentStage Current stage in the supply chain
     */
    function getProductDetails(uint256 _productId) public view returns (
        uint256 id,
        string memory name,
        string memory manufacturer,
        uint256 manufactureDate,
        uint256 expiryDate,
        address currentOwner,
        Stage currentStage
    ) {
        require(_productId > 0 && _productId <= productCount, "Invalid product ID");
        
        Product storage product = products[_productId];
        
        return (
            product.id,
            product.name,
            product.manufacturer,
            product.manufactureDate,
            product.expiryDate,
            product.currentOwner,
            product.currentStage
        );
    }
    
    /**
     * @dev Get location history entry for a product
     * @param _productId The product ID
     * @param _index The index of the location history entry
     * @return location The location
     * @return timestamp The timestamp when product was at this location
     * @return handler The handler at this location
     */
    function getLocationHistory(uint256 _productId, uint256 _index) public view returns (
        string memory location,
        uint256 timestamp,
        address handler
    ) {
        require(_productId > 0 && _productId <= productCount, "Invalid product ID");
        Product storage product = products[_productId];
        require(_index < product.locationCount, "Invalid location index");
        
        LocationHistory storage history = product.locationHistory[_index];
        
        return (
            history.location,
            history.timestamp,
            history.handler
        );
    }
    
    /**
     * @dev Transfer ownership of a product to another address
     * @param _productId The product ID
     * @param _newOwner The address of the new owner
     */
    function transferOwnership(uint256 _productId, address _newOwner) public {
        require(_productId > 0 && _productId <= productCount, "Invalid product ID");
        Product storage product = products[_productId];
        require(product.currentOwner == msg.sender, "Only current owner can transfer ownership");
        require(_newOwner != address(0), "New owner cannot be zero address");
        
        product.currentOwner = _newOwner;
    }
}
