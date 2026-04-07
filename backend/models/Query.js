const mongoose = require('mongoose');

const querySchema = new mongoose.Schema({
  farmerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Farmer',
    required: true,
  },
  cropId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Crop',
    required: true,
  },
  fieldworkerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  description: {
    type: String,
    required: true,
    trim: true,
  },
  status: {
    type: String,
    enum: ['OPEN', 'RESOLVED'],
    default: 'OPEN',
  },
  resolutionNote: {
    type: String,
    trim: true,
  },
  resolvedAt: {
    type: Date,
    default: null,
  },
}, { timestamps: true });

module.exports = mongoose.model('Query', querySchema);
