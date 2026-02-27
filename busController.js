const Bus = require('../models/Bus');
const Route = require('../models/Route');
const Stop = require('../models/Stop');
const { getIO } = require('../config/socket');
const config = require('../config');

const { calculateDistance, calculateETA, detectNearbyStop } = require('../utils/geoUtils');

exports.registerBus = async (req, res, next) => {
  try {
    const { busNumber, driverName, routeId, capacity } = req.body;

    let route = null;
    if (routeId) {
      route = await Route.findById(routeId);
    }

    const bus = await Bus.create({
      busNumber: busNumber.toUpperCase(),
      driverName,
      route: route?._id,
      capacity: capacity || 50,
      status: 'inactive',
      isActive: false
    });

    res.status(201).json({
      success: true,
      data: bus
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

exports.getAllBuses = async (req, res, next) => {
  try {
    const buses = await Bus.find().populate('route');

    const busesWithStatus = buses.map(bus => ({
      _id: bus._id,
      busNumber: bus.busNumber,
      driverName: bus.driverName,
      routeName: bus.route?.routeName || 'No Route',
      currentStop: bus.route?.stops[bus.currentStopIndex] || 'Unknown',
      isLive: bus.isLive(),
      isActive: bus.isActive,
      location: {
        lat: bus.location?.coordinates[1] || 0,
        lng: bus.location?.coordinates[0] || 0,
        lastUpdated: bus.location?.lastUpdated
      },
      status: bus.status,
      capacity: bus.capacity,
      currentPassengers: bus.currentPassengers
    }));

    res.status(200).json({
      success: true,
      count: buses.length,
      data: busesWithStatus
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

exports.getBus = async (req, res, next) => {
  try {
    const bus = await Bus.findOne({ busNumber: req.params.busNumber }).populate('route');

    if (!bus) {
      return res.status(404).json({
        success: false,
        error: 'Bus not found'
      });
    }

    const currentStop = bus.route?.stops[bus.currentStopIndex];
    const nextStop = bus.route?.stops[bus.currentStopIndex + 1];

    res.status(200).json({
      success: true,
      data: {
        busNumber: bus.busNumber,
        driverName: bus.driverName,
        isActive: bus.isActive,
        isLive: bus.isLive(),
        currentStop,
        nextStop: nextStop || 'Last Stop',
        currentStopIndex: bus.currentStopIndex,
        location: {
          lat: bus.location?.coordinates[1] || 0,
          lng: bus.location?.coordinates[0] || 0,
          lastUpdated: bus.location?.lastUpdated
        },
        route: bus.route,
        status: bus.status
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

exports.updateLocation = async (req, res, next) => {
  try {
    const { busNumber } = req.params;
    const { lat, lng, bearing } = req.body;

    if (lat == null || lng == null) {
      return res.status(400).json({
        success: false,
        error: 'Please provide latitude and longitude'
      });
    }

    const bus = await Bus.findOne({ busNumber: busNumber.toUpperCase() });

    if (!bus) {
      return res.status(404).json({
        success: false,
        error: 'Bus not found'
      });
    }

    if (req.user && bus.driver) {
      if (req.user.id !== bus.driver.toString() && req.user.role !== 'admin') {
        return res.status(403).json({
          success: false,
          error: 'Not authorized to update this bus location'
        });
      }
    }

    if (!bus.isActive) {
      return res.status(400).json({
        success: false,
        error: 'Bus is inactive. Start trip first.'
      });
    }

    const oldLocation = {
      lat: bus.location?.coordinates[1] || 0,
      lng: bus.location?.coordinates[0] || 0,
      timestamp: bus.location?.lastUpdated
    };

    bus.location = {
      type: 'Point',
      coordinates: [lng, lat],
      lastUpdated: new Date()
    };
    await bus.save();

    const nearbyStop = await detectNearbyStop(lat, lng, bus.route);
    if (nearbyStop && bus.currentStopIndex < bus.route.stops.length - 1) {
      const stopIndex = bus.route.stops.findIndex(s => s.name === nearbyStop.name);
      if (stopIndex > bus.currentStopIndex) {
        bus.currentStopIndex = stopIndex;
        await bus.save();
      }
    }

    const io = getIO();
    io.to(`bus-${busNumber}`).emit('locationUpdate', {
      busNumber: bus.busNumber,
      lat,
      lng,
      bearing: bearing || 0,
      currentStopIndex: bus.currentStopIndex,
      currentStop: bus.route?.stops[bus.currentStopIndex],
      timestamp: new Date()
    });

    io.emit('busStatusChanged', {
      busNumber: bus.busNumber,
      isActive: bus.isActive,
      isLive: bus.isLive(),
      location: { lat, lng }
    });

    let eta = null;
    if (bus.route && bus.currentStopIndex < bus.route.stops.length - 1) {
      eta = await calculateETA(bus, oldLocation, { lat, lng });
    }

    res.status(200).json({
      success: true,
      data: {
        busNumber: bus.busNumber,
        location: { lat, lng },
        currentStopIndex: bus.currentStopIndex,
        currentStop: bus.route?.stops[bus.currentStopIndex],
        eta
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

exports.updateStatus = async (req, res, next) => {
  try {
    const { busNumber } = req.params;
    const { isActive, tripEnded } = req.body;

    const bus = await Bus.findOne({ busNumber: busNumber.toUpperCase() });

    if (!bus) {
      return res.status(404).json({
        success: false,
        error: 'Bus not found'
      });
    }

    if (req.user && bus.driver) {
      if (req.user.id !== bus.driver.toString() && req.user.role !== 'admin') {
        return res.status(403).json({
          success: false,
          error: 'Not authorized to update this bus status'
        });
      }
    }

    if (tripEnded) {
      bus.isActive = false;
      bus.status = 'inactive';
      bus.lastTripEnded = new Date();
      bus.location = {
        type: 'Point',
        coordinates: [0, 0],
        lastUpdated: new Date(Date.now() - 10 * 60 * 1000)
      };
    } else {
      bus.isActive = isActive;
      bus.status = isActive ? 'active' : 'inactive';
    }

    await bus.save();

    const io = getIO();
    io.to(`bus-${busNumber}`).emit('statusUpdate', {
      busNumber: bus.busNumber,
      isActive: bus.isActive,
      status: bus.status,
      tripEnded: !!tripEnded
    });

    io.emit('busStatusChanged', {
      busNumber: bus.busNumber,
      isActive: bus.isActive,
      isLive: bus.isLive()
    });

    res.status(200).json({
      success: true,
      data: {
        busNumber: bus.busNumber,
        isActive: bus.isActive,
        status: bus.status
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

exports.assignDriver = async (req, res, next) => {
  try {
    const { busNumber } = req.params;
    const { driverId } = req.body;

    const bus = await Bus.findOne({ busNumber: busNumber.toUpperCase() });

    if (!bus) {
      return res.status(404).json({
        success: false,
        error: 'Bus not found'
      });
    }

    const driver = await User.findById(driverId);

    if (!driver || driver.role !== 'driver') {
      return res.status(404).json({
        success: false,
        error: 'Driver not found'
      });
    }

    bus.driver = driverId;
    driver.assignedBus = bus._id;
    await bus.save();
    await driver.save();

    res.status(200).json({
      success: true,
      data: {
        busNumber: bus.busNumber,
        driver: {
          id: driver._id,
          name: driver.name,
          email: driver.email
        }
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

exports.getMyBus = async (req, res, next) => {
  try {
    const bus = await Bus.findOne({ driver: req.user.id }).populate('route');

    if (!bus) {
      return res.status(404).json({
        success: false,
        error: 'No bus assigned to this driver'
      });
    }

    res.status(200).json({
      success: true,
      data: bus
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};
