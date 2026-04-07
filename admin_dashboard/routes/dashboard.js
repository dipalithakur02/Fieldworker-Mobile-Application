const express = require('express');
const axios = require('axios');

const router = express.Router();

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:5001/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
});

const isAuthenticated = (req, res, next) => {
  if (req.session.adminToken && req.session.adminUser?.role === 'admin') {
    return next();
  }

  res.redirect('/login');
};

const getAuthConfig = (req) => ({
  headers: { Authorization: `Bearer ${req.session.adminToken}` },
});

const getData = async (req, endpoint, fallback = []) => {
  try {
    const response = await api.get(endpoint, getAuthConfig(req));
    return response.data?.data ?? fallback;
  } catch (error) {
    if (error.response?.status === 401 || error.response?.status === 403) {
      req.session.destroy(() => {});
    }
    return fallback;
  }
};

const getFarmerId = (farmerRef) => {
  if (!farmerRef) return null;
  if (typeof farmerRef === 'string') return farmerRef;
  return farmerRef._id || null;
};

router.get('/login', (req, res) => {
  if (req.session.adminToken && req.session.adminUser?.role === 'admin') {
    return res.redirect('/dashboard');
  }

  res.render('login', { error: null });
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    const response = await api.post('/auth/login', {
      identifier: email,
      password,
    });
    console.log(response);
    const authData = response.data?.data;
    const user = authData?.user;
    if (!response.data?.success || !authData?.token || user?.role !== 'admin') {
      return res.render('login', {
        error: 'Admin access is required to use this dashboard.',
      });
    }

    req.session.adminToken = authData.token;
    req.session.adminUser = user;

    res.redirect('/dashboard');
  } catch (error) {
    const message =
      error.response?.status === 401
        ? 'Invalid credentials'
        : 'Login failed. Please try again.';

    res.render('login', { error: message });
  }
});

router.get('/logout', (req, res) => {
  req.session.destroy(() => {
    res.redirect('/login');
  });
});

router.get(['/', '/dashboard'], isAuthenticated, async (req, res) => {
  const [users, farmers, crops, queries] = await Promise.all([
    getData(req, '/auth/users'),
    getData(req, '/farmers?limit=10000&page=1'),
    getData(req, '/crops'),
    getData(req, '/queries'),
  ]);

  const stats = {
    totalUsers: users.length,
    totalFieldworkers: users.filter((user) => user.role === 'fieldworker').length,
    totalFarmers: farmers.length,
    totalFarmerAccounts: users.filter((user) => user.role === 'farmer').length,
    totalCrops: crops.length,
    totalQueries: queries.length,
    openQueries: queries.filter((query) => query.status === 'OPEN').length,
    resolvedQueries: queries.filter((query) => query.status === 'RESOLVED').length,
    syncedFarmers: farmers.filter((farmer) => farmer.syncStatus === 'SYNCED').length,
    pendingFarmers: farmers.filter((farmer) => farmer.syncStatus === 'PENDING').length,
  };

  const recentFarmers = [...farmers]
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
    .slice(0, 5);

  const recentQueries = [...queries]
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
    .slice(0, 5);

  const topFieldworkers = users
    .filter((user) => user.role === 'fieldworker')
    .map((user) => ({
      ...user,
      farmersManaged: farmers.filter((farmer) => farmer.createdBy?._id === user._id).length,
      openQueries: queries.filter(
        (query) => query.fieldworkerId?._id === user._id && query.status === 'OPEN'
      ).length,
    }))
    .sort((a, b) => b.farmersManaged - a.farmersManaged)
    .slice(0, 5);

  res.render('dashboard', {
    user: req.session.adminUser,
    stats,
    recentFarmers,
    recentQueries,
    topFieldworkers,
  });
});

router.get('/users', isAuthenticated, async (req, res) => {
  const users = await getData(req, '/auth/users');

  res.render('users', {
    user: req.session.adminUser,
    users,
  });
});

router.get('/farmers', isAuthenticated, async (req, res) => {
  const farmers = await getData(req, '/farmers?limit=10000&page=1');

  res.render('farmers', {
    user: req.session.adminUser,
    farmers,
  });
});

router.get('/crops', isAuthenticated, async (req, res) => {
  const crops = await getData(req, '/crops');

  const farmerMap = {};
  crops.forEach((crop) => {
    const farmerId = getFarmerId(crop.farmerId);
    if (farmerId && typeof crop.farmerId === 'object') {
      farmerMap[farmerId] = crop.farmerId;
    }
  });

  res.render('crops', {
    user: req.session.adminUser,
    crops,
    farmerMap,
  });
});

router.get('/queries', isAuthenticated, async (req, res) => {
  const queries = await getData(req, '/queries');

  res.render('queries', {
    user: req.session.adminUser,
    queries,
  });
});

module.exports = router;
