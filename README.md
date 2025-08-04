# 📱 Clipus - Social Media App

**Clipus** is a complete mobile social media application built with **Flutter** and **Firebase**, featuring modern UI/UX design with black and white theming, video/image sharing, real-time messaging, and comprehensive admin management.

## 🎯 Features

### 🔐 Authentication
- **Email/Password Login & Signup** with Firebase Auth
- **Password Reset** functionality
- **Account Management** (change password, delete account)
- **Automatic session management** with auth state persistence
- **Admin Panel** with hardcoded credentials (`admin` / `clipus2024`)

### 🏠 Home Feed
- **YouTube-style horizontal scroll** for browsing posts
- **Shorts-style vertical scroll** for immersive viewing
- **Real-time post loading** with pagination
- **Interactive stories** section
- **Pull-to-refresh** functionality

### 👤 User Profiles
- **Profile customization** (photo, bio, display name)
- **Follower/Following system** with real-time counts
- **Post gallery** with grid layout
- **Privacy controls** (public/private accounts)
- **User verification** status display

### 💬 Real-Time Messaging
- **Firebase Firestore** powered chat system
- **Individual and group chats**
- **Message read receipts**
- **Media sharing** (images/videos)
- **Message deletion** and editing
- **Typing indicators**

### 📤 Media Upload
- **Image and video upload** to Firebase Storage
- **Caption and hashtag** support
- **Privacy settings** per post
- **Multiple media** per post
- **Auto-compression** and optimization

### 🔍 Search & Discovery
- **Real-time user search** by username/display name
- **Post search** by captions and hashtags
- **Trending hashtags**
- **Suggested users** based on activity

### ⚙️ Settings & Preferences
- **Dark/Light mode** toggle with persistence
- **Push notification** controls
- **Privacy settings** management
- **Account security** options
- **Data export/deletion** tools

### 👑 Admin Panel
- **Protected admin login** (admin/clipus2024)
- **User management** (view, warn, ban, terminate, unban)
- **Custom ban/termination** screens
- **Email notifications** to admin via EmailJS
- **User activity monitoring**
- **Content moderation** tools

### 🔔 Notification System
- **Real-time notifications** for likes, comments, follows
- **Warning and ban** notifications
- **Message notifications**
- **In-app notification** center
- **Push notification** support

## 🏗️ Architecture

### 📁 Project Structure
```
lib/
├── main.dart                   # App entry point
├── models/                     # Data models
│   ├── user_model.dart
│   ├── post_model.dart
│   ├── message_model.dart
│   └── notification_model.dart
├── providers/                  # State management
│   ├── auth_provider.dart
│   ├── theme_provider.dart
│   ├── user_provider.dart
│   ├── post_provider.dart
│   ├── chat_provider.dart
│   └── notification_provider.dart
├── screens/                    # UI screens
│   ├── splash_screen.dart
│   ├── auth/
│   ├── main/
│   ├── settings/
│   └── notifications/
├── widgets/                    # Reusable widgets
│   ├── custom_text_field.dart
│   ├── loading_button.dart
│   ├── post_card.dart
│   └── story_list.dart
└── services/
    └── firebase_options.dart
```

### 🏛️ State Management
- **Provider Pattern** for reactive state management
- **Separate providers** for different app domains
- **Optimistic updates** for better UX
- **Error handling** with user feedback

### 🗄️ Firebase Collections
```
users/                          # User profiles and settings
posts/                          # User posts with media
chats/                          # Chat conversations
  └── messages/                 # Individual messages
notifications/                  # User notifications
admin_actions/                  # Admin moderation logs
```

## 🎨 Design System

### 🎭 Theme
- **Black and white** modern aesthetic
- **Responsive design** for all screen sizes
- **Consistent typography** using Inter font family
- **Material Design 3** components
- **Dark/Light mode** support

### 🧩 Components
- **Custom text fields** with validation
- **Loading buttons** with spinner states
- **Post cards** with media support
- **Story circles** with gradient borders
- **Notification badges** with unread counts

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK** (3.0.0 or later)
- **Dart SDK** (2.17.0 or later)
- **Firebase Project** with Authentication, Firestore, and Storage enabled
- **Android Studio** / **VS Code** with Flutter extensions

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/clipus.git
cd clipus
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication (Email/Password)
   - Create Firestore database
   - Enable Firebase Storage
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update `lib/services/firebase_options.dart` with your project credentials

4. **EmailJS Setup** (for admin notifications)
   - Create account at [EmailJS](https://www.emailjs.com/)
   - Update admin email configuration in admin panel

5. **Run the app**
```bash
flutter run
```

## 📱 App Flow

### 🔑 Authentication Flow
1. **Splash Screen** → Check authentication state
2. **Login Screen** → Email/password authentication
3. **Signup Screen** → Account creation with validation
4. **Main Screen** → Bottom navigation with 5 tabs

### 🏠 Main Navigation
- **Home** → Feed with posts and stories
- **Search** → User and content discovery
- **Upload** → Media creation and sharing
- **Messages** → Real-time chat system
- **Profile** → User profile and settings

### 👑 Admin Features
- **Admin Login** → Separate admin authentication
- **User Management** → View and moderate users
- **Action History** → Track all admin actions
- **Email Notifications** → Automatic admin alerts

## 🔧 Configuration

### 🔥 Firebase Setup
Update `lib/services/firebase_options.dart`:
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'your-api-key',
  appId: 'your-app-id',
  messagingSenderId: 'your-sender-id',
  projectId: 'your-project-id',
  storageBucket: 'your-storage-bucket',
);
```

### 📧 EmailJS Configuration
Configure admin email settings in the admin panel:
```dart
// Admin credentials (change in production)
static const String adminUsername = 'admin';
static const String adminPassword = 'clipus2024';
static const String adminEmail = 'tykirussmith60@gmail.com';
```

## 🛠️ Development

### 🧪 Testing
```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

### 🔍 Debugging
- Use **Flutter Inspector** for widget debugging
- **Firebase Console** for backend monitoring
- **Provider DevTools** for state management debugging

### 📦 Building
```bash
# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

## 📝 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **Firebase** for the backend infrastructure
- **Material Design** for the design system
- **Provider Package** for state management
- **Community packages** that made this possible

## 📞 Support

For support, email `support@clipus.app` or join our community Discord.

---

**Built with ❤️ using Flutter and Firebase**

*Share Your World with Clipus* 🎬✨