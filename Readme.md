# Farmer Crop App - Fieldworker App with Offline Sync

## 📱 Project Overview

**Fieldworker App with Offline Sync** ek mobile application hai jo agriculture field officers / extension workers ke liye banayi gayi hai. Is app ka main purpose hai farmers ke data ko collect, manage aur sync karna, even jab internet available na ho.

### 🎯 Key Features

- ✅ **Offline-First Architecture** - Network ke bina bhi kaam karta hai
- ✅ **Automatic Background Sync** - Internet milte hi data sync ho jata hai
- ✅ **Conflict Resolution** - Data conflicts ko automatically handle karta hai
- ✅ **JWT Authentication** - Secure login system
- ✅ **MongoDB Atlas** - Cloud database for scalability
- ✅ **Clean Architecture** - Maintainable and scalable code structure

### 🎯 Use Cases

- Crop survey
- Farmer registration
- Soil & crop health data collection
- Government schemes monitoring
- Training & advisory delivery

---

## 🏗️ Architecture

### Backend (Node.js + Express + MongoDB)
```
backend/
├── src/
│   ├── config/          # Database, environment, logger
│   ├── modules/
│   │   ├── auth/        # Authentication (JWT)
│   │   ├── farmer/      # Farmer CRUD operations
│   │   └── sync/        # Offline sync logic
│   ├── middlewares/     # Auth, error handling, rate limiting
│   └── utils/           # Response helpers, validators
└── server.js
```

### Frontend (Flutter)
```
frontend_flutter/
├── lib/
│   ├── core/
│   │   ├── config/      # App configuration
│   │   ├── network/     # Dio client, network info
│   │   └── errors/      # Exception handling
│   ├── features/
│   │   ├── auth/        # Login/Register
│   │   ├── farmer/      # Farmer management
│   │   └── sync/        # Background sync, conflict resolver
│   └── main.dart
```

---

## 🚀 Setup Instructions

### Backend Setup

1. **Navigate to backend directory:**
```bash
cd backend
```

2. **Install dependencies:**
```bash
npm install
```

3. **Create .env file:**
```bash
cp .env.example .env
```

4. **Update .env with your MongoDB Atlas credentials:**
```env
PORT=5000
MONGODB_URI=mongodb+srv://<username>:<password>@cluster.mongodb.net/farmercrop?retryWrites=true&w=majority
JWT_SECRET=your_super_secret_jwt_key_here
JWT_EXPIRE=7d
NODE_ENV=development
```

5. **Start the server:**
```bash
npm run dev
```

Server will run on `http://localhost:5000`

### Frontend Setup

1. **Navigate to frontend directory:**
```bash
cd frontend_flutter
```

2. **Install Flutter dependencies:**
```bash
flutter pub get
```

3. **Update API URL in `lib/core/config/app_config.dart`:**
```dart
static const String baseUrl = 'http://YOUR_IP:5000/api';
```

4. **Run the app:**
```bash
flutter run
```

---

## 📡 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new fieldworker
- `POST /api/auth/login` - Login

### Farmers
- `POST /api/farmers` - Create farmer
- `GET /api/farmers` - Get all farmers
- `GET /api/farmers/:id` - Get single farmer
- `PUT /api/farmers/:id` - Update farmer
- `DELETE /api/farmers/:id` - Delete farmer

### Sync
- `POST /api/sync/sync` - Sync offline data
- `GET /api/sync/status/:deviceId` - Get sync status

---

## 🗄️ Database Schema

### Farmer Collection
```javascript
{
  "_id": "ObjectId",
  "name": "Ramesh Kumar",
  "village": "Rampur",
  "mobile": "9xxxxxxx",
  "createdBy": "fieldworker_id",
  "deviceId": "ANDROID-123",
  "syncStatus": "SYNCED",
  "createdAt": "ISODate",
  "updatedAt": "ISODate"
}
```

### Sync Metadata Collection
```javascript
{
  "deviceId": "ANDROID-123",
  "userId": "fieldworker_id",
  "lastSync": "ISODate",
  "recordsSynced": 120,
  "status": "SUCCESS"
}
```

---

## 🔄 Offline Sync Strategy

1. **Data Creation Offline:**
   - Data SQLite local database me save hota hai
   - `syncStatus = 'PENDING'` mark hota hai

2. **Background Sync:**
   - Har 15 minutes me background task check karta hai
   - Internet available hai to pending data sync karta hai

3. **Conflict Resolution:**
   - `LATEST_WINS` - Jo data latest hai wo win karega
   - `SERVER_WINS` - Server ka data priority lega
   - `CLIENT_WINS` - Local data priority lega

---

## 🔐 Security Features

- JWT token-based authentication
- Password hashing with bcrypt
- Rate limiting (100 requests per 15 minutes)
- Input validation
- CORS enabled

---

## 📦 Tech Stack

### Backend
- Node.js + Express.js
- MongoDB Atlas
- JWT Authentication
- Winston Logger
- Express Rate Limit

### Frontend
- Flutter
- SQLite (Local Database)
- Dio (HTTP Client)
- WorkManager (Background Sync)
- Connectivity Plus (Network Detection)

---

## 🧪 Testing

### Test Backend API
```bash
# Health check
curl http://localhost:5000/health

# Register
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"password123"}'

# Login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

---

## 📈 Scalability

- MongoDB Atlas auto-scaling
- Horizontal scaling with load balancers
- Background sync reduces server load
- Rate limiting prevents abuse
- Efficient indexing on database

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

---

## 📄 License

MIT License

---

## 👨‍💻 Developer

Built with ❤️ for Agriculture Extension Workers

**Contact:** Your contact information here
