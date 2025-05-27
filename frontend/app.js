// Configuration - Using local proxy server
const API_CONFIG = {
    PRODUCT_SERVICE: '',
    INVENTORY_SERVICE: '', 
    ORDER_SERVICE: ''
};

// Global state
let orderItemCount = 1;

// Initialize application
document.addEventListener('DOMContentLoaded', function() {
    ensureNotificationsContainer();
    setupTabListeners();
    setupEventListeners();
    loadProducts();
});

// Ensure notifications container exists
function ensureNotificationsContainer() {
    let notifications = document.getElementById('notifications');
    if (!notifications) {
        notifications = document.createElement('div');
        notifications.id = 'notifications';
        notifications.className = 'notifications-container';
        document.body.appendChild(notifications);
    }
}

// Tab Management
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
    
    // Load appropriate data
    if (tabName === 'products') {
        loadProducts();
    }
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

// Product Management
async function loadProducts() {
    const productsList = document.getElementById('productsList');
    
    if (!productsList) {
        console.error('Products list element not found');
        return;
    }
    
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
                <i class="fas fa-box-open"></i>
                <p>No products found. Create your first product to get started!</p>
            </div>
        `;
    }
}

function displayProducts(products) {
    const productsList = document.getElementById('productsList');
    
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

// Inventory Management
async function checkInventory(skuCodes) {
    const resultsContainer = document.getElementById('inventoryResult');
    
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
    const resultsContainer = document.getElementById('inventoryResult');
    
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

// SKU List Functionality
async function showSkuList() {
    const skuSection = document.getElementById('skuListSection');
    const container = document.getElementById('skuListContainer');
    
    if (!skuSection || !container) {
        console.error('SKU list elements not found');
        return;
    }
    
    skuSection.style.display = 'block';
    
    try {
        container.innerHTML = `
            <div class="loading-spinner">
                <i class="fas fa-spinner fa-spin"></i>
                <p>Loading SKU codes...</p>
            </div>
        `;

        const response = await fetch(`${API_CONFIG.INVENTORY_SERVICE}/api/inventory?skuCode=iphone13_mini&skuCode=iphone13_pro_max`, {
            method: 'GET',
            mode: 'cors',
            headers: {
                'Content-Type': 'application/json',
            }
        });

        if (response.ok) {
            const inventoryData = await response.json();
            displaySkuList(inventoryData);
        } else {
            container.innerHTML = `
                <div class="text-muted">
                    <i class="fas fa-exclamation-triangle"></i>
                    <p>Unable to load SKU codes. Service may be unavailable.</p>
                </div>
            `;
        }
    } catch (error) {
        console.error('Error loading SKU list:', error);
        container.innerHTML = `
            <div class="text-muted">
                <i class="fas fa-exclamation-triangle"></i>
                <p>Error loading SKU codes: ${error.message}</p>
            </div>
        `;
    }
}

function displaySkuList(inventoryData) {
    const container = document.getElementById('skuListContainer');
    
    if (inventoryData.length === 0) {
        container.innerHTML = `
            <div class="text-muted">
                <i class="fas fa-box-open"></i>
                <p>No SKU codes found in inventory.</p>
            </div>
        `;
        return;
    }

    const skuHTML = inventoryData.map(item => `
        <div class="sku-item ${item.inStock ? 'in-stock' : 'out-of-stock'}" onclick="selectSku('${item.skuCode}')">
            <div class="sku-code">${item.skuCode}</div>
            <div class="stock-status ${item.inStock ? 'available' : 'unavailable'}">
                ${item.inStock ? 'Available' : 'Out of Stock'}
            </div>
        </div>
    `).join('');

    container.innerHTML = `
        <div class="sku-grid">
            ${skuHTML}
        </div>
    `;
}

function selectSku(skuCode) {
    const skuInput = document.getElementById('skuCode');
    if (skuInput) {
        skuInput.value = skuCode;
        showNotification(`SKU "${skuCode}" selected`, 'success');
    }
}

function hideSkuList() {
    const skuSection = document.getElementById('skuListSection');
    if (skuSection) {
        skuSection.style.display = 'none';
    }
}

// Order Management
function addOrderItem() {
    orderItemCount++;
    const orderItems = document.getElementById('orderItems');
    
    const newItem = document.createElement('div');
    newItem.className = 'order-item';
    newItem.innerHTML = `
        <input type="text" placeholder="SKU Code" name="skuCode" required>
        <input type="number" placeholder="Quantity" name="quantity" min="1" required>
        <button type="button" onclick="removeOrderItem(this)" class="btn btn-secondary">
            <i class="fas fa-trash"></i>
        </button>
    `;
    
    orderItems.appendChild(newItem);
}

function removeOrderItem(button) {
    const orderItem = button.parentElement;
    orderItem.remove();
}

async function createOrder(orderData) {
    const resultsContainer = document.getElementById('orderResult');
    
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
            document.getElementById('orderForm').reset();
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
    const productForm = document.getElementById('productForm');
    if (productForm) {
        productForm.addEventListener('submit', async function(e) {
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
                    productForm.reset();
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
    }

    // Inventory Form
    const inventoryForm = document.getElementById('inventoryForm');
    if (inventoryForm) {
        inventoryForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const skuCodesInput = document.getElementById('skuCode').value;
            const skuCodes = skuCodesInput.split(',').map(sku => sku.trim()).filter(sku => sku.length > 0);
            
            if (skuCodes.length > 0) {
                checkInventory(skuCodes);
            } else {
                showNotification('Please enter at least one SKU code', 'error');
            }
        });
    }

    // Order Form
    const orderForm = document.getElementById('orderForm');
    if (orderForm) {
        orderForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const orderItems = [];
            const orderItemsElements = document.querySelectorAll('#orderItems .order-item');
            
            orderItemsElements.forEach(item => {
                const skuCode = item.querySelector('input[name="skuCode"]').value;
                const quantity = parseInt(item.querySelector('input[name="quantity"]').value);
                
                if (skuCode && quantity) {
                    orderItems.push({
                        skuCode: skuCode,
                        quantity: quantity,
                        price: 99.99 // Default price - you can modify this
                    });
                }
            });

            if (orderItems.length > 0) {
                const orderData = {
                    orderLineItemsListDto: orderItems
                };
                createOrder(orderData);
            } else {
                showNotification('Please add at least one order item', 'error');
            }
        });
    }

    // Add Order Item Button
    const addOrderItemBtn = document.getElementById('addOrderItem');
    if (addOrderItemBtn) {
        addOrderItemBtn.addEventListener('click', addOrderItem);
    }

    // SKU List Button
    const showSkuListBtn = document.getElementById('showSkuListBtn');
    if (showSkuListBtn) {
        showSkuListBtn.addEventListener('click', showSkuList);
    }

    // Hide SKU List Button
    const hideSkuListBtn = document.getElementById('hideSkuListBtn');
    if (hideSkuListBtn) {
        hideSkuListBtn.addEventListener('click', hideSkuList);
    }
}

// Notification System
function showNotification(message, type = 'info') {
    const notifications = document.getElementById('notifications');
    if (!notifications) {
        console.error('Notifications container not found');
        return;
    }
    
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    
    const icon = type === 'success' ? 'check-circle' : 
                 type === 'error' ? 'exclamation-circle' : 
                 'info-circle';
    
    notification.innerHTML = `
        <i class="fas fa-${icon}"></i>
        <span>${message}</span>
        <button class="notification-close" onclick="this.parentElement.remove()">
            <i class="fas fa-times"></i>
        </button>
    `;
    
    notifications.appendChild(notification);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        if (notification.parentElement) {
            notification.remove();
        }
    }, 5000);
}

// Placeholder functions for edit/delete (to be implemented)
function editProduct(productId) {
    showNotification('Edit product feature coming soon!', 'info');
}

function deleteProduct(productId) {
    showNotification('Delete product feature coming soon!', 'info');
} 