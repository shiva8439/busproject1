const mongoose = require('mongoose');

const busSchema = new mongoose.Schema({
  busNumber: {
    type: String,
    required: [true, 'Please provide bus number'],
    unique: true,
    uppercase: true
  },
  driverName: {
    type: String
  },
  driver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  route: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Route'
  },
  currentStopIndex: {
    type: Number,
    default: 0
  },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number],
      default: [0, 0]
    },
    lastUpdated: {
      type: Date,
      default: Date.now
    }
  },
  isActive: {
    type: Boolean,
    default: false
  },
  lastTripEnded: {
    type: Date
  },
  status: {
    type: String,
    enum: ['active', 'inactive', 'maintenance'],
    default: 'inactive'
  },
  capacity: {
    type: Number,
    default: 50
  },
  currentPassengers: {
    type: Number,
    default: 0
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

busSchema.index({ location: '2dsphere' });

busSchema.methods.isLive = function() {
  if (!this.isActive) return false;
  if (!this.location?.lastUpdated) return false;
  const now = new Date();
  const lastUpdate = new Date(this.location.lastUpdated);
  const diffMinutes = (now - lastUpdate) / (1000 * 60);
  return diffMinutes <= 2;
};

module.exports = mongoose.model('Bus', busSchema);
