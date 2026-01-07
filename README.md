# Habit Tracker 

A modern, minimalist habit tracking application built with **Flutter**. This app features a sleek **Glassmorphism UI**, detailed analytics with heatmaps, and robust local data persistence, designed to help users build and maintain consistent daily habits.

![App Screenshot](Screenshot%202025-12-28%20at%2012.24.37%E2%80%AFAM.png)

## Features

- **🎨 Glassmorphism UI**: A beautiful, frosted-glass interface for the navigation bar and UI elements, complete with smooth animations and transitions.
- **📊 Smart Analytics**:
    - **Heatmap Visualization**: Visual calendar view of your habit consistency over time.
    - **Daily Goal Progress**: Large, circular progress indicator to track daily completion rates.
    - **Detailed Stats**: Track total habits, daily completion, best streaks, and overall efficiency.
- **🌗 Dark & Light Mode**: Fully supported theming that adapts to your preference.
- **🔔 Smart Notifications**: Set specific reminder times for individual habits to stay on track.
- **💾 Local Storage**: Data is persisted locally using **Hive**, ensuring privacy and offline access.
- **⚡ Interactive Experience**:
    - Haptic feedback on interactions.
    - Swipe-to-delete functionality.
    - Animated page transitions.

## Tech Stack

- **Flutter**: SDK 3.8.1+
- **Dart**: Programming Language
- **Provider**: State Management
- **Hive**: Lightweight and fast key-value database for local storage
- **Flutter Local Notifications**: Cross-platform local notifications
- **Intl**: Date formatting
- **Timezone**: Notification scheduling support

## Screenshots

| Dashboard (Dark) | Analytics & Heatmap | Empty State |
|:---:|:---:|:---:|
| <img src="Screenshot 2025-12-28 at 12.24.37 AM.png" width="250" /> | <img src="Screenshot 2025-12-28 at 2.36.23 PM.png" width="250" /> | <img src="Screenshot 2025-12-28 at 12.19.27 AM.png" width="250" /> |

## Installation

1.  **Clone the repository**:
    ```bash
    git clone [https://github.com/yourusername/habit-tracker-glass.git](https://github.com/yourusername/habit-tracker-glass.git)
    cd habit-tracker-glass
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the application**:
    ```bash
    flutter run
    ```

### Note on Code Generation
This project uses Hive for data persistence. If you modify `habit_model.dart`, you must run the build runner to regenerate the type adapter:

```bash
flutter pub run build_runner build
