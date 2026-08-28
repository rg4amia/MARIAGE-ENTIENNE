# Graph Report - MARIAGE ENTIENNE  (2026-08-28)

## Corpus Check
- 158 files · ~484,945 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1724 nodes · 2345 edges · 104 communities (96 shown, 8 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `910f9b00`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app_colors.dart
- GeneratedPluginRegistrant.swift
- app_text_styles.dart
- settings_page.dart
- entrance_qr_page.dart
- auth_controller.dart
- table_detail_page.dart
- guest_access_page.dart
- guest_access_controller.dart
- invitations_page.dart
- micro_interactions.dart
- media-duration.ts
- shared_components.dart
- my_application.cc
- wedding_theme_page.dart
- home_page.dart
- web_video_recorder.dart
- guest_detail_page.dart
- guests_controller.dart
- State
- audio_recorder_page.dart
- animated_widgets.dart
- web_audio_recorder.dart
- main_shell_page.dart
- login_page.dart
- home_controller.dart
- invitation_card_generator.dart
- guest_repository.dart
- models_test.dart
- guests_page.dart
- video_recorder_page.dart
- Widget?
- tables_controller.dart
- invitation.dart
- StatelessWidget
- Win32Window
- media_player_page.dart
- tables_page.dart
- event_venue.dart
- wedding_header.dart
- auth_repository.dart
- guest-access/index.ts
- invitations_controller.dart
- venues_page.dart
- DESIGN.md
- guest_link.dart
- chair.dart
- package:get/get.dart
- guest-portal-web/manifest.json
- guest_seat.dart
- wedding_table.dart
- wWinMain
- table_repository.dart
- wedding_settings_repository.dart
- wedding_theme_controller.dart
- register_page.dart
- app_pages.dart
- 6. Plan d'Implementation
- profile.dart
- web/manifest.json
- guest_link_repository.dart
- Application Mariage Entienne
- Tables principales
- workspace_onboarding_controller.dart
- app_bottom_nav_bar.dart
- secure_local_storage.dart
- invitation_repository.dart
- 1. Prompt Produit Reorganise
- venues_controller.dart
- SupabaseClient
- Déploiement mobile, portail invité et Supabase
- chair_repository.dart
- supabase_config.dart
- validators.dart
- 7. Sprint MVP Recommande
- 2. Cadrage Fonctionnel
- package:supabase_flutter/supabase_flutter.dart
- entrance_qr.dart
- ADR-001 — Socle SaaS multi-tenant pour l'organisation de mariages
- ../../core/theme/app_colors.dart
- FlutterActivity
- weeding_app
- AGENTS.md
- sw.js
- wedding_palette.dart
- LaunchImage.imageset/README.md
- @mail
- Feuille de route — SaaS d'organisation de mariages
- event_venue_repository.dart
- app_routes.dart
- media_repository.dart
- WaveformStyle
- String?
- main.dart
- package:flutter/material.dart
- SingleTickerProviderStateMixin
- main_navigation_controller.dart
- qr_code_page.dart
- app_binding.dart
- GuestsController

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 24 edges
2. `AuthController` - 12 edges
3. `MessageHandler` - 12 edges
4. `Application Mariage Entienne` - 11 edges
5. `6. Plan d'Implementation` - 11 edges
6. `FlutterWindow` - 10 edges
7. `Create` - 10 edges
8. `WndProc` - 10 edges
9. `MessageHandler` - 9 edges
10. `Tables principales` - 8 edges

## Surprising Connections (you probably didn't know these)
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  weeding_app/windows/runner/main.cpp → weeding_app/windows/runner/utils.cpp
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  weeding_app/windows/runner/win32_window.cpp → weeding_app/windows/runner/win32_window.h
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  weeding_app/linux/runner/my_application.cc → weeding_app/linux/flutter/generated_plugin_registrant.cc
- `main()` --calls--> `my_application_new()`  [INFERRED]
  weeding_app/linux/runner/main.cc → weeding_app/linux/runner/my_application.cc
- `OnCreate` --calls--> `RegisterPlugins()`  [INFERRED]
  weeding_app/windows/runner/flutter_window.h → weeding_app/windows/flutter/generated_plugin_registrant.cc

## Import Cycles
- None detected.

## Communities (104 total, 8 thin omitted)

### Community 0 - "app_colors.dart"
Cohesion: 0.04
Nodes (51): AppColors, background, cardDark, cardDarkText, dark, error, errorContainer, gold (+43 more)

### Community 1 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (35): Any, app_links, audio_session, Cocoa, file_selector_macos, Flutter, flutter_sound, FlutterAppDelegate (+27 more)

### Community 2 - "app_text_styles.dart"
Cohesion: 0.07
Nodes (27): app_colors.dart, app_text_styles.dart, package:google_fonts/google_fonts.dart, static TextStyle, static ThemeData get, wedding_palette.dart, AppTextStyles, bodyLg (+19 more)

### Community 3 - "settings_page.dart"
Cohesion: 0.07
Nodes (27): ../../data/repositories/wedding_settings_repository.dart, package:intl/date_symbol_data_local.dart, package:intl/intl.dart, build, _buildTextField, _buildWeddingInfoCard, colors, _confirmLogout (+19 more)

### Community 4 - "entrance_qr_page.dart"
Cohesion: 0.08
Nodes (24): @visibleForTesting, ../../data/models/entrance_qr.dart, ../../data/repositories/entrance_repository.dart, RealtimeChannel?, build, _buildActionChip, _buildActions, _buildCodeChip (+16 more)

### Community 5 - "auth_controller.dart"
Cohesion: 0.08
Nodes (24): ../../core/theme/wedding_theme_controller.dart, StreamSubscription, String get, authenticatedEntryRoute, _authRepository, _authSubscription, _clearControllers, emailController (+16 more)

### Community 6 - "table_detail_page.dart"
Cohesion: 0.06
Nodes (33): copyWith, createdAt, email, fromJson, fullName, Guest, id, phone (+25 more)

### Community 7 - "guest_access_page.dart"
Cohesion: 0.06
Nodes (30): audio_recorder_page.dart, ../../core/utils/invitation_card_generator.dart, GlobalKey, recorder_factory.dart, video_recorder_page.dart, build, _buildCardUnlocked, _buildError (+22 more)

### Community 8 - "guest_access_controller.dart"
Cohesion: 0.07
Nodes (29): ../../data/repositories/media_repository.dart, _client, currentStep, errorMessage, goToMediaChoice, guest, GuestAccessStep, _guestRepo (+21 more)

### Community 9 - "invitations_page.dart"
Cohesion: 0.06
Nodes (30): ../../data/models/guest_media.dart, Map, MaterialPageRoute, media_player_page.dart, build, color, count, createState (+22 more)

### Community 10 - "micro_interactions.dart"
Cohesion: 0.07
Nodes (31): _anim, backgroundColor, borderRadius, boxShadow, build, child, createState, _ctrl (+23 more)

### Community 11 - "media-duration.ts"
Cohesion: 0.11
Nodes (17): admin, corsHeaders, GuestTokenRecord, inlineScriptValue(), renderSPA(), ascii(), detectMediaDuration(), ElementHeader (+9 more)

### Community 12 - "shared_components.dart"
Cohesion: 0.08
Nodes (23): EdgeInsets, Gradient?, Size get, actions, actionText, backgroundColor, bottom, build (+15 more)

### Community 13 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, MyApplicationClass (+14 more)

### Community 14 - "wedding_theme_page.dart"
Cohesion: 0.06
Nodes (32): _accentController, _backgroundController, build, color, _ColorSlot, controller, createState, description (+24 more)

### Community 15 - "home_page.dart"
Cohesion: 0.07
Nodes (27): CustomPainter, ../navigation/main_navigation_controller.dart, build, _buildInvitationStatus, _buildKpiGrid, _buildQuickActions, _buildWeddingHeader, cardUnlocked (+19 more)

### Community 16 - "web_video_recorder.dart"
Cohesion: 0.08
Nodes (25): VideoElement?, build, _cameraReady, _chunks, createState, dispose, _elapsedSeconds, _formatDuration (+17 more)

### Community 17 - "guest_detail_page.dart"
Cohesion: 0.09
Nodes (22): ../../data/models/guest_link.dart, availableChairs, build, _confirmCancellation, _confirmDelete, controller, createState, _getInviteUrl (+14 more)

### Community 18 - "guests_controller.dart"
Cohesion: 0.08
Nodes (25): ../../data/models/guest_seat.dart, assignSeatToGuest, confirmedCount, createGuest, deleteGuest, filterStatus, getAllTables, getAvailableChairs (+17 more)

### Community 19 - "State"
Cohesion: 0.10
Nodes (29): State, StatefulWidget, TickerProviderStateMixin, LoginPage, _LoginPageState, _PasswordField, _PasswordFieldState, RegisterPage (+21 more)

### Community 20 - "audio_recorder_page.dart"
Cohesion: 0.08
Nodes (23): FlutterSoundRecorder, package:flutter_sound/flutter_sound.dart, Timer?, build, createState, dispose, _elapsedSeconds, _formatDuration (+15 more)

### Community 21 - "animated_widgets.dart"
Cohesion: 0.08
Nodes (29): Animation, Duration, TextStyle?, _anim, AnimatedCounter, _AnimatedCounterState, borderRadius, build (+21 more)

### Community 22 - "web_audio_recorder.dart"
Cohesion: 0.09
Nodes (21): dart:html, MediaRecorder?, MediaStream?, build, _chunks, createState, dispose, _elapsedSeconds (+13 more)

### Community 23 - "main_shell_page.dart"
Cohesion: 0.13
Nodes (15): ../../core/widgets/app_bottom_nav_bar.dart, ../guests/guests_page.dart, ../home/home_page.dart, ../invitations/invitations_page.dart, main_navigation_controller.dart, ../settings/settings_page.dart, ../tables/tables_page.dart, build (+7 more)

### Community 24 - "login_page.dart"
Cohesion: 0.12
Nodes (15): TextEditingController, _bgCtrl, build, _buildInput, _buildLabel, controller, createState, dispose (+7 more)

### Community 25 - "home_controller.dart"
Cohesion: 0.11
Nodes (18): ../../data/models/profile.dart, Profile? get, cardUnlocked, _channels, currentProfile, _guestRepository, _invitationRepository, isLoading (+10 more)

### Community 26 - "invitation_card_generator.dart"
Cohesion: 0.11
Nodes (18): dart:ui, package:flutter/rendering.dart, package:path_provider/path_provider.dart, build, captureCard, _CardInfo, guestName, icon (+10 more)

### Community 27 - "guest_repository.dart"
Cohesion: 0.10
Nodes (19): ../models/guest.dart, ../models/guest_seat.dart, package:uuid/uuid.dart, assignSeat, _client, createGuest, deleteGuest, _generateQrToken (+11 more)

### Community 28 - "models_test.dart"
Cohesion: 0.08
Nodes (20): package:flutter_test/flutter_test.dart, package:weeding_app/app/core/theme/app_theme.dart, package:weeding_app/app/core/theme/wedding_palette.dart, package:weeding_app/app/core/utils/validators.dart, package:weeding_app/app/data/models/chair.dart, package:weeding_app/app/data/models/entrance_qr.dart, package:weeding_app/app/data/models/event_venue.dart, package:weeding_app/app/data/models/guest.dart (+12 more)

### Community 29 - "guests_page.dart"
Cohesion: 0.11
Nodes (18): ../../core/widgets/shared_components.dart, _AddGuestSheet, _avatarColor, build, _buildField, _buildFilterChips, controller, filters (+10 more)

### Community 30 - "video_recorder_page.dart"
Cohesion: 0.12
Nodes (15): dart:io, ImagePicker, package:image_picker/image_picker.dart, build, createState, _formatDuration, _getVideoDuration, initState (+7 more)

### Community 31 - "Widget?"
Cohesion: 0.32
Nodes (7): Offset, PageRouteBuilder, T, page, SlideFadeRoute, SlideUpRoute, Widget?

### Community 32 - "tables_controller.dart"
Cohesion: 0.12
Nodes (15): ../../data/models/chair.dart, ../../data/models/wedding_table.dart, ../../data/repositories/table_repository.dart, RxString, createTable, deleteTable, getChairsForTable, isLoading (+7 more)

### Community 33 - "invitation.dart"
Cohesion: 0.12
Nodes (16): chairId, copyWith, createdAt, deepLink, fromJson, guestId, id, Invitation (+8 more)

### Community 34 - "StatelessWidget"
Cohesion: 0.10
Nodes (20): PreferredSizeWidget, StatelessWidget, GradientCard, SectionHeader, StatusBadge, UserAvatar, WeddingAppBar, _MediaOptionCard (+12 more)

### Community 35 - "Win32Window"
Cohesion: 0.05
Nodes (57): PluginRegistry, RECT, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT (+49 more)

### Community 36 - "media_player_page.dart"
Cohesion: 0.04
Nodes (54): AudioPlayer?, package:just_audio/just_audio.dart, package:video_player/video_player.dart, Random, VideoPlayerController?, _audioPlayer, _barCount, _bars (+46 more)

### Community 37 - "tables_page.dart"
Cohesion: 0.13
Nodes (14): ../../core/widgets/animated_widgets.dart, ../../core/widgets/micro_interactions.dart, VoidCallback, build, _buildField, controller, _CreateTableSheet, _inputDecoration (+6 more)

### Community 38 - "event_venue.dart"
Cohesion: 0.06
Nodes (32): double?, addressLine, city, countryCode, endsAt, eventId, EventVenue, fromJson (+24 more)

### Community 39 - "wedding_header.dart"
Cohesion: 0.12
Nodes (15): IconData, List, micro_interactions.dart, ../theme/app_text_styles.dart, build, child, gradientColors, HeaderInfoBanner (+7 more)

### Community 40 - "auth_repository.dart"
Cohesion: 0.12
Nodes (15): ../models/profile.dart, Session? get, Stream, User? get, AuthRepository, authStateChanges, _client, createSaasWorkspace (+7 more)

### Community 41 - "guest-access/index.ts"
Cohesion: 0.19
Nodes (5): admin, admin, admin, corsHeaders, admin

### Community 42 - "invitations_controller.dart"
Cohesion: 0.15
Nodes (12): ../../data/models/guest.dart, ../../data/models/invitation.dart, ../../data/repositories/guest_repository.dart, ../../data/repositories/invitation_repository.dart, getGuestForInvitation, getInvitationForGuest, _guestRepository, _invitationRepository (+4 more)

### Community 43 - "venues_page.dart"
Cohesion: 0.09
Nodes (21): TextInputType?, build, _confirmDelete, controller, _EmptyVenues, icon, keyboardType, label (+13 more)

### Community 44 - "DESIGN.md"
Cohesion: 0.14
Nodes (13): Brand & Style, Buttons, Cards, Colors, Components, Elevation & Depth, Input Fields, Layout & Spacing (+5 more)

### Community 45 - "guest_link.dart"
Cohesion: 0.14
Nodes (13): copyWith, createdAt, fromJson, getInviteUrl, guestId, GuestLink, guestToken, id (+5 more)

### Community 46 - "chair.dart"
Cohesion: 0.15
Nodes (12): bool get, Chair, chairNumber, copyWith, createdAt, fromJson, guestId, guestName (+4 more)

### Community 47 - "package:get/get.dart"
Cohesion: 0.09
Nodes (23): Bindings, GetxController, guest_access_controller.dart, home_controller.dart, package:get/get.dart, venues_controller.dart, AppBinding, WeddingThemeController (+15 more)

### Community 48 - "guest-portal-web/manifest.json"
Cohesion: 0.17
Nodes (11): background_color, description, display, icons, lang, name, orientation, scope (+3 more)

### Community 49 - "guest_seat.dart"
Cohesion: 0.17
Nodes (11): DateTime, assignedAt, chairId, chairNumber, fromJson, guestId, GuestSeat, id (+3 more)

### Community 50 - "wedding_table.dart"
Cohesion: 0.17
Nodes (11): double get, assignedSeats, capacity, copyWith, createdAt, fromJson, id, label (+3 more)

### Community 51 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 52 - "table_repository.dart"
Cohesion: 0.17
Nodes (11): ../models/wedding_table.dart, _client, createTable, deleteTable, getAllTables, getAvailableChairsByTableId, getChairsByTableId, getTableById (+3 more)

### Community 53 - "wedding_settings_repository.dart"
Cohesion: 0.17
Nodes (11): brideName, _client, eventDate, fromJson, getSettings, groomName, location, title (+3 more)

### Community 54 - "wedding_theme_controller.dart"
Cohesion: 0.17
Nodes (11): ../../data/repositories/wedding_theme_repository.dart, package:flutter/foundation.dart, Rx, RxBool, isLoading, isSaving, loadForCurrentWedding, palette (+3 more)

### Community 55 - "register_page.dart"
Cohesion: 0.14
Nodes (13): AnimationController, auth_controller.dart, ../../core/utils/validators.dart, FormState, dependencies, AuthController, build, _buildField (+5 more)

### Community 56 - "app_pages.dart"
Cohesion: 0.08
Nodes (24): app_routes.dart, GetMiddleware, ../modules/auth/auth_binding.dart, ../modules/auth/login_page.dart, ../modules/guests/guest_detail_page.dart, ../modules/guests/guests_binding.dart, ../modules/invitations/entrance_qr_page.dart, ../modules/invitations/invitations_binding.dart (+16 more)

### Community 57 - "6. Plan d'Implementation"
Cohesion: 0.18
Nodes (11): 6. Plan d'Implementation, Phase 10. Qualite et livraison, Phase 1. Cadrage et initialisation, Phase 2. Base de donnees Supabase, Phase 3. Authentification et espace maries, Phase 4. Gestion des tables et chaises, Phase 5. Gestion des invites, Phase 6. Generation des invitations (+3 more)

### Community 58 - "profile.dart"
Cohesion: 0.18
Nodes (10): copyWith, createdAt, eventId, fromJson, fullName, id, phone, Profile (+2 more)

### Community 59 - "web/manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 60 - "guest_link_repository.dart"
Cohesion: 0.14
Nodes (13): dart:math, ../models/guest_link.dart, _client, createGuestLink, _fetchLinkByGuestId, _generateShortCode, getAllLinks, getLinkByGuestId (+5 more)

### Community 61 - "Application Mariage Entienne"
Cohesion: 0.20
Nodes (9): 10. Prompt Technique Pret a Reutiliser, 3. Proposition d'Architecture, 5. Structure Flutter Recommandee, 8. Risques Techniques a Anticiper, 9. Decisions Recommandees Avant Developpement, Application Mariage Entienne, Cote Flutter, Cote Supabase (+1 more)

### Community 62 - "Tables principales"
Cohesion: 0.20
Nodes (10): 4. Modele de Donnees Supabase Recommande, Buckets Storage, `chairs`, `guest_media`, `guest_seats`, `guests`, `invitations`, `profiles` (+2 more)

### Community 63 - "workspace_onboarding_controller.dart"
Cohesion: 0.12
Nodes (15): ../../data/repositories/auth_repository.dart, ../../routes/app_routes.dart, Rxn, brideNameController, createWorkspace, eventDate, eventTitleController, groomNameController (+7 more)

### Community 64 - "app_bottom_nav_bar.dart"
Cohesion: 0.25
Nodes (7): ../theme/app_colors.dart, ValueChanged, AppBottomNavBar, build, currentIndex, _icons, onTabSelected

### Community 65 - "secure_local_storage.dart"
Cohesion: 0.15
Nodes (12): dart:async, LocalStorage, package:shared_preferences/shared_preferences.dart, SharedPreferences?, accessToken, hasAccessToken, initialize, persistSession (+4 more)

### Community 66 - "invitation_repository.dart"
Cohesion: 0.22
Nodes (8): ../models/invitation.dart, _client, getAllInvitations, getInvitationByGuestId, getInvitationCount, getMediaCount, InvitationRepository, updateCardPaths

### Community 67 - "1. Prompt Produit Reorganise"
Cohesion: 0.22
Nodes (9): 1. Prompt Produit Reorganise, Back-office metier, Espace invite, Espace maries, Fonctionnalites minimales MVP, Objectif principal, Parcours attendu, Regle metier principale (+1 more)

### Community 68 - "venues_controller.dart"
Cohesion: 0.12
Nodes (16): ../../data/models/event_venue.dart, ../../data/repositories/event_venue_repository.dart, package:url_launcher/url_launcher.dart, RxList, deleteVenue, isLoading, isSaving, loadVenues (+8 more)

### Community 69 - "SupabaseClient"
Cohesion: 0.29
Nodes (6): ../../core/constants/supabase_config.dart, ../models/entrance_qr.dart, SupabaseClient, _client, EntranceRepository, getOrCreate

### Community 70 - "Déploiement mobile, portail invité et Supabase"
Cohesion: 0.29
Nodes (6): Architecture retenue, Déploiement mobile, portail invité et Supabase, Ordre de déploiement, QR commun à l’entrée de la salle, Validation média, Vérifications avant publication

### Community 71 - "chair_repository.dart"
Cohesion: 0.29
Nodes (6): ../models/chair.dart, ChairRepository, _client, getAvailableChairsByTableId, getChairById, getChairsByTableId

### Community 72 - "supabase_config.dart"
Cohesion: 0.29
Nodes (6): static const String, anonKey, eventId, guestPortalUrl, SupabaseConfig, url

### Community 73 - "validators.dart"
Cohesion: 0.29
Nodes (6): email, password, phone, positiveNumber, required, Validators

### Community 74 - "7. Sprint MVP Recommande"
Cohesion: 0.33
Nodes (6): 7. Sprint MVP Recommande, Sprint 1, Sprint 2, Sprint 3, Sprint 4, Sprint 5

### Community 75 - "2. Cadrage Fonctionnel"
Cohesion: 0.40
Nodes (5): 1. Marie / Administrateur, 2. Cadrage Fonctionnel, 2. Invite, Regles metier detaillees, Roles

### Community 76 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.18
Nodes (9): ../../core/theme/wedding_palette.dart, package:supabase_flutter/supabase_flutter.dart, package:weeding_app/app/modules/invitations/entrance_qr_page.dart, _client, _currentEventId, getPalette, updatePalette, WeddingThemeRepository (+1 more)

### Community 77 - "entrance_qr.dart"
Cohesion: 0.17
Nodes (11): checkInCount, code, createdAt, EntranceQr, eventId, fromJson, id, isActive (+3 more)

### Community 78 - "ADR-001 — Socle SaaS multi-tenant pour l'organisation de mariages"
Cohesion: 0.18
Nodes (10): ADR-001 — Socle SaaS multi-tenant pour l'organisation de mariages, Arbitrages acceptés, Conséquences, Contexte, Décision, Déclencheurs de réévaluation, Options considérées, Positives (+2 more)

### Community 79 - "../../core/theme/app_colors.dart"
Cohesion: 0.20
Nodes (9): ../auth/auth_controller.dart, ../../core/theme/app_colors.dart, ../../core/theme/app_text_styles.dart, build, child, _pickDate, _SectionCard, title (+1 more)

### Community 84 - "wedding_palette.dart"
Cohesion: 0.12
Nodes (16): @immutable, Color, int? get, accent, background, celestialRomance, colorFromHex, colorToHex (+8 more)

### Community 87 - "Feuille de route — SaaS d'organisation de mariages"
Cohesion: 0.25
Nodes (7): Critères de passage en production de la phase 1, Feuille de route — SaaS d'organisation de mariages, Phase 1 — Fondation commercialisable, Phase 2 — Organisation quotidienne, Phase 3 — Expérience invité, Phase 4 — Monétisation et supervision, Positionnement

### Community 92 - "event_venue_repository.dart"
Cohesion: 0.25
Nodes (7): ../models/event_venue.dart, _client, _currentEventId, delete, EventVenueRepository, getVenues, save

### Community 93 - "app_routes.dart"
Cohesion: 0.13
Nodes (14): AppRoutes, entranceQr, guestDetail, guests, home, invitations, login, onboarding (+6 more)

### Community 94 - "media_repository.dart"
Cohesion: 0.20
Nodes (10): @Deprecated, dart:typed_data, ../models/guest_media.dart, _client, getMediaByGuestId, getMediaDownloadUrl, getValidMediaByGuestId, MediaRepository (+2 more)

### Community 97 - "main.dart"
Cohesion: 0.17
Nodes (11): app/bindings/app_binding.dart, app/core/constants/supabase_config.dart, app/core/storage/secure_local_storage.dart, app/core/theme/app_theme.dart, app/core/theme/wedding_theme_controller.dart, app/routes/app_pages.dart, package:flutter_localizations/flutter_localizations.dart, build (+3 more)

### Community 98 - "package:flutter/material.dart"
Cohesion: 0.20
Nodes (8): package:flutter/material.dart, web_audio_recorder.dart, web_video_recorder.dart, buildWebAudioRecorderPage, buildWebVideoRecorderPage, buildWebAudioRecorderPage, buildWebVideoRecorderPage, minDurationSeconds

### Community 99 - "SingleTickerProviderStateMixin"
Cohesion: 0.29
Nodes (7): SingleTickerProviderStateMixin, ShimmerSkeleton, _ShimmerSkeletonState, TapScale, _TapScaleState, WebAudioRecorderPage, _WebAudioRecorderPageState

### Community 100 - "main_navigation_controller.dart"
Cohesion: 0.20
Nodes (9): RxInt, static const, currentIndex, guestsTab, homeTab, invitationsTab, selectTab, settingsTab (+1 more)

### Community 101 - "qr_code_page.dart"
Cohesion: 0.15
Nodes (12): ../../core/widgets/wedding_header.dart, ../../data/repositories/guest_link_repository.dart, invitations_controller.dart, package:flutter/services.dart, package:qr_flutter/qr_flutter.dart, package:share_plus/share_plus.dart, dependencies, InvitationsBinding (+4 more)

### Community 103 - "app_binding.dart"
Cohesion: 0.15
Nodes (11): ../modules/auth/auth_controller.dart, ../modules/guests/guests_controller.dart, ../modules/home/home_controller.dart, ../modules/invitations/invitations_controller.dart, ../modules/navigation/main_navigation_controller.dart, ../modules/tables/tables_controller.dart, tables_controller.dart, dependencies (+3 more)

### Community 104 - "GuestsController"
Cohesion: 0.40
Nodes (4): guests_controller.dart, dependencies, GuestsBinding, GuestsController

## Knowledge Gaps
- **1072 isolated node(s):** `name`, `short_name`, `description`, `start_url`, `scope` (+1067 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Guest` connect `table_detail_page.dart` to `guest_detail_page.dart`, `media_player_page.dart`, `invitations_page.dart`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Why does `GuestLink` connect `guest_link.dart` to `guest_detail_page.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `EventVenue` connect `event_venue.dart` to `venues_page.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **What connects `name`, `short_name`, `description` to the rest of the system?**
  _1072 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_colors.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.038461538461538464 - nodes in this community are weakly interconnected._
- **Should `GeneratedPluginRegistrant.swift` be split into smaller, more focused modules?**
  _Cohesion score 0.04846938775510204 - nodes in this community are weakly interconnected._
- **Should `app_text_styles.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06896551724137931 - nodes in this community are weakly interconnected._