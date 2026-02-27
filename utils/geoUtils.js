const Stop = require('../models/Stop');
const Route = require('../models/Route');
const config = require('../config');

const toRadians = (degrees) => {
  return degrees * (Math.PI / 180);
};

const calculateDistance = (lat1, lng1, lat2, lng2) => {
  const R = 6371e3;
  const φ1 = toRadians(lat1);
  const φ2 = toRadians(lat2);
  const Δφ = toRadians(lat2 - lat1);
  const Δλ = toRadians(lng2 - lng1);

  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) *
    Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
};

const calculateETA = async (bus, oldLocation, newLocation) => {
  if (!bus.route || !bus.route.stops || bus.route.stops.length === 0) {
    return null;
  }

  const currentStop = bus.route.stops[bus.currentStopIndex];
  const nextStop = bus.route.stops[bus.currentStopIndex + 1];

  if (!nextStop) {
    return null;
  }

  const distanceToNextStop = calculateDistance(
    newLocation.lat,
    newLocation.lng,
    nextStop.lat,
    nextStop.lng
  );

  const distanceCovered = calculateDistance(
    oldLocation.lat,
    oldLocation.lng,
    newLocation.lat,
    newLocation.lng
  );

  const timeDiff = oldLocation.timestamp
    ? (new Date() - new Date(oldLocation.timestamp)) / 1000
    : 30;

  if (timeDiff <= 0 || distanceCovered <= 0) {
    const avgSpeed = 30;
    const timeToCover = (distanceToNextStop / 1000) / avgSpeed;
    return Math.round(timeToCover * 60);
  }

  const speed = distanceCovered / timeDiff;
  const speedKmH = speed * 3.6;

  if (speedKmH <= 0) {
    return null;
  }

  const distanceKm = distanceToNextStop / 1000;
  const timeInMinutes = (distanceKm / speedKmH) * 60;

  return Math.round(timeInMinutes);
};

const detectNearbyStop = async (lat, lng, route) => {
  if (!route || !route.stops || route.stops.length === 0) {
    return null;
  }

  for (const stop of route.stops) {
    if (stop.lat != null && stop.lng != null) {
      const distance = calculateDistance(lat, lng, stop.lat, stop.lng);
      if (distance <= config.STOP_RADIUS_METERS) {
        return stop;
      }
    }
  }

  return null;
};

const getRouteETA = async (bus) => {
  if (!bus.route || !bus.route.stops || bus.route.stops.length === 0) {
    return null;
  }

  let totalDistance = 0;
  const currentStop = bus.route.stops[bus.currentStopIndex];
  const currentLat = bus.location?.coordinates[1] || 0;
  const currentLng = bus.location?.coordinates[0] || 0;

  if (currentStop) {
    totalDistance += calculateDistance(currentLat, currentLng, currentStop.lat, currentStop.lng);
  }

  for (let i = bus.currentStopIndex; i < bus.route.stops.length - 1; i++) {
    const stop = bus.route.stops[i];
    const nextStop = bus.route.stops[i + 1];
    totalDistance += calculateDistance(stop.lat, stop.lng, nextStop.lat, nextStop.lng);
  }

  const avgSpeed = 30;
  const timeInHours = (totalDistance / 1000) / avgSpeed;
  const timeInMinutes = timeInHours * 60;

  return Math.round(timeInMinutes);
};

module.exports = {
  calculateDistance,
  calculateETA,
  detectNearbyStop,
  getRouteETA
};
