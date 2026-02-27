const mongoose = require('mongoose');

const routeSchema = new mongoose.Schema({
  routeName: {
    type: String,
    required: [true, 'Please provide route name']
  },
  routeNumber: {
    type: String,
    unique: true,
    sparse: true
  },
  stops: [{
    name: String,
    lat: Number,
    lng: Number,
    order: Number
  }],
  startPoint: {
    name: String,
    lat: Number,
    lng: Number
  },
  endPoint: {
    name: String,
    lat: Number,
    lng: Number
  },
  distance: {
    type: Number,
    default: 0
  },
  estimatedTime: {
    type: Number,
    default: 0
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Route', routeSchema);
