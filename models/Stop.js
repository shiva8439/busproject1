const mongoose = require('mongoose');

const stopSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Please provide stop name']
  },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number],
      required: true
    }
  },
  address: {
    type: String
  },
  route: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Route'
  },
  order: {
    type: Number
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

stopSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('Stop', stopSchema);
