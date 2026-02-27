const express = require('express');
const http = require('http');
const cors = require('cors');
require('dotenv').config();

const connectDB = require('./config/database');
const { initializeSocket } = require('./config/socket');
const errorHandler = require('./middleware/error');
const limiter = require('./middleware/rateLimiter');

const authRoutes = require('./routes/auth');
const busRoutes = require('./routes/bus');
const routeRoutes = require('./routes/routes');
const stopRoutes = require('./routes/stops');

const app = express();
const server = http.createServer(app);

connectDB();

initializeSocket(server);

app.use(cors());
app.use(express.json());
app.use(limiter);

app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Bus Tracker API',
    endpoints: {
      auth: '/api/auth',
      bus: '/api/bus',
      routes: '/api/routes',
      stops: '/api/stops'
    }
  });
});

// Compatibility route for Flutter app - maps /vehicles/search to /api/bus
app.get('/vehicles/search', async (req, res) => {
  try {
    const Bus = require('./models/Bus');
    const { number } = req.query;
    
    let buses;
    if (number) {
      buses = await Bus.find({ busNumber: number.toUpperCase() }).populate('route');
    } else {
      buses = await Bus.find().populate('route');
    }

    const vehicles = buses.map(bus => ({
      _id: bus._id,
      number: bus.busNumber,
      busNumber: bus.busNumber,
      driverName: bus.driverName,
      isActive: bus.isActive,
      hasValidLocation: bus.isLive(),
      currentLocation: {
        lat: bus.location?.coordinates[1] || 0,
        lng: bus.location?.coordinates[0] || 0
      },
      currentStopIndex: bus.currentStopIndex,
      route: bus.route
    }));

    res.json({
      success: true,
      vehicles
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

app.use('/api/auth', authRoutes);
app.use('/api/bus', busRoutes);
app.use('/api/routes', routeRoutes);
app.use('/api/stops', stopRoutes);

app.use(errorHandler);

const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app;
