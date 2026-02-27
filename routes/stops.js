const express = require('express');
const router = express.Router();
const {
  createStop,
  getAllStops,
  getStop,
  nearbyStops,
  updateStop,
  deleteStop
} = require('../controllers/stopController');
const { protect, authorize } = require('../middleware/auth');

router.post('/', protect, authorize('admin'), createStop);
router.get('/', getAllStops);
router.get('/nearby', nearbyStops);
router.get('/:id', getStop);
router.put('/:id', protect, authorize('admin'), updateStop);
router.delete('/:id', protect, authorize('admin'), deleteStop);

module.exports = router;
