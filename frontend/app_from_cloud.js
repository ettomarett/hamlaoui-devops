// Configuration
const API_CONFIG = {
    PRODUCT_SERVICE: 'http://20.86.144.152:8080',
    INVENTORY_SERVICE: 'http://20.86.144.152:8080', 
    ORDER_SERVICE: 'http://20.86.144.152:8080'
};

// Global state
let orderItemCount = 1;

// DOM Elements
const notifications = document.getElementById('notifications');

// Initialize application
document.addEventListener('DOMContentLoaded', function() {
    checkServiceHealth();
    loadProducts();
    setupEventListeners();
});

// Service Health Check
async function checkServiceHealth() {
    const services = [
        { name: 'product', url: `${API_CONFIG.PRODUCT_SERVICE}/actuator/health`, elementId: 'product-status' },
        { name: 'inventory', url: `${API_CONFIG.INVENTORY_SERVICE}/actuator/health`, elementId: 'inventory-status' },
        { name: 'order', url: `${API_CONFIG.ORDER_SERVICE}/actuator/health`, elementId: 'order-status' }
    ];

    for (const service of services) {
        try {
            const response = await fetch(service.url, { 
                method: 'GET',
                mode: 'cors',
                headers: {
                    'Content-Type': 'application/json',
                }
            });
            
            const element = document.getElementById(service.elementId);
            if (response.ok) {
                element.classList.remove('offline');
                showNotification(`${service.name} service is online`, 'success');
            } else {
                element.classList.add('offline');
                showNotification(`${service.name} service is offline`, 'error');
            }
        } catch (error) {
            const element = document.getElementById(service.elementId);
            element.classList.add('offline');
            console.error(`Error checking ${service.name} service:`, error);
        }
    }
}

// Tab Management
function showTab(tabName) {
    // Hide all tab contents
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // Remove active class from all tab buttons
    document.querySelectorAll('.tab-button').forEach(button => {
        button.classList.remove('active');
    });
    
    // Show selected tab content
    document.getElementById(`${tabName}-tab`).classList.add('active');
    
    // Add active class to clicked button
    event.target.classList.add('active');
    
    // Load appropriate data
    if (tabName === 'products') {
        loadProducts();
    }
}

// Product Management
async function loadProducts() {
    const productsList = document.getElementById('products-list');
    
    try {
        productsList.innerHTML = `
            <div class="loading-spinner">
                <i class="fas fa-spinner fa-spin"></i>
                <p>Loading products...</p>
            </div>
        `;

        const response = await fetch(`${API_CONFIG.PRODUCT_SERVICE}/api/product/allProducts`, {
            method: 'GET',
            mode: 'cors',
            headers: {
                'Content-Type': 'application/json',
            }
        });

        if (response.ok) {
            const products = await response.json();
            displayProducts(products);
        } else {
            productsList.innerHTML = `
                <div class="text-muted">
                    <i class="fas fa-exclamation-triangle"></i>
                    <p>Unable to load products. Please check if the product service is running.</p>
                    <button class="btn btn-primary" onclick="loadProducts()">
                        <i class="fas fa-refresh"></i> Retry
                    </button>
                </div>
            `;
        }
    } catch (error) {
        console.error('Error loading products:', error);
        productsList.innerHTML = `
            <div class="text-muted">
                <i class="fas fa-exclamation-triangle"></i>
                <p>No products found. Create your first product to get started!</p>
            </div>
        `;
    }
}

function displayProducts(products) {
    const productsList = document.getElementById('products-list');
    
    if (products.length === 0) {
        productsList.innerHTML = `
            <div class="text-muted">
                <i class="fas fa-box-open"></i>
                <p>No products found. Create your first product to get started!</p>
            </div>
        `;
        return;
    }

    const productsHTML = products.map(product => `
        <div class="product-card">
            <h3>${product.name}</h3>
            <p>${product.description}</p>
            <div class="product-price">$${product.price}</div>
            <div style="display: flex; gap: 10px;">
                <button class="btn btn-info" onclick="editProduct('${product.id}')">
                    <i class="fas fa-edit"></i> Edit
                </button>
                <button class="btn btn-secondary" onclick="deleteProduct('${product.id}')">
                    <i class="fas fa-trash"></i> Delete
                </button>
            </div>
        </div>
    `).join('');

    productsList.innerHTML = productsHTML;
}

// Product Form Management
function showAddProductForm() {
    document.getElementById('add-product-form').style.display = 'block';
    document.getElementById('productName').focus();
}

function hideAddProductForm() {
    document.getElementById('add-product-form').style.display = 'none';
    document.getElementById('productForm').reset();
}

// Inventory Management
function showInventoryCheck() {
    document.getElementById('inventory-check-form').style.display = 'block';
    document.getElementById('skuCodes').focus();
}

function hideInventoryCheck() {
    document.getElementById('inventory-check-form').style.display = 'none';
    document.getElementById('inventoryForm').reset();
}

async function checkInventory(skuCodes) {
    const resultsContainer = document.getElementById('inventory-results');
    
    try {
        resultsContainer.innerHTML = `
            <div class="loading-spinner">
                <i class="fas fa-spinner fa-spin"></i>
                <p>Checking inventory...</p>
            </div>
        `;

        const skuParams = skuCodes.map(sku => `skuCode=${encodeURIComponent(sku.trim())}`).join('&');
        const response = await fetch(`${API_CONFIG.INVENTORY_SERVICE}/api/inventory?${skuParams}`, {
            method: 'GET',
            mode: 'cors',
            headers: {
                'Content-Type': 'application/json',
            }
        });

        if (response.ok) {
            const inventoryData = await response.json();
            displayInventoryResults(inventoryData);
        } else {
            resultsContainer.innerHTML = `
                <div class="order-error">
                    <i class="fas fa-exclamation-triangle"></i>
                    <p>Unable to check inventory. Service may be unavailable.</p>
                </div>
            `;
        }
    } catch (error) {
        console.error('Error checking inventory:', error);
        resultsContainer.innerHTML = `
            <div class="order-error">
                <i class="fas fa-exclamation-triangle"></i>
                <p>Error checking inventory: ${error.message}</p>
            </div>
        `;
    }
}

function displayInventoryResults(inventoryData) {
    const resultsContainer = document.getElementById('inventory-results');
    
    if (inventoryData.length === 0) {
        resultsContainer.innerHTML = `
            <div class="text-muted">
                <i class="fas fa-search"></i>
                <p>No inventory data found for the specified SKU codes.</p>
            </div>
        `;
        return;
    }

    const inventoryHTML = inventoryData.map(item => `
        <div class="inventory-item ${item.inStock ? 'in-stock' : 'out-of-stock'}">
            <div>
                <strong>${item.skuCode}</strong>
                <small style="display: block; color: #666;">SKU Code</small>
            </div>
            <div class="stock-badge ${item.inStock ? 'available' : 'unavailable'}">
                ${item.inStock ? 'In Stock' : 'Out of Stock'}
            </div>
        </div>
    `).join('');

    resultsContainer.innerHTML = inventoryHTML;
}

// Order Management
function showCreateOrderForm() {
    document.getElementById('create-order-form').style.display = 'block';
}

function hideCreateOrderForm() {
    document.getElementById('create-order-form').style.display = 'none';
    document.getElementById('orderForm').reset();
    // Reset order items to just one
    orderItemCount = 1;
    const orderItems = document.getElementById('order-items');
    orderItems.innerHTML = `
        <div class="order-item">
            <h4>Order Item 1</h4>
            <div class="form-row">
                <div class="form-group">
                    <label>SKU Code</label>
                    <input type="text" name="skuCode" placeholder="iphone_13" required>
                </div>
                <div class="form-group">
                    <label>Quantity</label>
                    <input type="number" name="quantity" min="1" value="1" required>
                </div>
                <div class="form-group">
                    <label>Price ($)</label>
                    <input type="number" name="price" step="0.01" placeholder="999.99" required>
                </div>
            </div>
        </div>
    `;
}

function addOrderItem() {
    orderItemCount++;
    const orderItems = document.getElementById('order-items');
    
    const newItem = document.createElement('div');
    newItem.className = 'order-item';
    newItem.innerHTML = `
        <h4>Order Item ${orderItemCount}</h4>
        <div class="form-row">
            <div class="form-group">
                <label>SKU Code</label>
                <input type="text" name="skuCode" placeholder="iphone_14" required>
            </div>
            <div class="form-group">
                <label>Quantity</label>
                <input type="number" name="quantity" min="1" value="1" required>
            </div>
            <div class="form-group">
                <label>Price ($)</label>
                <input type="number" name="price" step="0.01" placeholder="1099.99" required>
            </div>
        </div>
    `;
    
    orderItems.appendChild(newItem);
}

async function createOrder(orderData) {
    const resultsContainer = document.getElementById('order-results');
    
    try {
        resultsContainer.innerHTML = `
            <div class="loading-spinner">
                <i class="fas fa-spinner fa-spin"></i>
                <p>Processing order...</p>
            </div>
        `;

        const response = await fetch(`${API_CONFIG.ORDER_SERVICE}/api/order/create`, {
            method: 'POST',
            mode: 'cors',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(orderData)
        });

        if (response.ok) {
            const result = await response.text();
            resultsContainer.innerHTML = `
                <div class="order-success">
                    <i class="fas fa-check-circle"></i>
                    <h3>Order Placed Successfully!</h3>
                    <p>${result}</p>
                </div>
            `;
            showNotification('Order placed successfully!', 'success');
            hideCreateOrderForm();
        } else {
            const errorText = await response.text();
            resultsContainer.innerHTML = `
                <div class="order-error">
                    <i class="fas fa-exclamation-triangle"></i>
                    <h3>Order Failed</h3>
                    <p>${errorText}</p>
                </div>
            `;
        }
    } catch (error) {
        console.error('Error creating order:', error);
        resultsContainer.innerHTML = `
            <div class="order-error">
                <i class="fas fa-exclamation-triangle"></i>
                <h3>Order Failed</h3>
                <p>Error: ${error.message}</p>
            </div>
        `;
    }
}

// Event Listeners Setup
function setupEventListeners() {
    // Product Form
    document.getElementById('productForm').addEventListener('submit', async function(e) {
        e.preventDefault();
        
        const productData = {
            name: document.getElementById('productName').value,
            description: document.getElementById('productDescription').value,
            price: parseFloat(document.getElementById('productPrice').value)
        };

        try {
            const response = await fetch(`${API_CONFIG.PRODUCT_SERVICE}/api/product/create`, {
                method: 'POST',
                mode: 'cors',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(productData)
            });

            if (response.ok) {
                showNotification('Product created successfully!', 'success');
                hideAddProductForm();
                loadProducts(); // Reload products list
            } else {
                const errorText = await response.text();
                showNotification(`Error creating product: ${errorText}`, 'error');
            }
        } catch (error) {
            console.error('Error creating product:', error);
            showNotification(`Error creating product: ${error.message}`, 'error');
        }
    });

    // Inventory Form
    document.getElementById('inventoryForm').addEventListener('submit', function(e) {
        e.preventDefault();
        
        const skuCodesInput = document.getElementById('skuCodes').value;
        const skuCodes = skuCodesInput.split(',').map(sku => sku.trim()).filter(sku => sku.length > 0);
        
        if (skuCodes.length > 0) {
            checkInventory(skuCodes);
            hideInventoryCheck();
        } else {
            showNotification('Please enter at least one SKU code', 'error');
        }
    });

    // Order Form
    document.getElementById('orderForm').addEventListener('submit', function(e) {
        e.preventDefault();
        
        const orderItems = [];
        const orderItemsElements = document.querySelectorAll('.order-item');
        
        orderItemsElements.forEach(item => {
            const skuCode = item.querySelector('input[name="skuCode"]').value;
            const quantity = parseInt(item.querySelector('input[name="quantity"]').value);
            const price = parseFloat(item.querySelector('input[name="price"]').value);
            
            orderItems.push({
                skuCode: skuCode,
                quantity: quantity,
                price: price
            });
        });

        const orderData = {
            orderLineItemsListDto: orderItems
        };

        createOrder(orderData);
    });
}

// Notification System
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    
    const icon = type === 'success' ? 'check-circle' : 
                 type === 'error' ? 'exclamation-circle' : 
                 'info-circle';
    
    notification.innerHTML = `
        <i class="fas fa-${icon}"></i>
        <span>${message}</span>
    `;
    
    notifications.appendChild(notification);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        notification.remove();
    }, 5000);
}

// Placeholder functions for edit/delete (to be implemented)
function editProduct(productId) {
    showNotification('Edit product feature coming soon!', 'info');
}

function deleteProduct(productId) {
    showNotification('Delete product feature coming soon!', 'info');
}

// Refresh services health every 30 seconds
setInterval(checkServiceHealth, 30000); 
// Fixed Tab Management for current HTML structure
function showTab(tabName) {
    // Hide all tab contents
    document.querySelectorAll('.tab-content').forEach(tab => {
        tab.classList.remove('active');
    });
    
    // Remove active class from all tab buttons
    document.querySelectorAll('.tab-btn').forEach(button => {
        button.classList.remove('active');
    });
    
    // Show selected tab content
    document.getElementById(tabName).classList.add('active');
    
    // Add active class to clicked button
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
}

// Setup tab button event listeners
function setupTabListeners() {
    document.querySelectorAll('.tab-btn').forEach(button => {
        button.addEventListener('click', function() {
            const tabName = this.getAttribute('data-tab');
            showTab(tabName);
        });
    });
}

// Enhanced DOMContentLoaded event to include tab setup
document.addEventListener('DOMContentLoaded', function() {
    setupTabListeners(); // Add tab functionality
    checkServiceHealth();
    loadProducts();
    setupEventListeners();
});

// Fix for current HTML structure - override incompatible functions
function hideAddProductForm() {
    // Just reset the form since it's always visible in current structure
    document.getElementById('productForm').reset();
}

// Create notifications container if it doesn't exist
function ensureNotificationsContainer() {
    let notifications = document.getElementById('notifications');
    if (!notifications) {
        notifications = document.createElement('div');
        notifications.id = 'notifications';
        notifications.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 1000;
            max-width: 300px;
        `;
        document.body.appendChild(notifications);
    }
    return notifications;
}

// Enhanced showNotification that works with current structure
function showNotification(message, type = 'info') {
    const notifications = ensureNotificationsContainer();
    
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.style.cssText = `
        background: ${type === 'success' ? '#d4edda' : type === 'error' ? '#f8d7da' : '#d1ecf1'};
        color: ${type === 'success' ? '#155724' : type === 'error' ? '#721c24' : '#0c5460'};
        border: 1px solid ${type === 'success' ? '#c3e6cb' : type === 'error' ? '#f5c6cb' : '#bee5eb'};
        padding: 10px 15px;
        margin-bottom: 10px;
        border-radius: 4px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        animation: slideIn 0.3s ease-out;
    `;

    const icon = type === 'success' ? 'check-circle' :
                 type === 'error' ? 'exclamation-circle' :
                 'info-circle';

    notification.innerHTML = `
        <i class="fas fa-${icon}" style="margin-right: 8px;"></i>
        <span>${message}</span>
    `;

    notifications.appendChild(notification);

    // Auto remove after 5 seconds
    setTimeout(() => {
        if (notification.parentNode) {
            notification.remove();
        }
    }, 5000);
}

// Add CSS for notification animations
if (!document.getElementById('notification-styles')) {
    const style = document.createElement('style');
    style.id = 'notification-styles';
    style.textContent = `
        @keyframes slideIn {
            from { transform: translateX(100%); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }
    `;
    document.head.appendChild(style);
}

// Fix for current HTML structure - override incompatible functions
function hideAddProductForm() {
    // Just reset the form since it's always visible in current structure
    document.getElementById('productForm').reset();
}

// Create notifications container if it doesn't exist
function ensureNotificationsContainer() {
    let notifications = document.getElementById('notifications');
    if (!notifications) {
        notifications = document.createElement('div');
        notifications.id = 'notifications';
        notifications.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 1000;
            max-width: 300px;
        `;
        document.body.appendChild(notifications);
    }
    return notifications;
}

// Enhanced showNotification that works with current structure
function showNotification(message, type = 'info') {
    const notifications = ensureNotificationsContainer();
    
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.style.cssText = `
        background: ${type === 'success' ? '#d4edda' : type === 'error' ? '#f8d7da' : '#d1ecf1'};
        color: ${type === 'success' ? '#155724' : type === 'error' ? '#721c24' : '#0c5460'};
        border: 1px solid ${type === 'success' ? '#c3e6cb' : type === 'error' ? '#f5c6cb' : '#bee5eb'};
        padding: 10px 15px;
        margin-bottom: 10px;
        border-radius: 4px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        animation: slideIn 0.3s ease-out;
    `;

    const icon = type === 'success' ? 'check-circle' :
                 type === 'error' ? 'exclamation-circle' :
                 'info-circle';

    notification.innerHTML = `
        <i class="fas fa-${icon}" style="margin-right: 8px;"></i>
        <span>${message}</span>
    `;

    notifications.appendChild(notification);

    // Auto remove after 5 seconds
    setTimeout(() => {
        if (notification.parentNode) {
            notification.remove();
        }
    }, 5000);
}

// Add CSS for notification animations
if (!document.getElementById('notification-styles')) {
    const style = document.createElement('style');
    style.id = 'notification-styles';
    style.textContent = `
        @keyframes slideIn {
            from { transform: translateX(100%); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }
    `;
    document.head.appendChild(style);
}

// SKU List Functionality
async function showSkuList() {
    try {
    } catch (error) { console.error(Error:, error); }
}
// SKU List Functionality
async function showSkuList() {
}
