const Stop = require('../models/Stop');
const Route = require('../models/Route');

exports.createStop = async (req, res, next) => {
  try {
    const { name, lat, lng, address, routeId, order } = req.body;

    const stop = await Stop.create({
      name,
      location: {
        type: 'Point',
        coordinates: [lng, lat]
      },
      address,
      route: routeId,
      order
    });

    if (routeId) {
      await Route.findByIdAndUpdate(routeId, {
        $push: { stops: { name, lat, lng, order: order || 0 } }
      });
    }

    res.status(201).json({
      success: true,
      data: stop
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

exports.getAllStops = async (req, res, next) => {
  try {
    const stops = await Stop.find().populate('route');

    res.status(200).json({
      success: true,
      count: stops.length,
      data: stops
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

exports.getStop = async (req, res, next) => {
  try {
    const stop = await Stop.findById(req.params.id).populate('route');

    if (!stop) {
      return res.status(404).json({
        success: false,
        error: 'Stop not found'
      });
    }

    res.status(200).json({
      success: true,
      data: stop
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

exports.nearbyStops = async (req, res, next) => {
  try {
    const { lat, lng, radius } = req.query;

    if (!lat || !lng) {
      return res.status(400).json({
        success: false,
        error: 'Please provide lat and lng'
      });
    }

    const stops = await Stop.find({
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(lng), parseFloat(lat)]
          },
          $maxDistance: parseInt(radius) || 5000
        }
      }
    });

    res.status(200).json({
      success: true,
      count: stops.length,
      data: stops
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

exports.updateStop = async (req, res, next) => {
  try {
    const { name, lat, lng, address, order } = req.body;

    const stop = await Stop.findById(req.params.id);

    if (!stop) {
      return res.status(404).json({
        success: false,
        error: 'Stop not found'
      });
    }

    stop.name = name || stop.name;
    stop.address = address || stop.address;
    stop.order = order || stop.order;

    if (lat != null && lng != null) {
      stop.location = {
        type: 'Point',
        coordinates: [lng, lat]
      };
    }

    await stop.save();

    res.status(200).json({
      success: true,
      data: stop
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

exports.deleteStop = async (req, res, next) => {
  try {
    const stop = await Stop.findById(req.params.id);

    if (!stop) {
      return res.status(404).json({
        success: false,
        error: 'Stop not found'
      });
    }

    if (stop.route) {
      await Route.findByIdAndUpdate(stop.route, {
        $pull: { stops: { name: stop.name } }
      });
    }

    await stop.deleteOne();

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
