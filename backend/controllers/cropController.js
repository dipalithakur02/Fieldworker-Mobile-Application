const Crop = require('../models/Crop');
const Farmer = require('../models/Farmer');
const Query = require('../models/Query');
const sharp = require('sharp');

const buildCompressedImage = async (file) => {
  const compressedPath = `uploads/crop_images/compressed-${file.filename}`;
  await sharp(file.path)
    .resize(800, 600, { fit: 'inside' })
    .jpeg({ quality: 80 })
    .toFile(compressedPath);

  return compressedPath;
};

exports.createCrop = async (req, res) => {
  try {
    let imagePath = null;

    if (req.file) {
      imagePath = await buildCompressedImage(req.file);
    }

    const crop = await Crop.create({
      ...req.body,
      imagePath,
      createdBy: req.user.id
    });

    res.status(201).json({ success: true, message: 'Crop created', data: crop });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getAllCrops = async (req, res) => {
  try {
    let filter = {};

    if (req.user.role === 'farmer') {
      const farmer = await Farmer.findOne({ userId: req.user.id }).select('_id');
      if (!farmer) {
        return res.json({ success: true, data: [] });
      }

      filter = { farmerId: farmer._id };
    } else if (req.user.role !== 'admin') {
      filter = { createdBy: req.user.id };
    }

    const crops = await Crop.find(filter)
      .populate('farmerId')
      .populate('createdBy', 'name email mobile role');
    res.json({ success: true, data: crops });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getCropsByFarmer = async (req, res) => {
  try {
    let crops;

    if (req.user.role === 'farmer') {
      const farmer = await Farmer.findOne({ userId: req.user.id }).select('_id');
      if (!farmer || farmer._id.toString() !== req.params.farmerId) {
        return res.status(403).json({
          success: false,
          message: 'You do not have permission to view these crops',
        });
      }

      crops = await Crop.find({ farmerId: farmer._id });
    } else {
      const query = { farmerId: req.params.farmerId };
      if (req.user.role !== 'admin') {
        query.createdBy = req.user.id;
      }

      crops = await Crop.find(query).populate('farmerId');
    }

    res.json({ success: true, data: crops });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateCrop = async (req, res) => {
  try {
    const updates = { ...req.body };

    if (req.file) {
      updates.imagePath = await buildCompressedImage(req.file);
    }

    const cropLookup = { _id: req.params.id };
    if (req.user.role !== 'admin') {
      cropLookup.createdBy = req.user.id;
    }

    const crop = await Crop.findOneAndUpdate(cropLookup, updates, { new: true });
    if (!crop) return res.status(404).json({ success: false, message: 'Crop not found' });
    res.json({ success: true, message: 'Crop updated', data: crop });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.deleteCrop = async (req, res) => {
  try {
    const cropLookup = { _id: req.params.id };
    if (req.user.role !== 'admin') {
      cropLookup.createdBy = req.user.id;
    }

    const crop = await Crop.findOneAndDelete(cropLookup);
    if (!crop) return res.status(404).json({ success: false, message: 'Crop not found' });
    const queryDeleteQuery = { cropId: crop._id };
    if (req.user.role !== 'admin') {
      queryDeleteQuery.fieldworkerId = req.user.id;
    }
    await Query.deleteMany(queryDeleteQuery);
    res.json({ success: true, message: 'Crop deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
