const { body, param, query, validationResult } = require('express-validator');

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      errors: errors.array()
    });
  }
  next();
};

exports.registerValidation = [
  body('email').isEmail().withMessage('Please provide a valid email'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('name').notEmpty().withMessage('Name is required'),
  validate
];

exports.loginValidation = [
  body('email').isEmail().withMessage('Please provide a valid email'),
  body('password').notEmpty().withMessage('Password is required'),
  validate
];

exports.createBusValidation = [
  body('busNumber').notEmpty().withMessage('Bus number is required'),
  validate
];

exports.updateLocationValidation = [
  param('busNumber').notEmpty().withMessage('Bus number is required'),
  body('lat').isNumeric().withMessage('Latitude must be a number'),
  body('lng').isNumeric().withMessage('Longitude must be a number'),
  validate
];

exports.createRouteValidation = [
  body('routeName').notEmpty().withMessage('Route name is required'),
  validate
];

exports.createStopValidation = [
  body('name').notEmpty().withMessage('Stop name is required'),
  body('lat').isNumeric().withMessage('Latitude must be a number'),
  body('lng').isNumeric().withMessage('Longitude must be a number'),
  validate
];

exports.nearbyStopsValidation = [
  query('lat').isNumeric().withMessage('Latitude must be a number'),
  query('lng').isNumeric().withMessage('Longitude must be a number'),
  validate
];
