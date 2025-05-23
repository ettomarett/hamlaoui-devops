#!/bin/bash

# Local testing script for microservices
echo "🚀 Starting local microservices testing..."

# Build all services
echo "📦 Building services..."
mvn clean package -DskipTests -pl product-service,inventory-service,order-service

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"

# Start services in background (requires databases to be running)
echo "🔧 Starting services..."

# Product Service (requires MongoDB)
echo "Starting Product Service on port 8080..."
cd product-service
java -jar target/product-service-1.0-SNAPSHOT.jar --server.port=8080 &
PRODUCT_PID=$!
cd ..

# Wait a bit for startup
sleep 10

# Inventory Service (requires MySQL)
echo "Starting Inventory Service on port 8081..."
cd inventory-service
java -jar target/inventory-service-1.0-SNAPSHOT.jar --server.port=8081 &
INVENTORY_PID=$!
cd ..

# Wait a bit for startup
sleep 10

# Order Service (requires MySQL)
echo "Starting Order Service on port 8082..."
cd order-service
java -jar target/order-service-1.0-SNAPSHOT.jar --server.port=8082 &
ORDER_PID=$!
cd ..

# Wait for services to start
sleep 30

echo "🧪 Testing services..."

# Test health endpoints
echo "Testing Product Service health..."
curl -f http://localhost:8080/actuator/health || echo "❌ Product Service health check failed"

echo "Testing Inventory Service health..."
curl -f http://localhost:8081/actuator/health || echo "❌ Inventory Service health check failed"

echo "Testing Order Service health..."
curl -f http://localhost:8082/actuator/health || echo "❌ Order Service health check failed"

# Test Prometheus metrics
echo "Testing Prometheus metrics..."
curl -f http://localhost:8080/actuator/prometheus | head -10 || echo "❌ Prometheus metrics failed"

echo "🎉 Local testing complete!"
echo "Services running with PIDs: Product=$PRODUCT_PID, Inventory=$INVENTORY_PID, Order=$ORDER_PID"
echo "To stop services: kill $PRODUCT_PID $INVENTORY_PID $ORDER_PID" 