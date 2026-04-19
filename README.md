# OpenGym

OpenGym is a comprehensive fitness and workout tracking application built with Flutter. It features extensive workout logging, a custom exercise catalogue, progress tracking, dynamic UI theming, and an integrated camera/gallery system for tracking physique progress.

## Project Status

**This is a personal project.** It was built to serve specific personal fitness tracking needs. The codebase is provided here "as is" for reference, but there is no active development, and **no future updates are planned.**

## Codebase Structure & File Descriptions

The `lib` directory is organized into modules to separate UI, state, data models, and services:

### `lib/` (Root)
* `main.dart` - Application entry point, initializing Hive storage, services, providers, and setting up the app theme.
* `driver_main.dart` - Entry point for automated UI tests and Flutter Driver.

### `data/`
* `preset_themes.dart` - Contains the predefined UI color themes available within the application (e.g., Moonstone, default themes).

### `models/`
Defines the core data structures and objects storing workout and user data, tracked via Hive DB:
* `app_theme_profile.dart` - Defines theme colors and style configurations.
* `custom_measurement.dart` - Models user metrics/body measurements.
* `day_workout.dart` - Represents a planned or completed standard workout day.
* `exercise_definition.dart` - Models the metadata for an exercise inside the library.
* `exercise_instance.dart` - Represents an exercise loaded into a specific routine.
* `exercise_set.dart` - Data structure for reps, weights, and configurations of a single set.
* `log_entry.dart` - Models completion records stored in the log book.
* `media_item.dart` - Models metadata for images/videos taken in the physique gallery.
* `program_workout.dart` - Represents a multi-week workout program template.
* `week_workout.dart` - Represents a weekly routine combining several DayWorkouts.

### `providers/`
State management built on top of `ChangeNotifier` to tie data logic with the UI.
* `exercise_library_provider.dart` - Manages state for the custom exercise definitions/tags.
* `theme_provider.dart` - Hands out active UI theme data to the app interface.
* `workout_provider.dart` - Central state manager orchestrating schedules, catalogue pools, routines, and workout history.

### `screens/`
The visual pages and interfaces of the application.
* `active_workout_screen.dart` - The timer and progress tracking screen while performing a workout.
* `camera_mockups.dart` - UI overlays/silhouettes used to help structure physique photos.
* `camera_screen.dart` / `camera_view_page.dart` - Custom camera module mapping out sensor manipulation and image/video captures.
* `charts_screen.dart` - visual graphs rendering progress data.
* `custom_palette_screen.dart` - Color picker utility for custom app themes.
* `day_editor_screen.dart` - UI for building/modifying a single workout day.
* `day_overview_screen.dart` - Brief summary view showing what to expect from a workout.
* `delete_data_screen.dart` - Utility page for erasing local databases.
* `gallery_picker_screen.dart` - UI to browse physique media and albums.
* `guide_book_screen.dart` / `guide_detail_screen.dart` - Offline documentation explaining how to use the app.
* `home_screen.dart` - The main calendar view orchestrating scheduled tasks.
* `import_conflict_screen.dart` / `import_export_screen.dart` - Screens for managing JSON data backup and restoring.
* `library_screen.dart` - Displaying the catalog of Custom Exercise Definitions.
* `log_book_screen.dart` - Chronological history of completed workouts.
* `logged_item_stats_screen.dart` - Performance statistics for a specific past session.
* `media_view_page.dart` - Full-screen viewer for photos and videos.
* `program_detail_screen.dart` / `week_detail_screen.dart` - Overviews for structured multi-week / weekly templates.
* `tags_manager_screen.dart` - Managing filtering tags for the exercise library.
* `theme_settings_screen.dart` - Preferences for swapping active UI colorings.
* `workouts_screen.dart` - Hub displaying templates and catalogue workflows.

### `services/`
Background operations, DB interactions, and file tasks.
* `media_storage_service.dart` - Handles reading/saving/managing physics photos & videos from disk.
* `seed_data.dart` - Contains default templates (e.g., 24-week program) used to populate a fresh database.
* `storage_service.dart` - Central abstract class mapping Hive database reads and writes via JSON encoding.

### `utils/`
* `constants.dart` - Constants for padding, fonts, and foundational sizes.
* `helpers.dart` - Helper functions handling complex dates, UUID generation, or text formatting.

### `widgets/`
Reusable UI components.
* `album_selection_sheet.dart` / `tag_selection_sheet.dart` - Bottom sheets for choosing items from lists.
* `exercise_stats_dialog.dart` - Dialog tracking PRs and volumes.
* `guide_visuals.dart` - Assets/icons loaded into the guide book.
* `image_view_item.dart` / `video_view_item.dart` / `video_thumbnail_player.dart` - Components framing gallery media items.
* `media_calendar_picker.dart` - Custom date picking utility.
* `timer_picker_dialog.dart` - Rest-timer adjustment component.

## Notes

- **Assets:** Only the `lib` (source code) and `assets` directories are included in this repository.
- **FFmpeg:** This project utilizes FFmpeg for video processing within the camera and media features. However, the necessary FFmpeg binaries and external setup files are **not** included in this GitHub repository. If you attempt to run or build this app from source, you will need to configure the FFmpeg dependencies for your target platform independently.
