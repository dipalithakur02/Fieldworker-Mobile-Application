const express = require('express');
const router = express.Router();

const queryController = require('../controllers/queryController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.use(protect);

router.get('/', queryController.getQueries);
router.post('/', authorize('farmer'), queryController.createQuery);
router.patch('/:id/resolve', authorize('fieldworker', 'admin'), queryController.resolveQuery);

module.exports = router;
