const express = require('express');
const router = express.Router();
const {
  registerBus,
  getAllBuses,
  getBus,
  updateLocation,
  updateStatus,
  assignDriver,
  getMyBus
} = require('../controllers/busController');
const { protect, authorize } = require('../middleware/auth');

router.post('/', protect, authorize('driver', 'admin'), registerBus);
router.get('/', getAllBuses);
router.get('/my-bus', protect, authorize('driver'), getMyBus);
router.get('/:busNumber', getBus);
router.put('/:busNumber/location', protect, authorize('driver', 'admin'), updateLocation);
router.put('/:busNumber/status', protect, authorize('driver', 'admin'), updateStatus);
router.put('/:busNumber/assign-driver', protect, authorize('admin'), assignDriver);

module.exports = router;
