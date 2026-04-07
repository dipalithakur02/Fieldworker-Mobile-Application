const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const User = require('../models/User');
const Farmer = require('../models/Farmer');
const {
  jwtSecret,
  jwtExpire,
  jwtRefreshSecret,
  jwtRefreshExpire,
} = require('../src/config/env');

const signAccessToken = (user) =>
  jwt.sign(
    { id: user._id, role: user.role, type: 'access' },
    jwtSecret,
    { expiresIn: jwtExpire }
  );

const signRefreshToken = (user) =>
  jwt.sign(
    { id: user._id, type: 'refresh' },
    jwtRefreshSecret,
    { expiresIn: jwtRefreshExpire }
  );

const hashToken = (token) =>
  crypto.createHash('sha256').update(token).digest('hex');

const buildUserPayload = async (user) => {
  const payload = {
    id: user._id,
    name: user.name,
    email: user.email,
    mobile: user.mobile,
    role: user.role,
  };

  if (user.role === 'farmer') {
    const linkedFarmer = await Farmer.findOne({ userId: user._id }).select('_id');
    payload.farmerId = linkedFarmer?._id ?? null;
  }

  return payload;
};

const issueTokens = async (user) => {
  const accessToken = signAccessToken(user);
  const refreshToken = signRefreshToken(user);

  user.refreshTokenHash = hashToken(refreshToken);
  await user.save({ validateBeforeSave: false });

  return {
    user: await buildUserPayload(user),
    accessToken,
    refreshToken,
    token: accessToken,
  };
};

exports.register = async (req, res) => {
  try {
    const { name, email, password, mobile } = req.body;

    if (!email) {
      return res.status(400).json({ success: false, message: 'Email is required' });
    }

    const user = await User.create({
      name,
      email,
      password,
      mobile,
      role: 'fieldworker',
    });
    const authData = await issueTokens(user);

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      data: authData
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.login = async (req, res) => {
  try {
    const { identifier, email, password } = req.body;
    const loginIdentifier = (identifier || email || '').trim().toLowerCase();

    if (!loginIdentifier || !password) {
      return res.status(400).json({ success: false, message: 'Identifier and password are required' });
    }

    const user = await User.findOne({
      $or: [
        { email: loginIdentifier },
        { mobile: loginIdentifier },
      ],
    });

    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    const authData = await issueTokens(user);

    res.json({
      success: true,
      message: 'Login successful',
      data: authData
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.refresh = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ success: false, message: 'Refresh token is required' });
    }

    const decoded = jwt.verify(refreshToken, jwtRefreshSecret);
    if (decoded.type != 'refresh') {
      return res.status(401).json({ success: false, message: 'Invalid refresh token' });
    }

    const user = await User.findById(decoded.id);
    if (!user || !user.refreshTokenHash) {
      return res.status(401).json({ success: false, message: 'Refresh token is no longer valid' });
    }

    if (user.refreshTokenHash !== hashToken(refreshToken)) {
      return res.status(401).json({ success: false, message: 'Refresh token is no longer valid' });
    }

    const authData = await issueTokens(user);

    res.json({
      success: true,
      message: 'Token refreshed successfully',
      data: authData,
    });
  } catch (error) {
    res.status(401).json({ success: false, message: 'Refresh token expired or invalid' });
  }
};

exports.logout = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (refreshToken) {
      try {
        const decoded = jwt.verify(refreshToken, jwtRefreshSecret);
        const user = await User.findById(decoded.id);
        if (user) {
          user.refreshTokenHash = null;
          await user.save({ validateBeforeSave: false });
        }
      } catch (_) {
        // Local token cleanup should still succeed even if the refresh token is stale.
      }
    }

    res.json({ success: true, message: 'Logout successful' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getMe = async (req, res) => {
  try {
    res.json({
      success: true,
      data: {
        user: await buildUserPayload(req.user),
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const { name, email, mobile } = req.body;

    if (name != null) {
      req.user.name = name;
    }

    if (email != null) {
      req.user.email = email;
    }

    if (mobile != null) {
      req.user.mobile = mobile;
    }

    await req.user.save();

    if (req.user.role === 'farmer' && mobile != null) {
      await Farmer.findOneAndUpdate(
        { userId: req.user.id },
        { mobile },
      );
    }

    res.json({
      success: true,
      message: 'Profile updated',
      data: {
        user: await buildUserPayload(req.user),
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getUsers = async (req, res) => {
  try {
    const users = await User.find()
      .select('-password -refreshTokenHash')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: users,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
