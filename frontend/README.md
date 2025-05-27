# E-Commerce Microservices Frontend

A modern web interface for the Spring Boot microservices e-commerce platform.

## 🚀 Features

- **Product Management**: Create and view products
- **Inventory Checking**: Real-time stock verification
- **Order Processing**: Place orders with multiple items
- **Service Health Monitoring**: Live status of all microservices
- **Responsive Design**: Works on desktop and mobile
- **Real-time Notifications**: Success/error feedback

## 🏗️ Architecture

The frontend connects to three Spring Boot microservices:

- **Product Service** (Port 31309): Product catalog management
- **Inventory Service** (Port 31081): Stock level verification  
- **Order Service** (Port 31004): Order processing

## 🖥️ Running the Frontend

### Option 1: Simple HTTP Server (Python)

```bash
# Navigate to frontend directory
cd frontend

# Start Python HTTP server
python -m http.server 8000

# Open browser
http://localhost:8000
```

### Option 2: Live Server (VS Code)

1. Install "Live Server" extension in VS Code
2. Right-click on `index.html`
3. Select "Open with Live Server"

### Option 3: Any Static Web Server

Since this is a pure HTML/CSS/JavaScript application, you can serve it with any static web server.

## 🔧 Configuration

The API endpoints are configured in `app.js`:

```javascript
const API_CONFIG = {
    PRODUCT_SERVICE: 'http://20.86.144.152:31309',
    INVENTORY_SERVICE: 'http://20.86.144.152:31081', 
    ORDER_SERVICE: 'http://20.86.144.152:31004'
};
```

Update these URLs if your services are running on different hosts/ports.

## 🎯 Using the Application

### 1. Service Health Monitoring
- Green dots indicate services are online
- Red dots indicate services are offline
- Status updates automatically every 30 seconds

### 2. Product Management
- Click "Add Product" to create new products
- Fill in name, description, and price
- View all products in the grid layout
- Edit/Delete features coming soon

### 3. Inventory Checking
- Click "Check Stock" button
- Enter SKU codes (comma-separated)
- Example: `iphone_13, iphone_14, macbook_pro`
- View stock availability for each SKU

### 4. Order Processing
- Click "Create Order" button
- Add multiple items to the order
- Specify SKU, quantity, and price for each item
- Order validates inventory before processing

## 🛠️ CORS Configuration

For the frontend to communicate with your Spring Boot services, you may need to enable CORS in your backend services. Add this to your Spring Boot controllers:

```java
@CrossOrigin(origins = "*")
@RestController
public class YourController {
    // Your controller methods
}
```

Or configure CORS globally in your Spring Boot application:

```java
@Configuration
public class CorsConfig {
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(Arrays.asList("*"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(true);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
```

## 📱 Mobile Responsive

The interface is fully responsive and works on:
- Desktop computers
- Tablets  
- Mobile phones

## 🎨 Technologies Used

- **HTML5**: Semantic markup
- **CSS3**: Modern styling with gradients and animations
- **JavaScript**: Vanilla JS with async/await
- **Font Awesome**: Icons
- **CSS Grid & Flexbox**: Responsive layout

## 🔮 Future Enhancements

- [ ] Product edit/delete functionality
- [ ] Order history viewing
- [ ] User authentication
- [ ] Shopping cart functionality
- [ ] Inventory management interface
- [ ] Real-time notifications via WebSocket
- [ ] Dark mode toggle
- [ ] Export/import data functionality

## 🐛 Troubleshooting

### Service Status Shows Offline
- Check if Spring Boot services are running
- Verify the API URLs in `app.js`
- Check browser console for CORS errors

### Cannot Load Products
- Ensure Product Service is running on port 31309
- Check if MongoDB is connected to Product Service
- Verify CORS is enabled on the backend

### Orders Fail to Process
- Check if all required services are running
- Verify inventory exists for the SKU codes
- Check Order Service logs for errors

## 📞 Support

If you encounter issues:
1. Check browser console for errors
2. Verify all microservices are running
3. Ensure CORS is properly configured
4. Check network connectivity to the services 