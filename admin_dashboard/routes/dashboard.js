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

const parseApiMessage = (error, fallbackMessage) =>
  error.response?.data?.message ||
  error.response?.data?.error ||
  fallbackMessage;

const sendApiError = (res, error, fallbackMessage) => {
  res.status(error.response?.status || 500).json({
    success: false,
    message: parseApiMessage(error, fallbackMessage),
  });
};

const getFarmerId = (farmerRef) => {
  if (!farmerRef) return null;
  if (typeof farmerRef === 'string') return farmerRef;
  return farmerRef._id || null;
};

const buildSyncLogs = (farmers, crops, queries) => {
  const farmerLogs = farmers.slice(0, 8).map((farmer) => ({
    id: farmer._id || farmer.id || farmer.mobile,
    recordId: `FRM-${String(farmer.mobile || '').slice(-4) || '0000'}`,
    origin: farmer.name,
    detail: farmer.village || 'Farmer Registry',
    status: farmer.syncStatus === 'SYNCED' ? 'SYNCED' : 'PENDING',
    timestamp: farmer.updatedAt || farmer.createdAt,
    type: 'Farmer Record',
  }));

  const cropLogs = crops.slice(0, 8).map((crop) => ({
    id: crop._id || crop.id || crop.cropName,
    recordId: `CRP-${String(crop.cropName || '').slice(0, 4).toUpperCase()}`,
    origin: crop.cropName,
    detail: crop.cropType || 'Crop Registry',
    status: crop.syncStatus === 'SYNCED' ? 'SYNCED' : 'FAILED',
    timestamp: crop.updatedAt || crop.createdAt || crop.sowingDate,
    type: 'Crop Record',
  }));

  const queryLogs = queries.slice(0, 6).map((query) => ({
    id: query._id || query.id || query.description,
    recordId: `QRY-${String(query._id || query.id || '').slice(-4) || '0000'}`,
    origin: query.farmerId?.name || 'Farmer Query',
    detail: query.cropId?.cropName || 'Support Ticket',
    status: query.status === 'RESOLVED' ? 'SYNCED' : 'PENDING',
    timestamp: query.updatedAt || query.createdAt,
    type: 'Query Ticket',
  }));

  return [...farmerLogs, ...cropLogs, ...queryLogs]
    .filter((item) => item.timestamp)
    .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
    .slice(0, 12);
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
    pendingSyncRecords:
      farmers.filter((farmer) => farmer.syncStatus !== 'SYNCED').length +
      crops.filter((crop) => crop.syncStatus !== 'SYNCED').length,
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
    activePage: 'dashboard',
    stats,
    recentFarmers,
    recentQueries,
    topFieldworkers,
  });
});

router.get('/users', isAuthenticated, async (req, res) => {
  const users = await getData(req, '/auth/users');
  const fieldworkers = users.filter((userItem) => userItem.role === 'fieldworker');

  res.render('users', {
    user: req.session.adminUser,
    activePage: 'users',
    users: fieldworkers,
  });
});

router.get('/farmers', isAuthenticated, async (req, res) => {
  const [farmers, users] = await Promise.all([
    getData(req, '/farmers?limit=10000&page=1'),
    getData(req, '/auth/users'),
  ]);
  const fieldworkers = users.filter((userItem) => userItem.role === 'fieldworker');

  res.render('farmers', {
    user: req.session.adminUser,
    activePage: 'farmers',
    farmers,
    fieldworkers,
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
    activePage: 'crops',
    crops,
    farmerMap,
  });
});

router.get('/queries', isAuthenticated, async (req, res) => {
  const queries = await getData(req, '/queries');

  res.render('queries', {
    user: req.session.adminUser,
    activePage: 'queries',
    queries,
  });
});

router.get('/reports', isAuthenticated, async (req, res) => {
  const [users, farmers, crops, queries] = await Promise.all([
    getData(req, '/auth/users'),
    getData(req, '/farmers?limit=10000&page=1'),
    getData(req, '/crops'),
    getData(req, '/queries'),
  ]);

  const reportCards = [
    {
      category: 'Registry',
      title: 'Farmer Coverage Summary',
      description: 'Cross-region registration totals, linked accounts, and village-level onboarding coverage.',
      metric: `${farmers.length} farmers`,
      icon: 'person_pin',
    },
    {
      category: 'Operations',
      title: 'Field Agent Efficiency',
      description: 'Fieldworker performance based on registrations, crop capture activity, and support query volume.',
      metric: `${users.filter((user) => user.role === 'fieldworker').length} workers`,
      icon: 'badge',
    },
    {
      category: 'Production',
      title: 'Crop Mix Intelligence',
      description: 'Breakdown of crop categories, seasonality, and farmer participation across active records.',
      metric: `${crops.length} crops`,
      icon: 'eco',
    },
    {
      category: 'Support',
      title: 'Query Resolution Health',
      description: 'Open versus resolved farmer support requests with operational backlog visibility.',
      metric: `${queries.filter((query) => query.status === 'OPEN').length} open`,
      icon: 'support_agent',
    },
  ];

  res.render('reports', {
    user: req.session.adminUser,
    activePage: 'reports',
    summary: {
      totalReports: reportCards.length,
      farmers: farmers.length,
      crops: crops.length,
      users: users.length,
      openQueries: queries.filter((query) => query.status === 'OPEN').length,
      resolvedQueries: queries.filter((query) => query.status === 'RESOLVED').length,
    },
    reportCards,
  });
});

router.get('/sync-logs', isAuthenticated, async (req, res) => {
  const [farmers, crops, queries] = await Promise.all([
    getData(req, '/farmers?limit=10000&page=1'),
    getData(req, '/crops'),
    getData(req, '/queries'),
  ]);

  const syncLogs = buildSyncLogs(farmers, crops, queries);
  const total = syncLogs.length;
  const synced = syncLogs.filter((item) => item.status === 'SYNCED').length;
  const failed = syncLogs.filter((item) => item.status === 'FAILED').length;
  const pending = syncLogs.filter((item) => item.status === 'PENDING').length;

  res.render('sync_logs', {
    user: req.session.adminUser,
    activePage: 'sync-logs',
    syncLogs,
    syncSummary: {
      successRate: total === 0 ? 100 : Math.round((synced / total) * 1000) / 10,
      failed,
      pending,
      synced,
      lastSyncAt: syncLogs[0]?.timestamp || null,
    },
  });
});

router.get('/settings', isAuthenticated, async (req, res) => {
  const [users, farmers, crops] = await Promise.all([
    getData(req, '/auth/users'),
    getData(req, '/farmers?limit=10000&page=1'),
    getData(req, '/crops'),
  ]);

  res.render('settings', {
    user: req.session.adminUser,
    activePage: 'settings',
    settingsSummary: {
      admins: users.filter((item) => item.role === 'admin').length,
      fieldworkers: users.filter((item) => item.role === 'fieldworker').length,
      farmers: farmers.length,
      pendingSyncs:
        farmers.filter((item) => item.syncStatus !== 'SYNCED').length +
        crops.filter((item) => item.syncStatus !== 'SYNCED').length,
    },
  });
});

router.post('/farmers', isAuthenticated, async (req, res) => {
  try {
    const response = await api.post('/farmers', req.body, getAuthConfig(req));
    res.status(201).json({
      success: true,
      message: response.data?.message || 'Farmer created successfully',
      data: response.data?.data,
    });
  } catch (error) {
    sendApiError(res, error, 'Unable to create farmer');
  }
});

router.put('/farmers/:id', isAuthenticated, async (req, res) => {
  try {
    const response = await api.put(
      `/farmers/${req.params.id}`,
      req.body,
      getAuthConfig(req)
    );
    res.json({
      success: true,
      message: response.data?.message || 'Farmer updated successfully',
      data: response.data?.data,
    });
  } catch (error) {
    sendApiError(res, error, 'Unable to update farmer');
  }
});

router.delete('/farmers/:id', isAuthenticated, async (req, res) => {
  try {
    const response = await api.delete(`/farmers/${req.params.id}`, getAuthConfig(req));
    res.json({
      success: true,
      message: response.data?.message || 'Farmer deleted successfully',
    });
  } catch (error) {
    sendApiError(res, error, 'Unable to delete farmer');
  }
});

router.post('/users', isAuthenticated, async (req, res) => {
  try {
    const response = await api.post('/auth/users', req.body, getAuthConfig(req));
    res.status(201).json({
      success: true,
      message: response.data?.message || 'Fieldworker created successfully',
      data: response.data?.data,
    });
  } catch (error) {
    sendApiError(res, error, 'Unable to create fieldworker');
  }
});

router.put('/users/:id', isAuthenticated, async (req, res) => {
  try {
    const response = await api.put(
      `/auth/users/${req.params.id}`,
      req.body,
      getAuthConfig(req)
    );
    res.json({
      success: true,
      message: response.data?.message || 'Fieldworker updated successfully',
      data: response.data?.data,
    });
  } catch (error) {
    sendApiError(res, error, 'Unable to update fieldworker');
  }
});

router.delete('/users/:id', isAuthenticated, async (req, res) => {
  try {
    const response = await api.delete(`/auth/users/${req.params.id}`, getAuthConfig(req));
    res.json({
      success: true,
      message: response.data?.message || 'Fieldworker deleted successfully',
    });
  } catch (error) {
    sendApiError(res, error, 'Unable to delete fieldworker');
  }
});

module.exports = router;
