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
```
---
## 🧱 Folder Structure

```bash
lib/
├── main.dart – App entry point
├── models/ – Hive models (Task, Transaction, User Settings)
│   ├── task.dart
│   ├── transaction.dart
│   └── user_settings.dart
├── pages/ – Main screens of the app
│   ├── home_page.dart
│   ├── finance_page.dart
│   ├── tasks_page.dart
│   └── profile_page.dart
├── widgets/ – Reusable UI components (optional)
│   └── balance_card.dart
├── utils/ – Utility functions (optional)
│   └── formatters.dart
```

## 📝 Roadmap

 - Add pie chart analytics on Home
 - Gamify task streaks
 - Add filters/sort options in Finance
 - Backup and sync across devices
 - Evolve into AI-powered social productivity platform ✨

---

## 🙌 Contributing
Currently a solo weekend project. Contributions and ideas are welcome!
Submit an issue or pull request to get started.

---

## 📄 License
MIT License

---

✨Made with Flutter by Siva Sudhan
