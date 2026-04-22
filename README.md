# 🎨 BIF Simple Paint

BIF Simple Paint is a cross-platform drawing application built with Flutter, targeting Android, Linux, and Windows. The project follows a modular, feature-first architecture to support scalability, maintainability, and team collaboration.

## ✨ Highlights

- Cross-platform drawing experience on mobile and desktop
- Feature-first, clean architecture organization
- Riverpod-based state management and dependency injection
- Responsive master-detail UX for desktop and mobile flows

## 🏗️ Architecture

This project combines **Clean Architecture** with a **Feature-First** folder structure.

- **Core (`lib/core/`)**: Shared infrastructure such as routing, services, layout primitives, theme, and utility helpers.
- **Features (`lib/features/`)**: Isolated domains containing their own models, repositories, providers, and UI.

### 🔄 Data Flow (MVVM + Clean Architecture)

To keep UI concerns separate from business logic, data flow is unidirectional:

1. **Views** observe providers and emit user actions.
2. **Providers (ViewModels)** manage state and orchestrate use-case behavior.
3. **Repositories** transform domain data and coordinate persistence.
4. **Services** perform low-level infrastructure operations.

## 📱 Cross-Platform Strategy

The app uses a responsive split-view strategy:

- **Desktop (Linux/Windows)**: Persistent two-pane layout with `canvas_list` on the left and `drawing_board` on the right.
- **Mobile (Android)**: Stack navigation where selecting a canvas routes to the drawing board screen.

## 🧰 Technology Stack

- **Framework**: Flutter
- **Language**: Dart (SDK `^3.11.5`)
- **State Management / DI**: `flutter_riverpod`
- **Linting**: `flutter_lints`

## 📂 Project Structure

```text
lib/
├── main.dart
├── core/
│   ├── layout/
│   │   └── responsive_split_view.dart
│   ├── providers/
│   │   └── active_canvas_id_provider.dart
│   ├── routing/
│   │   └── app_router.dart
│   ├── services/
│   │   ├── database_service.dart
│   │   └── local_storage_service.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   └── utils/
│       ├── geometry_helper.dart
│       └── platform_detector.dart
└── features/
    ├── canvas_list/
    │   ├── models/
    │   │   └── canvas_metadata.dart
    │   ├── providers/
    │   │   └── canvas_list_notifier.dart
    │   ├── repositories/
    │   │   └── canvas_list_repository.dart
    │   └── views/
    │       ├── screens/
    │       │   └── canvas_list_screen.dart
    │       └── widgets/
    │           ├── canvas_list_item.dart
    │           └── create_canvas_dialog.dart
    └── drawing_board/
        ├── models/
        │   ├── stroke_data.dart
        │   └── tool_type.dart
        ├── providers/
        │   ├── drawing_board_notifier.dart
        │   └── tool_selection_notifier.dart
        ├── repositories/
        │   └── drawing_session_repository.dart
        └── views/
            ├── screens/
            │   └── drawing_board_screen.dart
            └── widgets/
                ├── interactive_canvas.dart
                └── tool_palette.dart
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (ensure Linux and Windows desktop build requirements are installed)
- Git

### Installation

1. Clone the repository:

```bash
git clone https://github.com/Schooleo/BIF-Simple-Paint.git
```

2. Navigate to the project directory:

```bash
cd BIF-Simple-Paint
```

3. Install dependencies:

```bash
flutter pub get
```

### Running the App

- Android:

```bash
flutter run -d android
```

- Linux:

```bash
flutter run -d linux
```

- Windows:

```bash
flutter run -d windows
```

## ✅ Development Commands

```bash
flutter analyze
flutter test
```

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