# Graph Report - MARIAGE ENTIENNE  (2026-09-03)

## Corpus Check
- 198 files · ~522,821 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2286 nodes · 3138 edges · 145 communities (127 shown, 18 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `d5c61942`
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
- admin_repository.dart
- tables_controller.dart
- invitation.dart
- package:flutter_test/flutter_test.dart
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
- DateTime
- web/manifest.json
- guest_link_repository.dart
- Application Mariage Entienne
- Tables principales
- workspace_onboarding_controller.dart
- static const
- secure_local_storage.dart
- invitation_repository.dart
- 1. Prompt Produit Reorganise
- venues_controller.dart
- package:supabase_flutter/supabase_flutter.dart
- Déploiement mobile, portail invité et Supabase
- chair_repository.dart
- platform_admin.dart
- validators.dart
- 7. Sprint MVP Recommande
- 2. Cadrage Fonctionnel
- wedding_theme_repository.dart
- entrance_qr.dart
- ADR-001 — Socle SaaS multi-tenant pour l'organisation de mariages
- package:flutter/material.dart
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
- recorder_factory_web.dart
- subscription.dart
- main_navigation_controller.dart
- qr_code_page.dart
- StatelessWidget
- app_binding.dart
- invitation_sender.dart
- plans_page.dart
- whatsapp_helper.dart
- admin_controller.dart
- welcome_page.dart
- guest.dart
- subscription_controller.dart
- guest_media.dart
- home_page_layout_test.dart
- Color
- quota_error.dart
- Offre commerciale
- ../../core/theme/app_colors.dart
- SupabaseClient
- app_theme.dart
- FlutterMacOS
- ios/RunnerTests/RunnerTests.swift
- app_colors_palette_test.dart
- AppDelegate
- Console d'exploitation
- AppDelegate
- RegisterGeneratedPlugins
- TablesController
- ../theme/app_colors.dart
- subscription_banner.dart
- supabase_config.dart
- venue_map_launcher.dart
- GuestsController
- _AssignGuestSheet
- _GuestDetailSheet
- _MoveGuestSheet
- _TableChairsSection
- subscription_test.dart
- _showGuestDetails
- workspace_onboarding_binding.dart
- wedding_palette_test.dart
- quota_error_test.dart
- event_venue_test.dart
- main_navigation_controller_test.dart
- SettingsPage
- _StorageInfoBody

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 24 edges
2. `AuthController` - 15 edges
3. `MessageHandler` - 12 edges
4. `Application Mariage Entienne` - 11 edges
5. `6. Plan d'Implementation` - 11 edges
6. `FlutterWindow` - 10 edges
7. `Create` - 10 edges
8. `WndProc` - 10 edges
9. `MessageHandler` - 9 edges
10. `GuestRepository` - 8 edges

## Surprising Connections (you probably didn't know these)
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  weeding_app/windows/runner/main.cpp → weeding_app/windows/runner/utils.cpp
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  weeding_app/windows/runner/win32_window.cpp → weeding_app/windows/runner/win32_window.h
- `_FakeAuthController` --inherits--> `AuthController`  [EXTRACTED]
  weeding_app/test/home_page_layout_test.dart → weeding_app/lib/app/modules/auth/auth_controller.dart
- `_FakeHomeController` --inherits--> `HomeController`  [EXTRACTED]
  weeding_app/test/home_page_layout_test.dart → weeding_app/lib/app/modules/home/home_controller.dart
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  weeding_app/linux/runner/my_application.cc → weeding_app/linux/flutter/generated_plugin_registrant.cc

## Import Cycles
- None detected.

## Communities (145 total, 18 thin omitted)

### Community 0 - "app_colors.dart"
Cohesion: 0.03
Nodes (62): static Color, AppColors, applyPalette, background, cardDark, cardDarkText, _contrast, dark (+54 more)

### Community 1 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.17
Nodes (11): app_links, audio_session, file_selector_macos, flutter_secure_storage_macos, flutter_sound, Foundation, just_audio, share_plus (+3 more)

### Community 2 - "app_text_styles.dart"
Cohesion: 0.07
Nodes (28): package:google_fonts/google_fonts.dart, static String, static TextStyle, applyPalette, AppTextStyles, _body, _bodyFamily, bodyLg (+20 more)

### Community 3 - "settings_page.dart"
Cohesion: 0.04
Nodes (45): package:intl/date_symbol_data_local.dart, package:intl/intl.dart, ScrollController, static const int, build, _buildTextField, _buildWeddingInfoCard, colors (+37 more)

### Community 4 - "entrance_qr_page.dart"
Cohesion: 0.08
Nodes (24): @visibleForTesting, ../../data/models/entrance_qr.dart, ../../data/repositories/entrance_repository.dart, RealtimeChannel?, build, _buildActionChip, _buildActions, _buildCodeChip (+16 more)

### Community 5 - "auth_controller.dart"
Cohesion: 0.07
Nodes (29): ../admin/admin_controller.dart, ../../core/theme/wedding_theme_controller.dart, ../guests/guests_controller.dart, ../home/home_controller.dart, ../invitations/invitations_controller.dart, StreamSubscription, ../tables/tables_controller.dart, authenticatedEntryRoute (+21 more)

### Community 6 - "table_detail_page.dart"
Cohesion: 0.04
Nodes (50): Future, _assign, _availableChairs, build, _buildChairsError, _buildChairsGrid, _buildDetailRow, _buildEmptyChairs (+42 more)

### Community 7 - "guest_access_page.dart"
Cohesion: 0.06
Nodes (33): audio_recorder_page.dart, ../../core/utils/invitation_card_generator.dart, GlobalKey, guest_venues_sheet.dart, recorder_factory.dart, video_recorder_page.dart, build, _buildCardUnlocked (+25 more)

### Community 8 - "guest_access_controller.dart"
Cohesion: 0.06
Nodes (34): _client, currentStep, errorMessage, goToMediaChoice, guest, GuestAccessStep, _guestRepo, guestSeat (+26 more)

### Community 9 - "invitations_page.dart"
Cohesion: 0.06
Nodes (35): ../../data/models/guest_media.dart, ../../data/repositories/media_repository.dart, media_player_page.dart, build, color, count, createState, guest (+27 more)

### Community 10 - "micro_interactions.dart"
Cohesion: 0.06
Nodes (36): _anim, backgroundColor, borderRadius, boxShadow, build, child, createState, _ctrl (+28 more)

### Community 11 - "media-duration.ts"
Cohesion: 0.11
Nodes (17): admin, corsHeaders, GuestTokenRecord, inlineScriptValue(), renderSPA(), ascii(), detectMediaDuration(), ElementHeader (+9 more)

### Community 12 - "shared_components.dart"
Cohesion: 0.07
Nodes (29): EdgeInsets, Gradient?, PreferredSizeWidget, Size get, actions, actionText, backgroundColor, bottom (+21 more)

### Community 13 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, MyApplicationClass (+14 more)

### Community 14 - "wedding_theme_page.dart"
Cohesion: 0.04
Nodes (48): _accentController, _backgroundController, bodyFont, build, _CardInfoColumn, _CardPreview, color, _ColorSlot (+40 more)

### Community 15 - "home_page.dart"
Cohesion: 0.08
Nodes (23): ../navigation/main_navigation_controller.dart, ../subscription/subscription_banner.dart, build, _buildBody, _buildInvitationStatus, _buildKpiRow, _buildQuickActions, _buildWeddingHeader (+15 more)

### Community 16 - "web_video_recorder.dart"
Cohesion: 0.08
Nodes (25): VideoElement?, build, _cameraReady, _chunks, createState, dispose, _elapsedSeconds, _formatDuration (+17 more)

### Community 17 - "guest_detail_page.dart"
Cohesion: 0.05
Nodes (41): ../../data/models/guest_link.dart, _AssignSheet, _AssignSheetState, availableChairs, build, _confirmCancellation, _confirmDelete, controller (+33 more)

### Community 18 - "guests_controller.dart"
Cohesion: 0.07
Nodes (28): ../../data/models/guest_seat.dart, assignSeatToGuest, cancelledCount, confirmedCount, createGuest, declinedCount, deleteGuest, filterStatus (+20 more)

### Community 19 - "State"
Cohesion: 0.11
Nodes (27): _PasswordField, SingleTickerProviderStateMixin, State, StatefulWidget, TickerProviderStateMixin, LoginPage, _LoginPageState, _PasswordField (+19 more)

### Community 20 - "audio_recorder_page.dart"
Cohesion: 0.08
Nodes (24): FlutterSoundRecorder, package:flutter_sound/flutter_sound.dart, AudioRecorderPage, _AudioRecorderPageState, build, createState, dispose, _elapsedSeconds (+16 more)

### Community 21 - "animated_widgets.dart"
Cohesion: 0.07
Nodes (32): Animation, Duration, Offset, TextStyle?, _anim, AnimatedCounter, _AnimatedCounterState, borderRadius (+24 more)

### Community 22 - "web_audio_recorder.dart"
Cohesion: 0.09
Nodes (22): dart:html, MediaRecorder?, MediaStream?, Timer?, build, _chunks, createState, dispose (+14 more)

### Community 23 - "main_shell_page.dart"
Cohesion: 0.13
Nodes (15): ../../core/widgets/app_bottom_nav_bar.dart, ../guests/guests_page.dart, ../home/home_page.dart, ../invitations/invitations_page.dart, main_navigation_controller.dart, ../settings/settings_page.dart, ../tables/tables_page.dart, build (+7 more)

### Community 24 - "login_page.dart"
Cohesion: 0.11
Nodes (17): AnimationController, ../../core/utils/validators.dart, VoidCallback, _bgCtrl, build, _buildInput, _buildLabel, controller (+9 more)

### Community 25 - "home_controller.dart"
Cohesion: 0.10
Nodes (19): ../../data/models/profile.dart, ../../data/repositories/table_repository.dart, Profile? get, cardUnlocked, _channels, currentProfile, _guestRepository, _invitationRepository (+11 more)

### Community 26 - "invitation_card_generator.dart"
Cohesion: 0.10
Nodes (19): dart:ui, package:flutter/rendering.dart, package:path_provider/path_provider.dart, build, captureCard, _CardInfo, guestName, icon (+11 more)

### Community 27 - "guest_repository.dart"
Cohesion: 0.10
Nodes (19): ../models/guest.dart, ../models/guest_seat.dart, package:uuid/uuid.dart, assignSeat, _client, createGuest, deleteGuest, _generateQrToken (+11 more)

### Community 28 - "models_test.dart"
Cohesion: 0.20
Nodes (9): package:weeding_app/app/data/models/chair.dart, package:weeding_app/app/data/models/entrance_qr.dart, package:weeding_app/app/data/models/guest.dart, package:weeding_app/app/data/models/guest_media.dart, package:weeding_app/app/data/models/guest_seat.dart, package:weeding_app/app/data/models/invitation.dart, package:weeding_app/app/data/models/profile.dart, package:weeding_app/app/data/models/wedding_table.dart (+1 more)

### Community 29 - "guests_page.dart"
Cohesion: 0.09
Nodes (22): ../../core/utils/invitation_sender.dart, ../../core/widgets/shared_components.dart, _avatarColor, build, _buildField, _buildFilterChips, controller, createState (+14 more)

### Community 30 - "video_recorder_page.dart"
Cohesion: 0.11
Nodes (18): dart:async, dart:io, ImagePicker, package:image_picker/image_picker.dart, build, createState, _formatDuration, _getVideoDuration (+10 more)

### Community 31 - "admin_repository.dart"
Cohesion: 0.12
Nodes (16): ../models/platform_admin.dart, PageRouteBuilder, T, SlideFadeRoute, SlideUpRoute, AdminRepository, _client, grantInvitations (+8 more)

### Community 32 - "tables_controller.dart"
Cohesion: 0.10
Nodes (19): ../../data/models/chair.dart, ../../data/models/wedding_table.dart, assignGuestToChair, createTable, deleteChair, deleteTable, getChairsForTable, getUnassignedGuests (+11 more)

### Community 33 - "invitation.dart"
Cohesion: 0.12
Nodes (16): chairId, copyWith, createdAt, deepLink, fromJson, guestId, id, Invitation (+8 more)

### Community 34 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.22
Nodes (6): package:flutter_test/flutter_test.dart, package:weeding_app/app/core/utils/validators.dart, package:weeding_app/app/data/models/platform_admin.dart, main, main, main

### Community 35 - "Win32Window"
Cohesion: 0.05
Nodes (57): PluginRegistry, RECT, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT (+49 more)

### Community 36 - "media_player_page.dart"
Cohesion: 0.04
Nodes (56): AudioPlayer?, package:just_audio/just_audio.dart, package:video_player/video_player.dart, Random, VideoPlayerController?, _audioPlayer, _AudioWaveform, _barCount (+48 more)

### Community 37 - "tables_page.dart"
Cohesion: 0.11
Nodes (17): FormState, build, _buildField, _capacityController, controller, createState, dispose, _formKey (+9 more)

### Community 38 - "event_venue.dart"
Cohesion: 0.11
Nodes (18): addressLine, city, countryCode, endsAt, eventId, EventVenue, fromJson, id (+10 more)

### Community 39 - "wedding_header.dart"
Cohesion: 0.14
Nodes (13): List, micro_interactions.dart, build, child, gradientColors, HeaderInfoBanner, icon, onBackPressed (+5 more)

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
Cohesion: 0.10
Nodes (19): TextEditingController, TextInputType?, build, _confirmDelete, controller, _EmptyVenues, icon, keyboardType (+11 more)

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
Cohesion: 0.11
Nodes (17): auth_controller.dart, Bindings, guest_access_controller.dart, home_controller.dart, package:get/get.dart, venues_controller.dart, AppBinding, AuthBinding (+9 more)

### Community 48 - "guest-portal-web/manifest.json"
Cohesion: 0.17
Nodes (11): background_color, description, display, icons, lang, name, orientation, scope (+3 more)

### Community 49 - "guest_seat.dart"
Cohesion: 0.18
Nodes (10): assignedAt, chairId, chairNumber, fromJson, guestId, GuestSeat, id, tableId (+2 more)

### Community 50 - "wedding_table.dart"
Cohesion: 0.17
Nodes (11): double get, assignedSeats, capacity, copyWith, createdAt, fromJson, id, label (+3 more)

### Community 51 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 52 - "table_repository.dart"
Cohesion: 0.13
Nodes (14): ../models/wedding_table.dart, _client, createTable, deleteChair, deleteTable, ensureChairsForTable, getAllTables, getAssignedGuestIds (+6 more)

### Community 53 - "wedding_settings_repository.dart"
Cohesion: 0.15
Nodes (12): brideName, _client, eventDate, fromJson, getSettings, groomName, location, rsvpDeadline (+4 more)

### Community 54 - "wedding_theme_controller.dart"
Cohesion: 0.15
Nodes (12): ../../data/repositories/wedding_theme_repository.dart, Rx, RxBool, _apply, isLoading, isSaving, loadForCurrentWedding, onInit (+4 more)

### Community 55 - "register_page.dart"
Cohesion: 0.10
Nodes (20): FocusNode?, build, _buildField, controller, createState, _ctrl, dispose, _emailFocus (+12 more)

### Community 56 - "app_pages.dart"
Cohesion: 0.07
Nodes (30): app_routes.dart, GetMiddleware, ../modules/admin/admin_console_page.dart, ../modules/auth/auth_binding.dart, ../modules/auth/login_page.dart, ../modules/auth/register_page.dart, ../modules/guests/guest_detail_page.dart, ../modules/guests/guests_binding.dart (+22 more)

### Community 57 - "6. Plan d'Implementation"
Cohesion: 0.18
Nodes (11): 6. Plan d'Implementation, Phase 10. Qualite et livraison, Phase 1. Cadrage et initialisation, Phase 2. Base de donnees Supabase, Phase 3. Authentification et espace maries, Phase 4. Gestion des tables et chaises, Phase 5. Gestion des invites, Phase 6. Generation des invitations (+3 more)

### Community 58 - "DateTime"
Cohesion: 0.17
Nodes (11): DateTime, copyWith, createdAt, eventId, fromJson, fullName, id, phone (+3 more)

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
Cohesion: 0.13
Nodes (14): ../auth/auth_controller.dart, ../../data/repositories/auth_repository.dart, brideNameController, createWorkspace, eventDate, eventTitleController, groomNameController, isLoading (+6 more)

### Community 64 - "static const"
Cohesion: 0.25
Nodes (7): static const, ValueChanged, AppBottomNavBar, build, currentIndex, _icons, onTabSelected

### Community 65 - "secure_local_storage.dart"
Cohesion: 0.14
Nodes (13): LocalStorage, package:flutter/foundation.dart, package:flutter_secure_storage/flutter_secure_storage.dart, SharedPreferences?, accessToken, hasAccessToken, initialize, persistSession (+5 more)

### Community 66 - "invitation_repository.dart"
Cohesion: 0.20
Nodes (9): ../models/invitation.dart, _client, getAllInvitations, getInvitationByGuestId, getInvitationCount, getMediaCount, InvitationRepository, recordDelivery (+1 more)

### Community 67 - "1. Prompt Produit Reorganise"
Cohesion: 0.22
Nodes (9): 1. Prompt Produit Reorganise, Back-office metier, Espace invite, Espace maries, Fonctionnalites minimales MVP, Objectif principal, Parcours attendu, Regle metier principale (+1 more)

### Community 68 - "venues_controller.dart"
Cohesion: 0.13
Nodes (14): ../../core/utils/venue_map_launcher.dart, ../../data/repositories/event_venue_repository.dart, RxList, deleteVenue, isLoading, isSaving, loadVenues, _nullIfEmpty (+6 more)

### Community 69 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.20
Nodes (8): ../../core/constants/supabase_config.dart, ../models/entrance_qr.dart, package:supabase_flutter/supabase_flutter.dart, package:weeding_app/app/modules/invitations/entrance_qr_page.dart, _client, EntranceRepository, getOrCreate, main

### Community 70 - "Déploiement mobile, portail invité et Supabase"
Cohesion: 0.29
Nodes (6): Architecture retenue, Déploiement mobile, portail invité et Supabase, Ordre de déploiement, QR commun à l’entrée de la salle, Validation média, Vérifications avant publication

### Community 71 - "chair_repository.dart"
Cohesion: 0.29
Nodes (6): ../models/chair.dart, ChairRepository, _client, getAvailableChairsByTableId, getChairById, getChairsByTableId

### Community 72 - "platform_admin.dart"
Cohesion: 0.05
Nodes (40): action, actorEmail, AdminAccount, AdminAction, AdminEvent, AdminMembership, AdminOrganization, createdAt (+32 more)

### Community 73 - "validators.dart"
Cohesion: 0.22
Nodes (8): email, _emailFormat, emailOptional, password, phone, positiveNumber, required, Validators

### Community 74 - "7. Sprint MVP Recommande"
Cohesion: 0.33
Nodes (6): 7. Sprint MVP Recommande, Sprint 1, Sprint 2, Sprint 3, Sprint 4, Sprint 5

### Community 75 - "2. Cadrage Fonctionnel"
Cohesion: 0.40
Nodes (5): 1. Marie / Administrateur, 2. Cadrage Fonctionnel, 2. Invite, Regles metier detaillees, Roles

### Community 76 - "wedding_theme_repository.dart"
Cohesion: 0.29
Nodes (6): ../../core/theme/wedding_palette.dart, _client, _currentEventId, getPalette, updatePalette, WeddingThemeRepository

### Community 77 - "entrance_qr.dart"
Cohesion: 0.17
Nodes (11): checkInCount, code, createdAt, EntranceQr, eventId, fromJson, id, isActive (+3 more)

### Community 78 - "ADR-001 — Socle SaaS multi-tenant pour l'organisation de mariages"
Cohesion: 0.18
Nodes (10): ADR-001 — Socle SaaS multi-tenant pour l'organisation de mariages, Arbitrages acceptés, Conséquences, Contexte, Décision, Déclencheurs de réévaluation, Options considérées, Positives (+2 more)

### Community 79 - "package:flutter/material.dart"
Cohesion: 0.10
Nodes (19): ../../core/theme/app_text_styles.dart, ../../core/widgets/micro_interactions.dart, ../../core/widgets/wedding_rings_icon.dart, package:flutter/material.dart, buildWebAudioRecorderPage, buildWebVideoRecorderPage, build, createState (+11 more)

### Community 84 - "wedding_palette.dart"
Cohesion: 0.08
Nodes (25): @immutable, int? get, accent, background, body, bodyFont, celestialRomance, colorFromHex (+17 more)

### Community 87 - "Feuille de route — SaaS d'organisation de mariages"
Cohesion: 0.25
Nodes (7): Critères de passage en production de la phase 1, Feuille de route — SaaS d'organisation de mariages, Phase 1 — Fondation commercialisable, Phase 2 — Organisation quotidienne, Phase 3 — Expérience invité, Phase 4 — Monétisation et supervision, Positionnement

### Community 92 - "event_venue_repository.dart"
Cohesion: 0.22
Nodes (8): ../models/event_venue.dart, _client, _currentEventId, delete, EventVenueRepository, getGuestPortalVenues, getVenues, save

### Community 93 - "app_routes.dart"
Cohesion: 0.10
Nodes (20): admin, AppRoutes, entranceQr, guestDetail, guests, home, invitations, login (+12 more)

### Community 94 - "media_repository.dart"
Cohesion: 0.20
Nodes (10): @Deprecated, dart:typed_data, ../models/guest_media.dart, _client, getMediaByGuestId, getMediaDownloadUrl, getValidMediaByGuestId, MediaRepository (+2 more)

### Community 97 - "main.dart"
Cohesion: 0.15
Nodes (12): app/bindings/app_binding.dart, app/core/constants/supabase_config.dart, app/core/storage/secure_local_storage.dart, app/core/theme/app_theme.dart, app/core/theme/wedding_theme_controller.dart, app/routes/app_pages.dart, package:flutter_localizations/flutter_localizations.dart, build (+4 more)

### Community 98 - "recorder_factory_web.dart"
Cohesion: 0.33
Nodes (5): web_audio_recorder.dart, web_video_recorder.dart, buildWebAudioRecorderPage, buildWebVideoRecorderPage, minDurationSeconds

### Community 99 - "subscription.dart"
Cohesion: 0.06
Nodes (35): Map, amountXof, billingInterval, billingLabel, collaborators, currentPeriodEnd, description, events (+27 more)

### Community 100 - "main_navigation_controller.dart"
Cohesion: 0.20
Nodes (9): RxInt, currentIndex, guestsTab, homeTab, invitationsTab, MainNavigationController, selectTab, settingsTab (+1 more)

### Community 101 - "qr_code_page.dart"
Cohesion: 0.17
Nodes (11): ../../core/utils/quota_error.dart, ../../core/widgets/wedding_header.dart, ../../data/repositories/guest_link_repository.dart, package:flutter/services.dart, package:qr_flutter/qr_flutter.dart, package:share_plus/share_plus.dart, ../subscription/subscription_controller.dart, build (+3 more)

### Community 102 - "StatelessWidget"
Cohesion: 0.07
Nodes (32): admin_controller.dart, StatelessWidget, _AccountsTab, actions, AdminConsolePage, _Badge, build, _Card (+24 more)

### Community 103 - "app_binding.dart"
Cohesion: 0.12
Nodes (17): GetxController, invitations_controller.dart, ../modules/admin/admin_controller.dart, ../modules/auth/auth_controller.dart, ../modules/guests/guests_controller.dart, ../modules/home/home_controller.dart, ../modules/invitations/invitations_controller.dart, ../modules/navigation/main_navigation_controller.dart (+9 more)

### Community 104 - "invitation_sender.dart"
Cohesion: 0.05
Nodes (39): aborted, awaiting, build, _BulkRecapSheet, _BulkSendStepSheet, _BulkSendStepSheetState, _BulkStepResult, _ChannelTile (+31 more)

### Community 105 - "plans_page.dart"
Cohesion: 0.15
Nodes (12): SubscriptionPlan, build, isCurrent, label, plan, _PlanCard, _PlanLine, PlansPage (+4 more)

### Community 106 - "whatsapp_helper.dart"
Cohesion: 0.07
Nodes (27): ../constants/supabase_config.dart, ../../data/repositories/wedding_settings_repository.dart, return, bride, buffer, _buildInvitationMessage, couple, date (+19 more)

### Community 107 - "admin_controller.dart"
Cohesion: 0.09
Nodes (21): ../../data/models/platform_admin.dart, ../../data/repositories/admin_repository.dart, RxString, accounts, actions, availablePlans, errorMessage, events (+13 more)

### Community 108 - "welcome_page.dart"
Cohesion: 0.18
Nodes (10): ../../core/widgets/animated_widgets.dart, IconData, build, delayMs, detail, icon, _PriceAnchor, title (+2 more)

### Community 109 - "guest.dart"
Cohesion: 0.12
Nodes (15): copyWith, createdAt, email, fromJson, fullName, Guest, hasRsvpResponded, id (+7 more)

### Community 110 - "subscription_controller.dart"
Cohesion: 0.13
Nodes (14): ../../data/repositories/subscription_repository.dart, Rxn, SubscriptionOverview, clear, currentPlanId, isLoading, isLoadingPlans, load (+6 more)

### Community 111 - "guest_media.dart"
Cohesion: 0.13
Nodes (14): double?, clientDurationSeconds, clientValidated, fromJson, guestId, GuestMedia, id, isValid (+6 more)

### Community 112 - "home_page_layout_test.dart"
Cohesion: 0.14
Nodes (15): package:shared_preferences/shared_preferences.dart, package:weeding_app/app/modules/auth/auth_controller.dart, package:weeding_app/app/modules/home/home_controller.dart, package:weeding_app/app/modules/home/home_page.dart, package:weeding_app/app/modules/subscription/subscription_controller.dart, ScrollableState, AuthController, HomeController (+7 more)

### Community 113 - "Color"
Cohesion: 0.17
Nodes (11): Color, CustomPainter, build, color, paint, shouldRepaint, size, strokeWidth (+3 more)

### Community 114 - "quota_error.dart"
Cohesion: 0.17
Nodes (11): String? get, ../theme/app_text_styles.dart, actionLabel, isSubscriptionLapsed, kind, message, QuotaRefusal, runWithQuotaGuard (+3 more)

### Community 115 - "Offre commerciale"
Cohesion: 0.18
Nodes (10): A. Packs mariage — paiement unique, B. Abonnements professionnels, Ce qui empêche de remettre le compteur à zéro, L'ancrage face au carton imprimé, Le moment du paiement, Le paiement mobile, Les trois leviers de conversion, Offre commerciale (+2 more)

### Community 116 - "../../core/theme/app_colors.dart"
Cohesion: 0.22
Nodes (8): ../../core/theme/app_colors.dart, ../../core/utils/venue_presentation.dart, build, _GuestVenueCard, onMap, showGuestVenuesSheet, showModalBottomSheet, venue

### Community 117 - "SupabaseClient"
Cohesion: 0.29
Nodes (6): ../models/subscription.dart, SupabaseClient, _client, getOverview, getPlans, SubscriptionRepository

### Community 118 - "app_theme.dart"
Cohesion: 0.22
Nodes (8): app_colors.dart, app_text_styles.dart, static ThemeData get, wedding_palette.dart, AppTheme, _foregroundFor, lightTheme, lightThemeFor

### Community 119 - "FlutterMacOS"
Cohesion: 0.28
Nodes (5): Cocoa, FlutterMacOS, RunnerTests, XCTest, XCTestCase

### Community 120 - "ios/RunnerTests/RunnerTests.swift"
Cohesion: 0.28
Nodes (5): Flutter, FlutterSceneDelegate, UIKit, SceneDelegate, RunnerTests

### Community 121 - "app_colors_palette_test.dart"
Cohesion: 0.22
Nodes (8): package:weeding_app/app/core/theme/app_colors.dart, contrast, darker, la, lb, lighter, main, palettes

### Community 122 - "AppDelegate"
Cohesion: 0.25
Nodes (6): Any, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, UIApplication, AppDelegate, Bool

### Community 123 - "Console d'exploitation"
Cohesion: 0.33
Nodes (5): Ce que la console permet, Console d'exploitation, Limites connues, Nommer le premier exploitant, Pourquoi des fonctions plutôt qu'un rôle privilégié

### Community 124 - "AppDelegate"
Cohesion: 0.47
Nodes (4): FlutterAppDelegate, NSApplication, AppDelegate, Bool

### Community 125 - "RegisterGeneratedPlugins"
Cohesion: 0.33
Nodes (5): FlutterPluginRegistry, FlutterViewController, NSWindow, RegisterGeneratedPlugins(), MainFlutterWindow

### Community 126 - "TablesController"
Cohesion: 0.40
Nodes (4): tables_controller.dart, dependencies, TablesBinding, TablesController

### Community 127 - "../theme/app_colors.dart"
Cohesion: 0.40
Nodes (4): ../theme/app_colors.dart, venueColor, venueIcon, venueLabel

### Community 128 - "subscription_banner.dart"
Cohesion: 0.18
Nodes (10): ../../data/models/subscription.dart, ../../routes/app_routes.dart, subscription_controller.dart, build, compact, _CompactBanner, isUrgent, message (+2 more)

### Community 129 - "supabase_config.dart"
Cohesion: 0.18
Nodes (10): package:flutter_dotenv/flutter_dotenv.dart, static bool get, static const String, static String get, anonKey, eventId, guestPortalUrl, isConfigured (+2 more)

### Community 130 - "venue_map_launcher.dart"
Cohesion: 0.20
Nodes (9): ../../data/models/event_venue.dart, package:url_launcher/url_launcher.dart, https, launchUrl, launchVenueMap, mapsUrl, query, uri (+1 more)

### Community 131 - "GuestsController"
Cohesion: 0.40
Nodes (4): guests_controller.dart, dependencies, GuestsBinding, GuestsController

### Community 136 - "subscription_test.dart"
Cohesion: 0.40
Nodes (4): package:weeding_app/app/data/models/subscription.dart, main, overviewJson, planJson

### Community 138 - "workspace_onboarding_binding.dart"
Cohesion: 0.40
Nodes (4): dependencies, WorkspaceOnboardingBinding, WorkspaceOnboardingController, workspace_onboarding_controller.dart

### Community 139 - "wedding_palette_test.dart"
Cohesion: 0.50
Nodes (3): package:weeding_app/app/core/theme/app_theme.dart, package:weeding_app/app/core/theme/wedding_palette.dart, main

## Knowledge Gaps
- **1498 isolated node(s):** `name`, `short_name`, `description`, `start_url`, `scope` (+1493 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **18 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `EventVenue` connect `event_venue.dart` to `venues_page.dart`, `../../core/theme/app_colors.dart`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Why does `_showGuestDetails` connect `_showGuestDetails` to `invitations_page.dart`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Why does `AuthController` connect `home_page_layout_test.dart` to `settings_page.dart`, `auth_controller.dart`, `app_binding.dart`, `package:get/get.dart`, `home_page.dart`, `package:flutter/material.dart`, `register_page.dart`, `login_page.dart`, `home_controller.dart`, `app_pages.dart`, `workspace_onboarding_controller.dart`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **What connects `name`, `short_name`, `description` to the rest of the system?**
  _1498 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_colors.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.031746031746031744 - nodes in this community are weakly interconnected._
- **Should `app_text_styles.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06896551724137931 - nodes in this community are weakly interconnected._
- **Should `settings_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.043478260869565216 - nodes in this community are weakly interconnected._