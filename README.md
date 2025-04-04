# 🧠 Orgo - All-in-One Productivity App

Orgo is a beautifully minimal productivity companion that helps users manage their daily lives more efficiently with smart task tracking, expense management, and a personalized dashboard experience. Built with ❤️ using Flutter.

---

## 🚀 Features

### ✅ Tasks
- Create and manage tasks with deadlines
- Smart auto-star rating based on task completion behavior
- Completed tasks history in a collapsible popup
- Customizable date/time format from settings

### 💸 Finance
- Add & track expenses and income with category tagging
- Auto-calculated balance (supports negative values)
- Currency type customizable in settings
- Neatly organized transaction list with real-time updates

### 👤 Profile
- Update user name, age, and profile picture (camera/gallery supported)
- Settings sectioned by category (Finance / Task)
- Persist changes across app using Hive and `ValueListenableBuilder`

### 🏠 Home Dashboard (WIP)
- Dynamic greeting (e.g., Good morning, Siva!)
- Snapshot of task streaks, balance summary, and more coming soon

---

## 🧱 Tech Stack

- **Framework**: Flutter (cross-platform support for Android & iOS)
- **State Management**: Stateful widgets & `ValueListenableBuilder`
- **Local Database**: Hive for fast key-value storage
- **UI**: Material design, custom theming, modular widget structure

---

## 📦 Installation

```bash
git clone git@github.com:siva-sudhan/Orgo.git
cd Orgo
flutter pub get
flutter run
