# Contributing

Thanks for helping improve Personal Tracker. Changes should preserve the app's offline-first behavior, privacy controls, and support for existing saved data.

## Before you start

- Search existing issues and open an issue for larger changes.
- Keep changes focused and avoid adding packages without a clear need.
- Never include API keys, service-role keys, personal tracker data, or unredacted logs in a change.

## Development

1. Install the stable Flutter SDK.
2. Run `flutter pub get`.
3. Make the change and add or update tests where behavior changes.
4. Run these checks before opening a pull request:

   ```bash
   dart format --set-exit-if-changed lib test
   flutter analyze
   flutter test
   flutter build apk --debug
   ```

5. Describe the user-visible change and the checks you ran. Redact personal data from screenshots and logs.

## Pull requests

- Keep the summary concise and explain any behavior or data-format changes.
- Include tests for bug fixes and new behavior.
- Do not commit generated build output, credentials, or real user data.
- Call out platform-specific behavior and any manual setup required.
