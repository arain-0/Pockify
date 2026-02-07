# Pockify

Save your favorite social media content. Access anytime.

> **Note:** This project is still under development.

## Preview

<p align="center">
  <img src="screenshots/preview.png" width="280" />
</p>

## Features

- Save videos from TikTok, Instagram, YouTube, Twitter
- Offline viewing
- Clean and intuitive UI
- Premium features available

## Supported Platforms

| Platform | Status |
|----------|--------|
| TikTok | Active |
| Instagram | Active |
| YouTube | Active |
| Twitter/X | Active |
| Facebook | Active |
| Reddit | Active |
| Vimeo | Active |

## Installation

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

## API Configuration

Set your RapidAPI key in `lib/core/config/api_config.dart`:

```dart
static const String rapidApiKey = 'YOUR_RAPIDAPI_KEY';
```

## Tech Stack

- Flutter
- BLoC State Management
- Hive (Local Storage)
- Dio (HTTP Client)

## License

MIT License
