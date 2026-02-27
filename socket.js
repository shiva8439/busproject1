const socketIo = require('socket.io');

let io;

const initializeSocket = (server) => {
  io = socketIo(server, {
    cors: { origin: "*" }
  });

  io.on('connection', (socket) => {
    console.log(`User connected: ${socket.id}`);

    socket.on('join-bus', (busNumber) => {
      socket.join(`bus-${busNumber}`);
      console.log(`User joined bus-${busNumber} room`);
    });

    socket.on('leave-bus', (busNumber) => {
      socket.leave(`bus-${busNumber}`);
      console.log(`User left bus-${busNumber} room`);
    });

    socket.on('driver-location-update', (data) => {
      const { busNumber, lat, lng, bearing } = data;
      io.to(`bus-${busNumber}`).emit('locationUpdate', {
        busNumber,
        lat,
        lng,
        bearing: bearing || 0,
        timestamp: new Date()
      });
    });

    socket.on('disconnect', () => {
      console.log(`User disconnected: ${socket.id}`);
    });
  });

  return io;
};

const getIO = () => {
  if (!io) {
    throw new Error('Socket.io not initialized!');
  }
  return io;
};

module.exports = { initializeSocket, getIO };
