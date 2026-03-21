const express = require('express');
const router = express.Router();
const cropController = require('../controllers/cropController');
const { protect } = require('../middleware/authMiddleware');
const upload = require('../middleware/upload');

router.use(protect);

router.post('/', upload.single('image'),cropController.createCrop);
router.get('/', cropController.getAllCrops);
router.get('/farmer/:farmerId', cropController.getCropsByFarmer);
router.put('/:id', cropController.updateCrop);
router.delete('/:id', cropController.deleteCrop);

module.exports = router;
