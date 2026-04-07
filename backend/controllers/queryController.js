const Farmer = require('../models/Farmer');
const Crop = require('../models/Crop');
const Query = require('../models/Query');

const getLinkedFarmer = async (userId) => {
  return Farmer.findOne({ userId }).select('_id createdBy');
};

exports.createQuery = async (req, res) => {
  try {
    const { cropId, description } = req.body;

    if (!cropId || !description) {
      return res.status(400).json({
        success: false,
        message: 'Crop and description are required',
      });
    }

    const farmer = await getLinkedFarmer(req.user.id);
    if (!farmer) {
      return res.status(404).json({
        success: false,
        message: 'Linked farmer profile not found',
      });
    }

    const crop = await Crop.findOne({ _id: cropId, farmerId: farmer._id });
    if (!crop) {
      return res.status(404).json({
        success: false,
        message: 'Crop not found for this farmer',
      });
    }

    const query = await Query.create({
      farmerId: farmer._id,
      cropId: crop._id,
      fieldworkerId: farmer.createdBy,
      description,
    });

    const populatedQuery = await Query.findById(query._id)
      .populate('farmerId', 'name village mobile')
      .populate('cropId', 'cropName cropType season');

    res.status(201).json({
      success: true,
      message: 'Query created',
      data: populatedQuery,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getQueries = async (req, res) => {
  try {
    let queryFilter = {};

    if (req.user.role === 'farmer') {
      const farmer = await getLinkedFarmer(req.user.id);
      if (!farmer) {
        return res.json({ success: true, data: [] });
      }

      queryFilter = { farmerId: farmer._id };
    } else if (req.user.role !== 'admin') {
      queryFilter = { fieldworkerId: req.user.id };
    }

    const queries = await Query.find(queryFilter)
      .populate('farmerId', 'name village mobile')
      .populate('cropId', 'cropName cropType season')
      .populate('fieldworkerId', 'name email mobile role')
      .sort({ createdAt: -1 });

    res.json({ success: true, data: queries });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.resolveQuery = async (req, res) => {
  try {
    const { resolutionNote } = req.body;

    const queryLookup = { _id: req.params.id };
    if (req.user.role !== 'admin') {
      queryLookup.fieldworkerId = req.user.id;
    }

    const query = await Query.findOneAndUpdate(
      queryLookup,
      {
        status: 'RESOLVED',
        resolutionNote,
        resolvedAt: new Date(),
      },
      { new: true }
    )
      .populate('farmerId', 'name village mobile')
      .populate('cropId', 'cropName cropType season');

    if (!query) {
      return res.status(404).json({ success: false, message: 'Query not found' });
    }

    res.json({
      success: true,
      message: 'Query marked as resolved',
      data: query,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
