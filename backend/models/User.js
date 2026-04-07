const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: {
    type: String,
    lowercase: true,
    trim: true,
    sparse: true,
    unique: true,
  },
  mobile: {
    type: String,
    trim: true,
    sparse: true,
    unique: true,
  },
  password: { type: String, required: true },
  role: {
    type: String,
    enum: ['fieldworker', 'admin', 'farmer'],
    default: 'fieldworker',
  },
  refreshTokenHash: { type: String, default: null }
}, { timestamps: true });

userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

userSchema.methods.comparePassword = async function(password) {
  return await bcrypt.compare(password, this.password);
};

module.exports = mongoose.model('User', userSchema);
