# 📚 WatchList

A beautiful Flutter app for bookmarking your anime, manga, TV shows, movies, and podcasts with **parallax depth cards**.

![Build](https://github.com/8lackR0z3/watchlist/actions/workflows/build.yml/badge.svg)

## ✨ Features

- **Parallax Depth Cards** - 3D tilt effect with dynamic shadows when you drag
- **Category Organization** - Anime 🎬, Manga 📖, TV 📺, Movie 🎥, Podcast 🎧
- **Progress Tracking** - Keep track of episodes, seasons, and chapters
- **Quick Access** - Tap a card to open the URL directly
- **Beautiful Dark UI** - Easy on the eyes for late-night binging
- **Offline Storage** - SQLite database keeps your bookmarks safe

## 📱 How to Use

| Action | Effect |
|--------|--------|
| **Tap** card | Opens the URL in browser |
| **Long press** card | Shows options menu (edit/delete) |
| **Double tap** card | Flips to reveal details |
| **Drag** on card | 3D parallax tilt effect |
| **Pull down** | Refresh bookmarks |

## 🚀 Download APK

1. Go to the [Actions tab](https://github.com/8lackR0z3/watchlist/actions)
2. Click the latest successful workflow run
3. Download `watchlist-apk` from Artifacts
4. Install on your Android device

## 🛠️ Build from Source

```bash
git clone https://github.com/8lackR0z3/watchlist.git
cd watchlist
flutter pub get
flutter build apk --release
```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── bookmark.dart         # Bookmark model + Category enum
├── services/
│   └── database_service.dart # SQLite CRUD operations
├── screens/
│   └── home_screen.dart      # Main screen with grid
└── widgets/
    ├── parallax_card.dart    # 3D tilt card widget
    └── bookmark_edit_sheet.dart # Add/Edit form
```

## 🙏 Credits

- Parallax card inspiration: [Andy Merskin's CodePen](https://codepen.io/andymerskin/pen/XNMWvQ)
- Built autonomously by Claude AI

## 📄 License

MIT
