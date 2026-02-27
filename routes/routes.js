const express = require('express');
const router = express.Router();
const {
  createRoute,
  getAllRoutes,
  getRoute,
  getRouteBuses,
  updateRoute,
  deleteRoute
} = require('../controllers/routeController');
const { protect, authorize } = require('../middleware/auth');

router.post('/', protect, authorize('admin'), createRoute);
router.get('/', getAllRoutes);
router.get('/:id', getRoute);
router.get('/:id/buses', getRouteBuses);
router.put('/:id', protect, authorize('admin'), updateRoute);
router.delete('/:id', protect, authorize('admin'), deleteRoute);

module.exports = router;
