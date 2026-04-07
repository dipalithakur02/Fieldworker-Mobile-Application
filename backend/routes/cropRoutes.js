const express = require('express');
const router = express.Router();
const cropController = require('../controllers/cropController');
const { protect, authorize } = require('../middleware/authMiddleware');
const upload = require('../middleware/upload');

router.use(protect);

router.post('/', authorize('fieldworker', 'admin'), upload.single('image'), cropController.createCrop);
router.get('/', cropController.getAllCrops);
router.get('/farmer/:farmerId', cropController.getCropsByFarmer);
router.put('/:id', authorize('fieldworker', 'admin'), upload.single('image'), cropController.updateCrop);
router.delete('/:id', authorize('fieldworker', 'admin'), cropController.deleteCrop);

module.exports = router;
