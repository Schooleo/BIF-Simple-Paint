# 🎨 BIF Simple Paint

BIF Simple Paint is a cross-platform Flutter drawing app for **Android**, **Linux**, and **Windows**. It supports quick sketching, shape-based editing, local canvas persistence, export flows, and platform-specific controls for mobile and desktop.

## ✨ Highlights

- Responsive **canvas list + drawing board** experience across mobile and desktop
- Create, open, rename, delete, and export saved canvases
- Drawing tools for **select**, **brush**, **eraser**, and **shapes**
- Fill + stroke styling with live stroke-width preview
- Mobile multi-touch gestures and desktop mouse/keyboard shortcuts
- Local persistence with `.mypt` canvas files and image export
- Riverpod-based state management with a feature-first structure

## 🧭 Platform UX

### Desktop (Linux / Windows)
- Split-view workflow with the **Canvas List** on the left and the **Drawing Board** on the right
- Keyboard shortcuts for editing and navigation
- Mouse wheel zoom and **middle-mouse drag panning**
- Drag-and-drop `.mypt` loading into the drawing board
- Bottom-right custom toast notifications

### Mobile (Android)
- Canvas list screen with navigation into a full-screen drawing board
- New canvases open directly into the board with the **title focused for quick rename**
- Floating bottom toolbars optimized for touch
- Pinch, pan, and two-finger object interactions
- Export directly to the device gallery

## 🖌️ Drawing Features

### Tools
- **Select** tool for selecting and transforming shapes
- **Brush** tool for freehand strokes
- **Eraser** tool with real eraser icon and larger size range
- **Shapes** including:
  - line
  - rectangle
  - square
  - oval
  - circle
  - arrow
  - text

### Styling
- Stroke color selection
- Fill color selection for supported shapes
- Transparent / no-fill option
- Stroke width adjustment with a **centered circular live preview**
- Selection border and resize handles stay readable across zoom levels

### Canvas interactions
- Undo / redo history
- Title editing directly in the drawing board
- Accurate saved-canvas loading instead of resetting to a new draft
- Canvas loading overlay for create/open/export flows

## 🤏 Gestures and Input

### Mobile gestures
- **One-finger drag** to draw or move/resize selected content depending on the active tool
- **Two-finger pan** to move around the board
- **Two-finger pinch** to zoom the board
- **Two-finger pinch on a selected object** to resize the object in select mode
- Zoom is clamped to supported limits instead of snapping back unexpectedly

### Desktop mouse controls
- **Mouse wheel** to zoom in/out
- **Middle mouse click + drag** to pan around the canvas
- Click to select shapes and drag resize handles for resizing

## ⌨️ Desktop Keybinds

### History and file actions
- `Ctrl + Z` — Undo
- `Ctrl + Y` — Redo
- `Ctrl + Shift + Z` — Redo
- `Ctrl + E` — Export
- `Ctrl + O` — Load canvas

### Tool switching
- `Q` — Select
- `W` — Brush / Stroke
- `E` — Eraser
- `R` — Open shape menu

### Shape menu navigation
- `Arrow keys` — Move through shape choices
- `Enter` — Confirm selected shape
- `Escape` — Close shape menu

## 💾 Canvas Management

From the **Canvas List**, users can:
- create a new canvas
- open an existing saved canvas
- load a `.mypt` file from disk
- rename a canvas
- export a canvas
- delete a canvas

Saved canvases keep thumbnails and metadata for quick browsing.

## 📤 Export Behavior

- Export supports **PNG** and **JPEG** from the drawing board
- Mobile export saves to the gallery
- Desktop export saves to a chosen file path
- Exported images are rendered as **square images** with:
  - centered content
  - padding around the artwork
  - board-independent export output rather than the current viewport crop

## 🏗️ Architecture

This project follows a **feature-first** structure with Riverpod-driven state management.

- **Core (`lib/core/`)**: routing, services, layout, theme, shared widgets, and utility helpers
- **Canvas List (`lib/features/canvas_list/`)**: recent canvases, search, metadata, and saved-canvas actions
- **Drawing Board (`lib/features/drawing_board/`)**: tools, gestures, canvas rendering, export, and editing state

### Data Flow
1. **Views** render UI and forward user input
2. **Providers / Notifiers** manage UI state and interaction logic
3. **Repositories** coordinate persistence and file access
4. **Utilities / Services** handle serialization, storage, thumbnails, and export rendering

## 🧰 Technology Stack

- **Framework**: Flutter
- **Language**: Dart (`^3.11.5`)
- **State Management / DI**: `flutter_riverpod`
- **Code generation**: `riverpod_generator`, `build_runner`
- **File picking**: `file_picker`
- **Gallery export**: `gal`
- **Desktop drag & drop**: `desktop_drop`
- **Image processing**: `image`

## 📂 Project Structure

```text
lib/
├── main.dart
├── core/
│   ├── layout/
│   ├── providers/
│   ├── routing/
│   ├── services/
│   ├── theme/
│   ├── utils/
│   └── widgets/
└── features/
    ├── canvas_list/
    │   ├── models/
    │   ├── providers/
    │   ├── repositories/
    │   └── views/
    │       ├── screens/
    │       └── widgets/
    └── drawing_board/
        ├── models/
        │   └── shape/
        ├── providers/
        ├── repositories/
        ├── utils/
        └── views/
            ├── screens/
            └── widgets/
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK
- Git
- Platform build requirements for Android / Linux / Windows

### Installation

```bash
git clone https://github.com/Schooleo/BIF-Simple-Paint.git
cd BIF-Simple-Paint
flutter pub get
```

### Run

```bash
flutter run -d android
flutter run -d linux
flutter run -d windows
```

## ✅ Development Commands

```bash
flutter analyze
flutter test
```

## 🎯 Branding

The app now includes updated logo and launcher icon assets under `assets/images/logo.png` and platform launcher resources.

### Contributors

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/KwanTheAsian">
        <img src="https://avatars.githubusercontent.com/KwanTheAsian" width="100px;" alt="KwanTheAsian"/><br />
        <sub><b>23127020 - Biện Xuân An</b></sub>
      </a><br />
      📝 Business Analyst / Developer
    </td>
    <td align="center">
      <a href="https://github.com/PaoPao1406">
        <img src="https://avatars.githubusercontent.com/PaoPao1406" width="100px;" alt="PaoPao1406"/><br />
        <sub><b>23127025 - Đoàn Lê Gia Bảo</b></sub>
      </a><br />
      🎨 UI/UX Designer / Developer
    </td>
    <td align="center">
      <a href="https://github.com/VNQuy94">
        <img src="https://avatars.githubusercontent.com/VNQuy94" width="100px;" alt="VNQuy94"/><br />
        <sub><b>23127114 - Văn Ngọc Quý</b></sub>
      </a><br />
      ⚙️ System Designer / Developer
    </td>
    <td align="center">
      <a href="https://github.com/Schooleo">
        <img src="https://avatars.githubusercontent.com/Schooleo" width="100px;" alt="Schooleo"/><br />
        <sub><b>23127136 - Lê Nguyễn Nhật Trường</b></sub>
      </a><br />
      💻 Project Manager / Developer
    </td>
  </tr>
</table>
