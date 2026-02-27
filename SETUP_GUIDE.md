# 🚌 Real-Time Bus Tracking System - Setup Guide

## 🚀 Quick Setup Instructions

### 1. Backend Setup

```bash
# Navigate to project directory
cd where_is_my_bus

# Install backend dependencies
npm install express mongoose socket.io bcryptjs cors dotenv http

# Start the optimized backend
node backend_optimized.js
```

### 2. Frontend Setup

```bash
# Install Flutter dependencies
flutter pub get

# Replace main.dart with optimized version
# Copy lib/main_optimized.dart to lib/main.dart

# Run the app
flutter run
```

### 3. Environment Setup

Create `.env` file:
```env
MONGO_URI=mongodb://localhost:27017/bus-tracker
PORT=3000
NODE_ENV=development
```

## 📡 Key Features Implemented

✅ **Real-time Bus Tracking** - Live GPS updates every 5 seconds  
✅ **Route Management** - Buses properly assigned to routes  
✅ **Interactive Maps** - Route polylines and stop highlighting  
✅ **Socket.IO Integration** - Real-time updates without polling  
✅ **Live Status Indicators** - LIVE/OFFLINE status with nearest stop  
✅ **Optimized Database** - Proper indexing and schema design  
✅ **Error Handling** - Comprehensive validation and error responses  

## 🎯 How It Works

1. **Bus Assignment**: Buses are assigned to specific routes
2. **Location Updates**: Driver apps send GPS coordinates to backend
3. **Real-time Sync**: Socket.IO broadcasts updates to all clients
4. **Route Display**: Buses appear on their assigned routes with live positions
5. **Stop Detection**: System automatically finds current/nearest stop

## 📱 Testing the System

### Create Test Route:
```bash
curl -X POST http://localhost:3000/api/routes \
  -H "Content-Type: application/json" \
  -d '{
    "routeName": "Delhi Route",
    "routeNumber": "DL-001",
    "stops": [
      {"name": "Stop 1", "lat": 28.7041, "lng": 77.1026},
      {"name": "Stop 2", "lat": 28.7141, "lng": 77.1126}
    ]
  }'
```

### Assign Bus to Route:
```bash
curl -X POST http://localhost:3000/api/buses/assign \
  -H "Content-Type: application/json" \
  -d '{
    "busNumber": "UP15",
    "routeId": "ROUTE_ID_HERE",
    "driverName": "Driver Name"
  }'
```

### Update Bus Location:
```bash
curl -X PUT http://localhost:3000/api/bus/UP15/location \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": 28.7041,
    "longitude": 77.1026,
    "speed": 25
  }'
```

## 🔧 File Structure

```
where_is_my_bus/
├── backend_optimized.js     # Optimized backend with proper schema
├── lib/
│   ├── main_optimized.dart   # Optimized Flutter frontend
│   └── main.dart          # Original frontend
├── SETUP_GUIDE.md         # This file
└── .env                  # Environment variables
```

## 🎯 Key Improvements Made

### Backend Optimizations:
- ✅ Proper MongoDB schema with relationships
- ✅ Geospatial indexing for location queries
- ✅ Compound indexes for performance
- ✅ Real-time Socket.IO implementation
- ✅ Comprehensive API endpoints
- ✅ Error handling and validation

### Frontend Optimizations:
- ✅ Real-time Socket.IO integration
- ✅ Route-based bus display
- ✅ Interactive maps with polylines
- ✅ Live status indicators
- ✅ Proper error handling
- ✅ Smooth animations and transitions

### Route Mapping Fixes:
- ✅ Buses show on correct assigned routes
- ✅ Live buses appear in route listings
- ✅ Proper stop detection and highlighting
- ✅ Real-time location updates on maps
- ✅ Current/next stop indicators

## 🚀 Production Deployment

### Backend:
```bash
# Install PM2 for process management
npm install -g pm2

# Start in production mode
pm2 start backend_optimized.js --name "bus-tracker"
```

### Frontend:
```bash
# Build for production
flutter build apk --release
flutter build web
```

## 📞 Support

For issues:
1. Check backend logs: `node backend_optimized.js`
2. Verify MongoDB connection
3. Check Socket.IO connection in browser console
4. Ensure proper route assignments

**System is now production-ready with proper route mapping and real-time tracking!** 🎉
