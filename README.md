# Crosswatch

A cross-platform workout timer app built with Flutter, designed for high-intensity interval training (HIIT), CrossFit, and circuit workouts. Features nested workout structures, audio cues, notifications, and support for both time-based and rep-based exercises.

## Live Demo

**🌐 Try it now:** [crosswatch-app.github.io](https://crosswatch.github.io/crosswatch-app/)

The web version works as a Progressive Web App (PWA) - install it to your home screen for an app-like experience!

## Features

### Core Functionality
- **Cross-Platform Support**: Runs on Android, iOS, Linux, Windows, macOS, and Web (PWA)
- **Flexible Workout Structure**: 
  - Nested workout sets (e.g., circuits within circuits)
  - Time-based exercises (e.g., 30 seconds of jumping jacks)
  - Rep-based exercises (e.g., 20 push-ups)
  - Configurable rounds with rest periods between rounds
  - Optional transition/preparation time before each exercise
- **Real-Time Timer**: 
  - Large circular progress indicator
  - Current/total exercise counter
  - Next exercise preview
  - Pause/resume functionality
- **Audio Cues**: Platform-specific audio notifications
  - Countdown beeps (5, 4, 3, 2, 1)
  - Exercise completion chimes
  - Automatic platform detection (paplay on Linux, audioplayers on mobile)
- **Notifications**: Desktop and mobile notifications for exercise transitions
- **Screen Wake Lock**: Keeps screen on during active workouts
- **Workout Management**:
   - Pre-loaded example workouts
   - Create and edit workouts with intuitive builder
   - **AI-Powered Import**: Import workouts from URLs (CrossFit.com, etc.) or plain text descriptions
   - Import/export workouts as JSON
   - Duplicate and delete workouts

### User Interface
- Material Design 3 with teal/orange color scheme
- Workout list with estimated duration
- Detailed workout preview before starting
- Reorderable exercises in workout builder
- Visual hierarchy with color-coded icons (orange for sets, blue for exercises)

## Screenshots

(Add screenshots here)

## Getting Started

### Prerequisites

- **Flutter SDK**: 3.10.4 or higher
- **Dart**: 3.10.4 or higher

**Platform-Specific Requirements:**

**Android:**
- Android SDK 21+ (Android 5.0 Lollipop)
- Java 17 JDK
- NDK 29.0.14206865 (automatically downloaded by Gradle)

**Linux:**
- GTK 3.0 development libraries
- PulseAudio (for audio playback via paplay)

**iOS:**
- Xcode 14.0+
- iOS 12.0+

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd vibes
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   # Run on connected device/emulator
   flutter run

   # Or run on specific platform
   flutter run -d chrome        # Web
   flutter run -d android       # Android
   flutter run -d linux         # Linux
   flutter run -d macos         # macOS
   flutter run -d windows       # Windows
   ```

### Building for Production

```bash
# Android (generates APK)
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Android (generates App Bundle for Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release

# Linux
flutter build linux --release
# Output: build/linux/x64/release/bundle/crosswatch

# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Web
flutter build web --release

# For GitHub Pages deployment with custom base path:
flutter build web --release --base-href /crosswatch-app/
```

### Web / PWA Deployment

The app automatically deploys to GitHub Pages on every push to `main`. The workflow:

1. Builds the web version with Flutter
2. Deploys to GitHub Pages
3. Available as a PWA at your GitHub Pages URL

**Manual deployment:**
```bash
# Build for web
flutter build web --release

# Deploy to your hosting provider
# Upload contents of build/web/ to your server
```

**PWA Features:**
- Installable to home screen on mobile and desktop
- Offline support with service worker
- Full app experience in the browser
- Responsive design for all screen sizes

## Project Structure

```
vibes/
├── lib/
│   ├── main.dart                           # App entry point with service initialization
│   ├── models/
│   │   ├── workout.dart                    # Workout container model
│   │   └── workout_set.dart                # Exercise/set model with nested support
│   ├── providers/
│   │   └── workout_timer_provider.dart     # Timer state management (ChangeNotifier)
│   ├── screens/
│   │   ├── home_screen.dart                # Workout list with management options
│   │   ├── workout_builder_screen.dart     # Create/edit workouts
│   │   ├── workout_detail_screen.dart      # Workout overview before starting
│   │   └── workout_timer_screen.dart       # Main timer UI with circular progress
│   ├── services/
│   │   ├── audio_service.dart              # Cross-platform audio playback
│   │   ├── notification_service.dart       # Platform-specific notifications
│   │   └── workout_storage_service.dart    # JSON import/export, file management
│   └── widgets/
│       └── workout_card.dart               # Reusable widget for displaying sets
├── assets/
│   ├── workouts/
│   │   ├── example.json                    # Example HIIT workout
│   │   ├── beginner-friendly.json          # Beginner workout
│   │   ├── cindy-crossfit-wod.json        # CrossFit benchmark WOD
│   │   └── rest-test.json                  # Test workout for rest periods
│   └── sounds/
│       ├── complete.oga                    # Completion chime
│       └── countdown.oga                   # Countdown beeps
└── android/
    └── app/
        ├── build.gradle.kts                # Android build configuration
        └── src/main/AndroidManifest.xml    # Android permissions & config
```

## JSON Workout Schema

Workouts are defined in JSON format:

### Workout Object
```json
{
  "name": "Workout Name",
  "description": "Optional description",
  "sets": [...]
}
```

### Set Object
Sets can be **leaf sets** (exercises) or **container sets** (groups):

**Leaf Set (Exercise):**
```json
{
  "name": "Push-ups",
  "description": "Standard push-ups",
  "type": "reps",           // or "time"
  "value": 20,              // reps or seconds
  "duration": 60,           // optional: max time for rep exercises
  "transitionTime": 5,      // optional: prep time (default: 5s)
  "rounds": 1,              // optional: repeat count (default: 1)
  "restBetweenRounds": 30   // optional: rest between rounds
}
```

**Container Set (Group):**
```json
{
  "name": "Main Circuit",
  "description": "3 rounds for time",
  "sets": [...],            // nested sets
  "rounds": 3,              // repeat count
  "restBetweenRounds": 60,  // rest between rounds
  "transitionTime": 5       // prep time before starting
}
```

**Special Values:**
- `transitionTime: 0` - No prep time, start immediately (useful for rest periods)
- `type: null` - Container set (must have nested `sets` array)

See `assets/workouts/` for complete examples.

## Dependencies

### Runtime Dependencies
- **provider** `^6.1.1` - State management
- **audioplayers** `^6.1.0` - Cross-platform audio playback
- **wakelock_plus** `^1.2.0` - Prevent screen sleep during workouts
- **flutter_local_notifications** `^18.0.1` - Platform notifications
- **path_provider** `^2.1.1` - Access to file system directories
- **path** `^1.8.3` - Path manipulation utilities
- **file_picker** `^8.0.0` - Import/export file dialogs
- **http** `^1.2.0` - HTTP requests for AI import
- **html** `^0.15.4` - HTML parsing for web scraping
- **flutter_secure_storage** `^9.0.0` - Encrypted API key storage
- **google_generative_ai** `^0.4.6` - Gemini AI integration
- **cupertino_icons** `^1.0.8` - iOS-style icons

### Dev Dependencies
- **flutter_test** - Testing framework
- **flutter_lints** `^6.0.0` - Linting rules

## Architecture

### State Management
- **Provider pattern** for workout timer state
- `WorkoutTimerProvider` manages:
  - Exercise progression and transitions
  - Timer state (running/paused/stopped)
  - Rest periods and round counting
  - Audio and notification triggers

### Timer Logic Flow
1. **Workout Flattening**: Nested workout structure converted to flat exercise list
2. **Phase System**: Each exercise has transition phase (prep) and active phase
3. **Round Management**: Exercises repeat with rest periods between rounds
4. **Countdown**: Audio beeps at 5-4-3-2-1 seconds (uses `ceil()` for display)
5. **Transitions**: 1-second delay between exercises to avoid audio collision

### Cross-Platform Audio
- **Linux**: Uses `paplay` command with bundled `.oga` files
- **Android/iOS**: Uses `audioplayers` package with asset sources
- Automatic platform detection with fallback support

### Cross-Platform Notifications
- **Android**: `AndroidNotificationDetails` with workout channel
- **iOS**: `DarwinNotificationDetails` with alerts and sounds
- **Linux**: `LinuxNotificationDetails` with urgency levels

## Development

### Adding New Workouts

Create a JSON file in `assets/workouts/` following the schema above, then add it to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/workouts/
```

### Modifying Timer Behavior

Key file: `lib/providers/workout_timer_provider.dart`

Important methods:
- `_flattenWorkout()` / `_flattenSet()` - Converts nested structure to flat list
- `_initializeExercise()` - Sets up transition/active phases
- `_onTimerComplete()` - Handles phase transitions
- `_moveToNextExercise()` - Advances to next exercise with rest periods

### Testing on Physical Devices

**Android:**
```bash
# Enable USB debugging on your device
adb devices
flutter install
# Or drag-and-drop the APK from build/app/outputs/flutter-apk/
```

**iOS:**
```bash
flutter run -d <device-id>
# Requires Apple Developer account for physical devices
```

### Common Issues

**Linux Audio Not Working:**
- Ensure PulseAudio is installed: `which paplay`
- Check audio service initialization in logs

**Android Build Errors:**
- Verify NDK is installed: `~/Android/Sdk/ndk/`
- Accept licenses: `flutter doctor --android-licenses`
- Clear build cache: `flutter clean && flutter pub get`

**Notifications Not Showing:**
- Check notification permissions in device settings
- Verify notification channel is created (Android)

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository** and create a feature branch
2. **Follow Flutter style guide** - run `flutter analyze` before committing
3. **Test on multiple platforms** if possible
4. **Update documentation** for new features
5. **Add example workouts** for new exercise types
6. **Submit a pull request** with a clear description

### Code Style
- Use `flutter format .` to format code
- Follow Material Design guidelines for UI
- Add comments for complex timer logic
- Use meaningful variable names

### Testing
```bash
flutter test
flutter analyze
```

## Roadmap

- [ ] Workout history tracking and statistics
- [ ] Custom audio cues (voice coaching, music integration)
- [ ] Exercise video/image demonstrations
- [ ] Social features (share workouts, leaderboards)
- [ ] Wearable device integration (heart rate monitoring)
- [ ] Cloud sync for workouts across devices
- [ ] Progressive overload tracking
- [ ] Rest timer between sets
- [ ] Custom color themes

## License

MIT License

Copyright (c) 2025 Crosswatch Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Sound effects from [OpenGameArt](https://opengameart.org/)
- Inspired by CrossFit training methodologies
- Thanks to all contributors and testers

## Support

For issues, feature requests, or questions:
- Open an issue on GitHub
- Check existing documentation in `/docs`
- Review example workouts in `/assets/workouts`

---

**App Name**: Crosswatch  
**Package ID**: `com.crosswatch.app`  
**Current Version**: 1.0.0+1  
**Platforms**: Android, iOS, Linux, Windows, macOS, Web
