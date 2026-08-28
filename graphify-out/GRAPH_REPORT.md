# Graph Report - MARIAGE ENTIENNE  (2026-08-28)

## Corpus Check
- 133 files · ~468,375 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1433 nodes · 1944 edges · 92 communities (83 shown, 9 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `cdf07c25`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app_colors.dart
- GeneratedPluginRegistrant.swift
- package:flutter/material.dart
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
- package:get/get.dart
- home_page.dart
- web_video_recorder.dart
- guest_detail_page.dart
- guests_controller.dart
- State
- audio_recorder_page.dart
- animated_widgets.dart
- web_audio_recorder.dart
- app_pages.dart
- login_page.dart
- home_controller.dart
- invitation_card_generator.dart
- guest_repository.dart
- models_test.dart
- guests_page.dart
- video_recorder_page.dart
- register_page.dart
- tables_controller.dart
- invitation.dart
- StatelessWidget
- FlutterWindow
- win32_window.cpp
- tables_page.dart
- guest_media.dart
- wedding_header.dart
- auth_repository.dart
- guest-access/index.ts
- invitations_controller.dart
- Win32Window
- DESIGN.md
- guest_link.dart
- chair.dart
- app_binding.dart
- guest-portal-web/manifest.json
- guest_seat.dart
- wedding_table.dart
- wWinMain
- table_repository.dart
- wedding_settings_repository.dart
- app_routes.dart
- media_repository.dart
- qr_code_page.dart
- 6. Plan d'Implementation
- profile.dart
- web/manifest.json
- guest_link_repository.dart
- Application Mariage Entienne
- Tables principales
- main_navigation_controller.dart
- app_bottom_nav_bar.dart
- MessageHandler
- invitation_repository.dart
- 1. Prompt Produit Reorganise
- page_transitions.dart
- SupabaseClient
- Déploiement mobile, portail invité et Supabase
- chair_repository.dart
- supabase_config.dart
- validators.dart
- 7. Sprint MVP Recommande
- 2. Cadrage Fonctionnel
- package:supabase_flutter/supabase_flutter.dart
- RegisterPlugins
- Point
- Size
- FlutterActivity
- weeding_app
- AGENTS.md
- sw.js
- WeddingAppBar
- LaunchImage.imageset/README.md
- @mail
- String?

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 24 edges
2. `MessageHandler` - 12 edges
3. `Application Mariage Entienne` - 11 edges
4. `6. Plan d'Implementation` - 11 edges
5. `AuthController` - 10 edges
6. `FlutterWindow` - 10 edges
7. `Create` - 10 edges
8. `WndProc` - 10 edges
9. `MessageHandler` - 9 edges
10. `Tables principales` - 8 edges

## Surprising Connections (you probably didn't know these)
- `OnCreate` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.h → windows/flutter/generated_plugin_registrant.cc
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  windows/runner/win32_window.cpp → windows/runner/win32_window.h
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  linux/runner/my_application.cc → linux/flutter/generated_plugin_registrant.cc
- `main()` --calls--> `my_application_new()`  [INFERRED]
  linux/runner/main.cc → linux/runner/my_application.cc

## Import Cycles
- None detected.

## Communities (92 total, 9 thin omitted)

### Community 0 - "app_colors.dart"
Cohesion: 0.04
Nodes (51): AppColors, background, cardDark, cardDarkText, dark, error, errorContainer, gold (+43 more)

### Community 1 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (32): Any, app_links, Cocoa, file_selector_macos, Flutter, flutter_sound, FlutterAppDelegate, FlutterImplicitEngineBridge (+24 more)

### Community 2 - "package:flutter/material.dart"
Cohesion: 0.05
Nodes (39): app/bindings/app_binding.dart, app_colors.dart, app/core/constants/supabase_config.dart, app/core/storage/secure_local_storage.dart, app/core/theme/app_theme.dart, app/routes/app_pages.dart, app_text_styles.dart, package:flutter/material.dart (+31 more)

### Community 3 - "settings_page.dart"
Cohesion: 0.05
Nodes (41): ../../core/theme/app_colors.dart, ../../core/widgets/app_bottom_nav_bar.dart, ../../data/repositories/wedding_settings_repository.dart, ../guests/guests_page.dart, ../home/home_page.dart, ../invitations/invitations_page.dart, main_navigation_controller.dart, package:intl/date_symbol_data_local.dart (+33 more)

### Community 4 - "entrance_qr_page.dart"
Cohesion: 0.05
Nodes (35): @visibleForTesting, ../../data/models/entrance_qr.dart, ../../data/repositories/entrance_repository.dart, RealtimeChannel?, checkInCount, code, createdAt, EntranceQr (+27 more)

### Community 5 - "auth_controller.dart"
Cohesion: 0.05
Nodes (35): dart:async, ../../data/repositories/auth_repository.dart, LocalStorage, package:shared_preferences/shared_preferences.dart, ../../routes/app_routes.dart, Rx, SharedPreferences?, StreamSubscription (+27 more)

### Community 6 - "table_detail_page.dart"
Cohesion: 0.06
Nodes (33): copyWith, createdAt, email, fromJson, fullName, Guest, id, phone (+25 more)

### Community 7 - "guest_access_page.dart"
Cohesion: 0.06
Nodes (33): audio_recorder_page.dart, ../../core/utils/invitation_card_generator.dart, GlobalKey, recorder_factory.dart, TickerProviderStateMixin, video_recorder_page.dart, build, _buildCardUnlocked (+25 more)

### Community 8 - "guest_access_controller.dart"
Cohesion: 0.07
Nodes (29): ../../data/repositories/media_repository.dart, _client, currentStep, errorMessage, goToMediaChoice, guest, GuestAccessStep, _guestRepo (+21 more)

### Community 9 - "invitations_page.dart"
Cohesion: 0.07
Nodes (27): Map, build, color, count, createState, guest, _guestRepo, _guests (+19 more)

### Community 10 - "micro_interactions.dart"
Cohesion: 0.07
Nodes (27): _anim, backgroundColor, borderRadius, boxShadow, build, child, createState, _ctrl (+19 more)

### Community 11 - "media-duration.ts"
Cohesion: 0.13
Nodes (16): admin, corsHeaders, inlineScriptValue(), renderSPA(), ascii(), detectMediaDuration(), ElementHeader, findTopLevel() (+8 more)

### Community 12 - "shared_components.dart"
Cohesion: 0.07
Nodes (26): EdgeInsets, Gradient?, Size get, actions, actionText, backgroundColor, bottom, build (+18 more)

### Community 13 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, MyApplicationClass (+14 more)

### Community 14 - "package:get/get.dart"
Cohesion: 0.10
Nodes (22): Bindings, GetxController, guest_access_controller.dart, home_controller.dart, invitations_controller.dart, package:get/get.dart, tables_controller.dart, AppBinding (+14 more)

### Community 15 - "home_page.dart"
Cohesion: 0.08
Nodes (25): CustomPainter, dart:math, ../navigation/main_navigation_controller.dart, build, _buildInvitationStatus, _buildKpiGrid, _buildQuickActions, _buildWeddingHeader (+17 more)

### Community 16 - "web_video_recorder.dart"
Cohesion: 0.08
Nodes (25): VideoElement?, build, _cameraReady, _chunks, createState, dispose, _elapsedSeconds, _formatDuration (+17 more)

### Community 17 - "guest_detail_page.dart"
Cohesion: 0.09
Nodes (24): ../../data/models/guest_link.dart, _AssignSheet, _AssignSheetState, availableChairs, build, _confirmDelete, controller, createState (+16 more)

### Community 18 - "guests_controller.dart"
Cohesion: 0.08
Nodes (24): ../../data/models/guest_seat.dart, assignSeatToGuest, confirmedCount, createGuest, deleteGuest, filterStatus, getAllTables, getAvailableChairs (+16 more)

### Community 19 - "State"
Cohesion: 0.14
Nodes (25): SingleTickerProviderStateMixin, State, StatefulWidget, FadeInSlide, _FadeInSlideState, ScaleIn, _ScaleInState, ShimmerBox (+17 more)

### Community 20 - "audio_recorder_page.dart"
Cohesion: 0.08
Nodes (23): FlutterSoundRecorder, package:flutter_sound/flutter_sound.dart, Timer?, build, createState, dispose, _elapsedSeconds, _formatDuration (+15 more)

### Community 21 - "animated_widgets.dart"
Cohesion: 0.09
Nodes (23): Animation, Duration, TextStyle?, _anim, AnimatedCounter, _AnimatedCounterState, borderRadius, build (+15 more)

### Community 22 - "web_audio_recorder.dart"
Cohesion: 0.09
Nodes (21): dart:html, MediaRecorder?, MediaStream?, build, _chunks, createState, dispose, _elapsedSeconds (+13 more)

### Community 23 - "app_pages.dart"
Cohesion: 0.10
Nodes (20): app_routes.dart, GetMiddleware, int? get, ../modules/auth/auth_binding.dart, ../modules/auth/login_page.dart, ../modules/guests/guest_detail_page.dart, ../modules/guests/guests_binding.dart, ../modules/invitations/entrance_qr_page.dart (+12 more)

### Community 24 - "login_page.dart"
Cohesion: 0.11
Nodes (18): TextEditingController, VoidCallback, _bgCtrl, build, _buildInput, _buildLabel, controller, createState (+10 more)

### Community 25 - "home_controller.dart"
Cohesion: 0.10
Nodes (19): ../auth/auth_controller.dart, ../../data/models/profile.dart, Profile? get, cardUnlocked, _channels, currentProfile, _guestRepository, _invitationRepository (+11 more)

### Community 26 - "invitation_card_generator.dart"
Cohesion: 0.11
Nodes (18): dart:ui, package:flutter/rendering.dart, package:path_provider/path_provider.dart, build, captureCard, _CardInfo, guestName, icon (+10 more)

### Community 27 - "guest_repository.dart"
Cohesion: 0.11
Nodes (18): ../models/guest.dart, ../models/guest_seat.dart, package:uuid/uuid.dart, assignSeat, _client, createGuest, deleteGuest, _generateQrToken (+10 more)

### Community 28 - "models_test.dart"
Cohesion: 0.11
Nodes (15): package:flutter_test/flutter_test.dart, package:weeding_app/app/core/utils/validators.dart, package:weeding_app/app/data/models/chair.dart, package:weeding_app/app/data/models/entrance_qr.dart, package:weeding_app/app/data/models/guest.dart, package:weeding_app/app/data/models/guest_media.dart, package:weeding_app/app/data/models/guest_seat.dart, package:weeding_app/app/data/models/invitation.dart (+7 more)

### Community 29 - "guests_page.dart"
Cohesion: 0.11
Nodes (17): ../../core/widgets/shared_components.dart, _avatarColor, build, _buildField, _buildFilterChips, controller, filters, guest (+9 more)

### Community 30 - "video_recorder_page.dart"
Cohesion: 0.12
Nodes (17): dart:io, ImagePicker, package:image_picker/image_picker.dart, build, createState, _formatDuration, _getVideoDuration, initState (+9 more)

### Community 31 - "register_page.dart"
Cohesion: 0.13
Nodes (15): AnimationController, auth_controller.dart, ../../core/utils/validators.dart, FormState, dependencies, AuthController, build, _buildField (+7 more)

### Community 32 - "tables_controller.dart"
Cohesion: 0.12
Nodes (16): ../../data/models/chair.dart, ../../data/models/wedding_table.dart, ../../data/repositories/table_repository.dart, RxList, RxString, createTable, deleteTable, getChairsForTable (+8 more)

### Community 33 - "invitation.dart"
Cohesion: 0.12
Nodes (16): chairId, copyWith, createdAt, deepLink, fromJson, guestId, id, Invitation (+8 more)

### Community 34 - "StatelessWidget"
Cohesion: 0.12
Nodes (16): StatelessWidget, GradientCard, _MediaOptionCard, _InfoRow, _AddGuestSheet, HomePage, _KpiCard, _QuickActionCard (+8 more)

### Community 35 - "FlutterWindow"
Cohesion: 0.13
Nodes (13): unique_ptr, DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM, FlutterWindow (+5 more)

### Community 36 - "win32_window.cpp"
Cohesion: 0.21
Nodes (12): wchar_t, Scale(), Create, Destroy, UpdateTheme, Win32Window::Win32Window(), WindowClassRegistrar, class_registered_ (+4 more)

### Community 37 - "tables_page.dart"
Cohesion: 0.13
Nodes (14): Color, ../../core/widgets/animated_widgets.dart, ../../core/widgets/micro_interactions.dart, build, _buildField, controller, _CreateTableSheet, _inputDecoration (+6 more)

### Community 38 - "guest_media.dart"
Cohesion: 0.13
Nodes (14): double?, clientDurationSeconds, clientValidated, fromJson, guestId, GuestMedia, id, isValid (+6 more)

### Community 39 - "wedding_header.dart"
Cohesion: 0.13
Nodes (14): IconData, List, micro_interactions.dart, build, child, gradientColors, HeaderInfoBanner, icon (+6 more)

### Community 40 - "auth_repository.dart"
Cohesion: 0.13
Nodes (14): ../models/profile.dart, Session? get, Stream, User? get, AuthRepository, authStateChanges, _client, currentSession (+6 more)

### Community 41 - "guest-access/index.ts"
Cohesion: 0.19
Nodes (5): admin, admin, admin, corsHeaders, admin

### Community 42 - "invitations_controller.dart"
Cohesion: 0.14
Nodes (13): ../../data/models/invitation.dart, ../../data/repositories/guest_repository.dart, ../../data/repositories/invitation_repository.dart, package:flutter/foundation.dart, RxBool, getGuestForInvitation, getInvitationForGuest, _guestRepository (+5 more)

### Community 43 - "Win32Window"
Cohesion: 0.20
Nodes (14): RECT, OnCreate, OnDestroy, HWND, Win32Window, child_content_, GetClientArea, OnCreate (+6 more)

### Community 44 - "DESIGN.md"
Cohesion: 0.14
Nodes (13): Brand & Style, Buttons, Cards, Colors, Components, Elevation & Depth, Input Fields, Layout & Spacing (+5 more)

### Community 45 - "guest_link.dart"
Cohesion: 0.14
Nodes (13): copyWith, createdAt, fromJson, getInviteUrl, guestId, GuestLink, guestToken, id (+5 more)

### Community 46 - "chair.dart"
Cohesion: 0.15
Nodes (12): bool get, Chair, chairNumber, copyWith, createdAt, fromJson, guestId, guestName (+4 more)

### Community 47 - "app_binding.dart"
Cohesion: 0.15
Nodes (11): guests_controller.dart, ../modules/auth/auth_controller.dart, ../modules/guests/guests_controller.dart, ../modules/home/home_controller.dart, ../modules/invitations/invitations_controller.dart, ../modules/navigation/main_navigation_controller.dart, ../modules/tables/tables_controller.dart, dependencies (+3 more)

### Community 48 - "guest-portal-web/manifest.json"
Cohesion: 0.17
Nodes (11): background_color, description, display, icons, lang, name, orientation, scope (+3 more)

### Community 49 - "guest_seat.dart"
Cohesion: 0.17
Nodes (11): DateTime?, assignedAt, chairId, chairNumber, fromJson, guestId, GuestSeat, id (+3 more)

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

### Community 54 - "app_routes.dart"
Cohesion: 0.17
Nodes (11): AppRoutes, entranceQr, guestDetail, guests, home, invitations, login, qrCode (+3 more)

### Community 55 - "media_repository.dart"
Cohesion: 0.20
Nodes (10): @Deprecated, dart:typed_data, ../models/guest_media.dart, _client, getMediaByGuestId, getMediaDownloadUrl, getValidMediaByGuestId, MediaRepository (+2 more)

### Community 56 - "qr_code_page.dart"
Cohesion: 0.18
Nodes (10): ../../core/theme/app_text_styles.dart, ../../core/widgets/wedding_header.dart, ../../data/models/guest.dart, ../../data/repositories/guest_link_repository.dart, package:flutter/services.dart, package:qr_flutter/qr_flutter.dart, package:share_plus/share_plus.dart, build (+2 more)

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
Cohesion: 0.20
Nodes (9): ../models/guest_link.dart, _client, createGuestLink, getAllLinks, getLinkByGuestId, getLinkByShortCode, getLinkStats, GuestLinkRepository (+1 more)

### Community 61 - "Application Mariage Entienne"
Cohesion: 0.20
Nodes (9): 10. Prompt Technique Pret a Reutiliser, 3. Proposition d'Architecture, 5. Structure Flutter Recommandee, 8. Risques Techniques a Anticiper, 9. Decisions Recommandees Avant Developpement, Application Mariage Entienne, Cote Flutter, Cote Supabase (+1 more)

### Community 62 - "Tables principales"
Cohesion: 0.20
Nodes (10): 4. Modele de Donnees Supabase Recommande, Buckets Storage, `chairs`, `guest_media`, `guest_seats`, `guests`, `invitations`, `profiles` (+2 more)

### Community 63 - "main_navigation_controller.dart"
Cohesion: 0.20
Nodes (9): RxInt, static const, currentIndex, guestsTab, homeTab, invitationsTab, selectTab, settingsTab (+1 more)

### Community 64 - "app_bottom_nav_bar.dart"
Cohesion: 0.20
Nodes (9): ../theme/app_colors.dart, ../theme/app_text_styles.dart, ValueChanged, AppBottomNavBar, build, currentIndex, _icons, _labels (+1 more)

### Community 65 - "MessageHandler"
Cohesion: 0.36
Nodes (10): HWND, LPARAM, LRESULT, UINT, WPARAM, EnableFullDpiSupportIfAvailable(), GetHandle, GetThisFromHandle (+2 more)

### Community 66 - "invitation_repository.dart"
Cohesion: 0.22
Nodes (8): ../models/invitation.dart, _client, getAllInvitations, getInvitationByGuestId, getInvitationCount, getMediaCount, InvitationRepository, updateCardPaths

### Community 67 - "1. Prompt Produit Reorganise"
Cohesion: 0.22
Nodes (9): 1. Prompt Produit Reorganise, Back-office metier, Espace invite, Espace maries, Fonctionnalites minimales MVP, Objectif principal, Parcours attendu, Regle metier principale (+1 more)

### Community 68 - "page_transitions.dart"
Cohesion: 0.32
Nodes (7): Offset, PageRouteBuilder, T, page, SlideFadeRoute, SlideUpRoute, Widget?

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
Cohesion: 0.50
Nodes (3): package:supabase_flutter/supabase_flutter.dart, package:weeding_app/app/modules/invitations/entrance_qr_page.dart, main

### Community 78 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 79 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

## Knowledge Gaps
- **868 isolated node(s):** `name`, `short_name`, `description`, `start_url`, `scope` (+863 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Guest` connect `table_detail_page.dart` to `guest_detail_page.dart`, `invitations_page.dart`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **Why does `WeddingTable` connect `wedding_table.dart` to `guest_detail_page.dart`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Why does `GuestLink` connect `guest_link.dart` to `guest_detail_page.dart`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **What connects `name`, `short_name`, `description` to the rest of the system?**
  _868 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_colors.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.038461538461538464 - nodes in this community are weakly interconnected._
- **Should `GeneratedPluginRegistrant.swift` be split into smaller, more focused modules?**
  _Cohesion score 0.05217391304347826 - nodes in this community are weakly interconnected._
- **Should `package:flutter/material.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.046511627906976744 - nodes in this community are weakly interconnected._