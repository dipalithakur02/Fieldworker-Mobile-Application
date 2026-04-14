const Farmer = require('../models/Farmer');
const Crop = require('../models/Crop');
const Query = require('../models/Query');
const User = require('../models/User');

exports.createFarmer = async (req, res) => {
  try {
    const {
      createLoginAccount,
      accountPassword,
      ...farmerPayload
    } = req.body;

    const assignedFieldworker =
      req.user.role === 'admin' && farmerPayload.createdBy
        ? farmerPayload.createdBy
        : req.user.id;

    let linkedUser = null;
    if (createLoginAccount) {
      if (!accountPassword) {
        return res.status(400).json({
          success: false,
          message: 'Password is required to create a farmer login account',
        });
      }

      linkedUser = await User.create({
        name: farmerPayload.name,
        mobile: farmerPayload.mobile,
        password: accountPassword,
        role: 'farmer',
      });
    }

    const farmer = await Farmer.create({
      ...farmerPayload,
      userId: linkedUser?._id ?? null,
      createdBy: assignedFieldworker,
    });

    res.status(201).json({ success: true, message: 'Farmer created', data: farmer });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getAllFarmers = async (req, res) => {
  try {
    const { search, village, page = 1, limit = 10 } = req.query;
    const query = {};

    if (req.user.role !== 'admin') {
      query.createdBy = req.user.id;
    }
    
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { mobile: { $regex: search, $options: 'i' } }
      ];
    }
    
    if (village) {
      query.village = { $regex: village, $options: 'i' };
    }
    
    const farmers = await Farmer.find(query)
      .populate('createdBy', 'name email mobile role')
      .populate('userId', 'name email mobile role')
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ createdAt: -1 });
    
    const count = await Farmer.countDocuments(query);
    
    res.json({ 
      success: true, 
      data: farmers,
      totalPages: Math.ceil(count / limit),
      currentPage: page,
      total: count
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getFarmer = async (req, res) => {
  try {
    const query = { _id: req.params.id };
    if (req.user.role !== 'admin') {
      query.createdBy = req.user.id;
    }

    const farmer = await Farmer.findOne(query)
      .populate('createdBy', 'name email mobile role')
      .populate('userId', 'name email mobile role');
    if (!farmer) return res.status(404).json({ success: false, message: 'Farmer not found' });
    res.json({ success: true, data: farmer });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateFarmer = async (req, res) => {
  try {
    const {
      createLoginAccount,
      accountPassword,
      ...updates
    } = req.body;

    if (req.user.role !== 'admin') {
      delete updates.createdBy;
    }

    const farmerLookup = { _id: req.params.id };
    if (req.user.role !== 'admin') {
      farmerLookup.createdBy = req.user.id;
    }

    const existingFarmer = await Farmer.findOne(farmerLookup);
    if (!existingFarmer) {
      return res.status(404).json({ success: false, message: 'Farmer not found' });
    }

    if (createLoginAccount && !existingFarmer.userId) {
      if (!accountPassword) {
        return res.status(400).json({
          success: false,
          message: 'Password is required to create a farmer login account',
        });
      }

      const linkedUser = await User.create({
        name: updates.name ?? existingFarmer.name,
        mobile: updates.mobile ?? existingFarmer.mobile,
        password: accountPassword,
        role: 'farmer',
      });

      updates.userId = linkedUser._id;
    }

    const farmer = await Farmer.findOneAndUpdate(farmerLookup, updates, { new: true });
    if (!farmer) return res.status(404).json({ success: false, message: 'Farmer not found' });

    if (farmer.userId) {
      const linkedUser = await User.findById(farmer.userId);
      if (linkedUser) {
        if (updates.name != null) linkedUser.name = updates.name;
        if (updates.mobile != null) linkedUser.mobile = updates.mobile;
        await linkedUser.save();
      }
    }

    res.json({ success: true, message: 'Farmer updated', data: farmer });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.deleteFarmer = async (req, res) => {
  try {
    const farmerLookup = { _id: req.params.id };
    if (req.user.role !== 'admin') {
      farmerLookup.createdBy = req.user.id;
    }

    const farmer = await Farmer.findOneAndDelete(farmerLookup);
    if (!farmer) return res.status(404).json({ success: false, message: 'Farmer not found' });
    const cropDeleteQuery = { farmerId: farmer._id };
    const queryDeleteQuery = { farmerId: farmer._id };

    if (req.user.role !== 'admin') {
      cropDeleteQuery.createdBy = req.user.id;
      queryDeleteQuery.fieldworkerId = req.user.id;
    }

    await Crop.deleteMany(cropDeleteQuery);
    await Query.deleteMany(queryDeleteQuery);
    if (farmer.userId) {
      await User.findByIdAndDelete(farmer.userId);
    }
    res.json({ success: true, message: 'Farmer deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
