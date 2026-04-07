# Admin Dashboard - Quick Start Guide

## 🚀 Setup & Run

### Step 1: Start Backend API
```bash
cd /Users/apple/WorkSpace/FarmerCropApp/backend
node server.js
```
Backend will run on: http://localhost:5000

### Step 2: Create or Update an Admin User
Use a backend user whose `role` is `admin`. The normal `/api/auth/register` route creates a `fieldworker`, not an admin, so you need to promote a user in the database or seed one separately.

### Step 3: Start Admin Dashboard
```bash
cd /Users/apple/WorkSpace/FarmerCropApp/admin_dashboard
npm install
node server.js
```
Dashboard will run on: http://localhost:3000

### Step 4: Open in Browser
Open your browser and go to:
```
http://localhost:3000
```

## 🔐 Login Credentials

Use the email and password for a backend user whose role is `admin`.

## 📊 Dashboard Features

### Main Dashboard
- Total Users, Farmers, Crops statistics
- Synced vs Pending farmers
- Recent farmers table
- Farmer-Crop relationships

### Farmers Page
- Complete list of all farmers
- GPS coordinates display
- Village and contact information
- Sync status indicators

### Crops Page
- All crops with details
- Linked farmer information
- Area, season, sowing date
- Crop type classification

## 🎨 UI Features

✅ Beautiful gradient login page  
✅ Responsive design  
✅ Clean modern interface  
✅ Color-coded status badges  
✅ Auto-refresh every 30 seconds  
✅ Session management  

## 🔧 Configuration

Edit `.env` file to change settings:
```env
API_BASE_URL=http://localhost:5000/api
PORT=3000
```

## 📱 Browser Support

✅ Chrome, Firefox, Safari, Edge  
✅ Mobile browsers (responsive)  
✅ Tablet browsers  

## 🔒 Security

- Session-based authentication
- Protected routes
- JWT token integration
- 24-hour session timeout

## 📝 Troubleshooting

**Dashboard won't start:**
- Check if port 3000 is available
- Ensure backend is running on port 5000

**Can't login:**
- Register admin user first (Step 2)
- Check backend is running
- Verify credentials

**No data showing:**
- Add farmers via mobile app
- Check backend API is responding
- Verify authentication token

## 🎉 You're All Set!

Your admin dashboard is ready to manage all farmers, crops, and users!
