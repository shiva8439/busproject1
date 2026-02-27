# 🚌 Stop-Based Bus Tracking System

## 🎯 Overview
This system tracks buses by their current stop instead of live GPS coordinates on a map. It shows:
- **Current Stop** where the bus is located
- **Previous Stop** that the bus just left
- **Next Stop** with ETA (Estimated Time of Arrival)
- **Between Stops** status when bus is en route

## 🚀 Quick Start

### 1. Backend Setup
```bash
# Start the stop-tracking backend
node backend_stop_tracking.js
```

### 2. Frontend Setup
```bash
# Replace main.dart with stop-tracking version
cp lib/main_stop_tracking.dart lib/main.dart

# Run the app
flutter run
```

## 📡 Key Features

### ✅ Stop Detection Logic
- **Haversine Formula**: Calculates distance between bus GPS and stops
- **100m Radius**: Bus is "at stop" when within 100 meters
- **Between Stops**: Shows progress when en route
- **Automatic Updates**: Every 30 seconds to optimize performance

### ✅ ETA Calculation
- **Distance-based**: Uses actual GPS distance to next stop
- **Speed-aware**: Considers current speed or route average
- **Traffic Buffer**: Adds 20% buffer time for realistic estimates
- **Real-time Updates**: ETA updates every 10 seconds

### ✅ Real-time Updates
- **Socket.IO**: Instant stop status changes
- **No Map Required**: Focus on stop-based information
- **Status Indicators**: LIVE/OFFLINE, At Stop, En Route, Off Route
- **Progress Tracking**: Shows journey progress between stops

## 🗄️ Database Schema

### Enhanced Bus Schema
```javascript
{
  busNumber: String,
  driverName: String,
  route: ObjectId,
  
  // Stop tracking fields
  currentStopIndex: Number,    // -1 = not at stop
  previousStopIndex: Number,
  nextStopIndex: Number,
  lastStopReached: Date,
  nextStopETA: Date,
  
  // Location fields
  location: {
    latitude: Number,
    longitude: Number,
    lastUpdated: Date,
    speed: Number,
    heading: Number
  },
  
  // Optimization
  lastStopCheck: Date,
  stopCheckInterval: Number  // 30 seconds
}
```

### Enhanced Route Schema
```javascript
{
  routeName: String,
  routeNumber: String,
  stops: [{
    name: String,
    lat: Number,
    lng: Number,
    stopOrder: Number,
    distanceFromStart: Number,
    landmark: String,
    facilities: [String]
  }],
  stopRadius: Number,        // 100 meters
  averageSpeed: Number,       // 25 km/h
  totalDistance: Number,
  estimatedDuration: Number
}
```

## 📱 UI Features

### Home Screen
- **Bus Search**: Track bus by number
- **Route List**: Browse all routes with bus counts
- **Status Overview**: At Stop vs En Route buses

### Route Screen
- **Bus Cards**: Show current/next stops with ETA
- **Status Indicators**: Visual status for each bus
- **Live Updates**: Real-time stop changes

### Bus Detail Screen
- **Current Status**: Large status indicator
- **Stop Cards**: Previous, Current, Next stops
- **Between Stops**: Progress bar when en route
- **ETA Display**: Minutes to next stop
- **Route Info**: Complete route details

## 🔌 API Endpoints

### Bus Tracking
- `GET /api/bus/:number` - Get bus with stop information
- `PUT /api/bus/:busNumber/location` - Update location with stop detection

### Route Management
- `GET /api/routes` - All routes with bus stop status
- `GET /api/routes/:routeId/buses` - Buses for route with stops
- `POST /api/routes` - Create route with stops
- `POST /api/buses/assign` - Assign bus to route

### Socket.IO Events
- `stopUpdate` - Real-time stop status changes
- `bus-{busNumber}` - Bus-specific updates

## 🎯 Stop Detection Logic

### 1. At Stop Detection
```javascript
// Check if bus is within 100m of any stop
const nearestStop = findNearestStop(lat, lng, stops, 100);
if (nearestStop) {
  // Bus is at stop
  currentStopIndex = nearestStop.index;
  status = 'At Stop';
}
```

### 2. Between Stops Detection
```javascript
// Check if bus is between current and next stop
const betweenStops = findBetweenStops(lat, lng, stops, currentStopIndex);
if (betweenStops) {
  // Bus is en route
  status = 'En Route';
  progress = (distanceFromCurrent / distanceBetweenStops) * 100;
}
```

### 3. ETA Calculation
```javascript
// Calculate ETA to next stop
const distance = calculateDistance(currentLat, currentLng, nextStop.lat, nextStop.lng);
const timeMinutes = (distance / speed) * 1.2; // 20% buffer
const arrivalTime = new Date(Date.now() + (timeMinutes * 60 * 1000));
```

## 📊 Status Types

| Status | Icon | Color | Description |
|--------|------|-------|-------------|
| At Stop | 📍 | Green | Bus is at a stop (within 100m) |
| En Route | 🚌 | Orange | Bus is between stops |
| Off Route | ⚠️ | Red | Bus is far from defined route |
| Unknown | ❓ | Grey | No recent location data |

## 🚀 Testing the System

### 1. Create Test Route
```bash
curl -X POST http://localhost:3000/api/routes \
  -H "Content-Type: application/json" \
  -d '{
    "routeName": "Delhi Airport Route",
    "routeNumber": "AIR-001",
    "stops": [
      {"name": "Airport Terminal 3", "lat": 28.5665, "lng": 77.1181},
      {"name": "Aerocity", "lat": 28.5562, "lng": 77.1130},
      {"name": "Mahipalpur", "lat": 28.5434, "lng": 77.1124},
      {"name": "Vasant Kunj", "lat": 28.5314, "lng": 77.1531}
    ],
    "averageSpeed": 30
  }'
```

### 2. Assign Bus to Route
```bash
curl -X POST http://localhost:3000/api/buses/assign \
  -H "Content-Type: application/json" \
  -d '{
    "busNumber": "AIR-01",
    "routeId": "ROUTE_ID_HERE",
    "driverName": "Airport Driver"
  }'
```

### 3. Simulate Bus Movement
```bash
# At Airport Terminal 3
curl -X PUT http://localhost:3000/api/bus/AIR-01/location \
  -H "Content-Type: application/json" \
  -d '{"latitude": 28.5665, "longitude": 77.1181, "speed": 0}'

# Between stops (en route)
curl -X PUT http://localhost:3000/api/bus/AIR-01/location \
  -H "Content-Type: application/json" \
  -d '{"latitude": 28.5600, "longitude": 77.1155, "speed": 25}'

# At Aerocity
curl -X PUT http://localhost:3000/api/bus/AIR-01/location \
  -H "Content-Type: application/json" \
  -d '{"latitude": 28.5562, "longitude": 77.1130, "speed": 0}'
```

## ⚡ Performance Optimizations

### Backend Optimizations
- **Rate Limiting**: Stop checks every 30 seconds max
- **Geospatial Indexing**: MongoDB 2dsphere indexes
- **Compound Indexes**: Optimized for bus queries
- **Batch Updates**: Reduce database writes

### Frontend Optimizations
- **Socket.IO Rooms**: Targeted updates only
- **Periodic Refresh**: 10-second data refresh
- **Local State**: Minimize API calls
- **Efficient Widgets**: Rebuild only when needed

## 🎨 UI Features

### Stop Cards
- **Current Stop**: Green highlight with ETA
- **Previous Stop**: Grey for reference
- **Next Stop**: Blue with arrival time
- **Between Stops**: Progress bar with route

### Status Indicators
- **Live Status**: Pulsing green dot for live buses
- **ETA Display**: Minutes to next stop
- **Progress Bar**: Journey completion percentage
- **Driver Info**: Name and current status

### Real-time Updates
- **Instant Changes**: Socket.IO for immediate updates
- **Smooth Transitions**: Animated status changes
- **Auto-refresh**: Background data updates
- **Error Handling**: Graceful fallback on connection issues

## 🔧 Configuration

### Environment Variables
```env
MONGO_URI=mongodb://localhost:27017/bus-tracker
PORT=3000
NODE_ENV=development
```

### Backend Configuration
```javascript
// Stop detection radius (meters)
const STOP_RADIUS = 100;

// Stop check interval (seconds)
const CHECK_INTERVAL = 30;

// Average bus speed (km/h)
const AVERAGE_SPEED = 25;

// ETA buffer factor (1.2 = 20% buffer)
const ETA_BUFFER = 1.2;
```

## 🚨 Error Handling

### Common Scenarios
- **Bus Off Route**: Shows warning message
- **No GPS Signal**: Displays last known location
- **Connection Lost**: Shows cached data with warning
- **Invalid Route**: Error message with retry option

### Fallback Behavior
- **ETA Missing**: Shows "Calculating..." 
- **Stop Unknown**: Displays stop index
- **Speed Missing**: Uses route average speed
- **Connection Error**: Shows last known status

## 📈 Scalability

### Multiple Buses
- **Independent Tracking**: Each bus tracked separately
- **Route-based Rooms**: Socket.IO rooms for routes
- **Efficient Updates**: Only relevant data sent
- **Load Balancing**: Ready for horizontal scaling

### Database Optimization
- **Indexing Strategy**: Optimized for stop queries
- **Connection Pooling**: MongoDB connection management
- **Caching**: Redis for frequent queries
- **Monitoring**: Performance metrics collection

## 🎉 Benefits

### User Experience
- **Clear Information**: Easy to understand stop-based data
- **Accurate ETAs**: Realistic arrival time predictions
- **No Map Confusion**: Focus on relevant stop information
- **Instant Updates**: Real-time status changes

### Operational Benefits
- **Reduced Complexity**: No complex map rendering
- **Better Performance**: Faster load times and updates
- **Lower Data Usage**: Less bandwidth than live maps
- **Easier Maintenance**: Simpler codebase

---

**🚌 Stop-based tracking is now ready for production!** 

The system provides clear, actionable information about bus locations without the complexity of live map tracking. Perfect for public transportation systems where passengers care more about stops than exact GPS coordinates.
