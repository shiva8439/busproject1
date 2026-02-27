const Route = require('../models/Route');
const Bus = require('../models/Bus');

exports.createRoute = async (req, res, next) => {
  try {
    const { routeName, routeNumber, stops, startPoint, endPoint } = req.body;

    const route = await Route.create({
      routeName,
      routeNumber: routeNumber || `ROUTE-${Date.now()}`,
      stops: stops || [],
      startPoint,
      endPoint
    });

    res.status(201).json({
      success: true,
      data: route
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

exports.getAllRoutes = async (req, res, next) => {
  try {
    const routes = await Route.find();

    res.status(200).json({
      success: true,
      count: routes.length,
      data: routes.map(route => ({
        _id: route._id,
        routeName: route.routeName,
        routeNumber: route.routeNumber,
        totalStops: route.stops.length,
        stops: route.stops,
        startPoint: route.startPoint,
        endPoint: route.endPoint
      }))
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

exports.getRoute = async (req, res, next) => {
  try {
    const route = await Route.findById(req.params.id);

    if (!route) {
      return res.status(404).json({
        success: false,
        error: 'Route not found'
      });
    }

    res.status(200).json({
      success: true,
      data: route
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

exports.getRouteBuses = async (req, res, next) => {
  try {
    const buses = await Bus.find({ route: req.params.id }).populate('route');

    const busesWithStatus = buses.map(bus => ({
      _id: bus._id,
      busNumber: bus.busNumber,
      driverName: bus.driverName,
      currentStop: bus.route?.stops[bus.currentStopIndex],
      isLive: bus.isLive(),
      isActive: bus.isActive,
      location: {
        lat: bus.location?.coordinates[1] || 0,
        lng: bus.location?.coordinates[0] || 0,
        lastUpdated: bus.location?.lastUpdated
      }
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

exports.updateRoute = async (req, res, next) => {
  try {
    const route = await Route.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!route) {
      return res.status(404).json({
        success: false,
        error: 'Route not found'
      });
    }

    res.status(200).json({
      success: true,
      data: route
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

exports.deleteRoute = async (req, res, next) => {
  try {
    const route = await Route.findById(req.params.id);

    if (!route) {
      return res.status(404).json({
        success: false,
        error: 'Route not found'
      });
    }

    await route.deleteOne();

    res.status(200).json({
      success: true,
      data: {}
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};
