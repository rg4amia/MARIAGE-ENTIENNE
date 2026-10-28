# Graph Report - MARIAGE ENTIENNE  (2026-10-27)

## Corpus Check
- 204 files · ~527,098 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2339 nodes · 3195 edges · 143 communities (127 shown, 16 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `ce4a1a9d`
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
- _MediaPlayerPageState
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
- Implementation Plan — Correction de 3 bugs (Mariage Kodjo & Marie Ange)
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
- SupabaseClient
- Déploiement mobile, portail invité et Supabase
- chair_repository.dart
- platform_admin.dart
- validators.dart
- 7. Sprint MVP Recommande
- 2. Cadrage Fonctionnel
- wedding_theme_repository.dart
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
- subscription.dart
- main_navigation_controller.dart
- qr_code_page.dart
- StatelessWidget
- app_binding.dart
- invitation_sender.dart
- plans_page.dart
- whatsapp_helper.dart
- admin_controller.dart
- package:get/get.dart
- guest.dart
- subscription_controller.dart
- guest_media.dart
- home_page_layout_test.dart
- Color
- GetxController
- Offre commerciale
- High-level view
- package:supabase_flutter/supabase_flutter.dart
- invitation_message_test.dart
- FlutterMacOS
- ios/RunnerTests/RunnerTests.swift
- app_colors_palette_test.dart
- AppDelegate
- Console d'exploitation
- AppDelegate
- RegisterGeneratedPlugins
- State
- Widget?
- GuestsController
- supabase_config.dart
- venue_map_launcher.dart
- InvitationsController
- _AssignGuestSheet
- _GuestDetailSheet
- _MoveGuestSheet
- _TableChairsSection
- subscription_test.dart
- TablesController
- venues_binding.dart
- GetMiddleware
- quota_error_test.dart
- validators_test.dart
- _BulkSendStepSheet

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

## Communities (143 total, 16 thin omitted)

### Community 0 - "app_colors.dart"
Cohesion: 0.03
Nodes (62): static Color, AppColors, applyPalette, background, cardDark, cardDarkText, _contrast, dark (+54 more)

### Community 1 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.17
Nodes (11): app_links, audio_session, file_selector_macos, flutter_secure_storage_macos, flutter_sound, Foundation, just_audio, share_plus (+3 more)

### Community 2 - "app_text_styles.dart"
Cohesion: 0.05
Nodes (36): app_colors.dart, app_text_styles.dart, package:google_fonts/google_fonts.dart, static String, static TextStyle, static ThemeData get, wedding_palette.dart, applyPalette (+28 more)

### Community 3 - "settings_page.dart"
Cohesion: 0.05
Nodes (43): package:intl/date_symbol_data_local.dart, package:intl/intl.dart, ScrollController, static const int, build, _buildTextField, _buildWeddingInfoCard, colors (+35 more)

### Community 4 - "entrance_qr_page.dart"
Cohesion: 0.08
Nodes (24): @visibleForTesting, ../../data/models/entrance_qr.dart, ../../data/repositories/entrance_repository.dart, RealtimeChannel?, build, _buildActionChip, _buildActions, _buildCodeChip (+16 more)

### Community 5 - "auth_controller.dart"
Cohesion: 0.07
Nodes (29): ../admin/admin_controller.dart, ../../core/theme/wedding_theme_controller.dart, ../guests/guests_controller.dart, ../home/home_controller.dart, ../invitations/invitations_controller.dart, StreamSubscription, ../tables/tables_controller.dart, authenticatedEntryRoute (+21 more)

### Community 6 - "table_detail_page.dart"
Cohesion: 0.04
Nodes (48): Future, _assign, _availableChairs, build, _buildChairsError, _buildChairsGrid, _buildDetailRow, _buildEmptyChairs (+40 more)

### Community 7 - "guest_access_page.dart"
Cohesion: 0.06
Nodes (36): audio_recorder_page.dart, ../../core/utils/invitation_card_generator.dart, GlobalKey, guest_venues_sheet.dart, recorder_factory.dart, TickerProviderStateMixin, video_recorder_page.dart, build (+28 more)

### Community 8 - "guest_access_controller.dart"
Cohesion: 0.06
Nodes (34): _client, currentStep, errorMessage, goToMediaChoice, guest, GuestAccessStep, _guestRepo, guestSeat (+26 more)

### Community 9 - "invitations_page.dart"
Cohesion: 0.05
Nodes (37): ../../data/models/guest_media.dart, ../../data/repositories/media_repository.dart, MaterialPageRoute, media_player_page.dart, build, color, count, createState (+29 more)

### Community 10 - "micro_interactions.dart"
Cohesion: 0.07
Nodes (30): _anim, backgroundColor, borderRadius, boxShadow, build, child, createState, _ctrl (+22 more)

### Community 11 - "media-duration.ts"
Cohesion: 0.11
Nodes (17): admin, corsHeaders, GuestTokenRecord, inlineScriptValue(), renderSPA(), ascii(), detectMediaDuration(), ElementHeader (+9 more)

### Community 12 - "shared_components.dart"
Cohesion: 0.04
Nodes (44): EdgeInsets, Gradient?, PreferredSizeWidget, Size get, String? get, ../theme/app_colors.dart, ../theme/app_text_styles.dart, actionLabel (+36 more)

### Community 13 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, MyApplicationClass (+14 more)

### Community 14 - "wedding_theme_page.dart"
Cohesion: 0.04
Nodes (45): @immutable, WeddingPalette, _accentController, _backgroundController, bodyFont, build, _CardPreview, color (+37 more)

### Community 15 - "home_page.dart"
Cohesion: 0.07
Nodes (27): ../navigation/main_navigation_controller.dart, ../subscription/subscription_banner.dart, build, _buildBody, _buildInvitationStatus, _buildKpiRow, _buildQuickActions, _buildWeddingHeader (+19 more)

### Community 16 - "web_video_recorder.dart"
Cohesion: 0.08
Nodes (25): VideoElement?, build, _cameraReady, _chunks, createState, dispose, _elapsedSeconds, _formatDuration (+17 more)

### Community 17 - "guest_detail_page.dart"
Cohesion: 0.05
Nodes (42): ../../core/utils/whatsapp_helper.dart, ../../data/models/guest_link.dart, _AssignSheet, _AssignSheetState, availableChairs, build, _confirmCancellation, _confirmDelete (+34 more)

### Community 18 - "guests_controller.dart"
Cohesion: 0.07
Nodes (28): ../../data/models/guest_seat.dart, assignSeatToGuest, cancelledCount, confirmedCount, createGuest, declinedCount, deleteGuest, filterStatus (+20 more)

### Community 20 - "audio_recorder_page.dart"
Cohesion: 0.08
Nodes (23): FlutterSoundRecorder, package:flutter_sound/flutter_sound.dart, Timer?, build, createState, dispose, _elapsedSeconds, _formatDuration (+15 more)

### Community 21 - "animated_widgets.dart"
Cohesion: 0.08
Nodes (25): Animation, Duration, TextStyle?, _anim, AnimatedCounter, _AnimatedCounterState, borderRadius, build (+17 more)

### Community 22 - "web_audio_recorder.dart"
Cohesion: 0.09
Nodes (21): dart:html, MediaRecorder?, MediaStream?, build, _chunks, createState, dispose, _elapsedSeconds (+13 more)

### Community 23 - "main_shell_page.dart"
Cohesion: 0.13
Nodes (15): ../../core/widgets/app_bottom_nav_bar.dart, ../guests/guests_page.dart, ../home/home_page.dart, ../invitations/invitations_page.dart, main_navigation_controller.dart, ../settings/settings_page.dart, ../tables/tables_page.dart, build (+7 more)

### Community 24 - "login_page.dart"
Cohesion: 0.11
Nodes (18): AnimationController, ../../core/utils/validators.dart, _bgCtrl, build, _buildInput, _buildLabel, controller, createState (+10 more)

### Community 25 - "home_controller.dart"
Cohesion: 0.10
Nodes (19): ../../data/models/profile.dart, ../../data/repositories/table_repository.dart, Profile? get, cardUnlocked, _channels, currentProfile, _guestRepository, _invitationRepository (+11 more)

### Community 26 - "invitation_card_generator.dart"
Cohesion: 0.10
Nodes (20): dart:ui, package:flutter/rendering.dart, package:path_provider/path_provider.dart, build, captureCard, _CardInfo, guestName, icon (+12 more)

### Community 27 - "guest_repository.dart"
Cohesion: 0.10
Nodes (19): ../models/guest.dart, ../models/guest_seat.dart, package:uuid/uuid.dart, assignSeat, _client, createGuest, deleteGuest, _generateQrToken (+11 more)

### Community 28 - "models_test.dart"
Cohesion: 0.22
Nodes (8): package:weeding_app/app/data/models/chair.dart, package:weeding_app/app/data/models/entrance_qr.dart, package:weeding_app/app/data/models/guest_media.dart, package:weeding_app/app/data/models/guest_seat.dart, package:weeding_app/app/data/models/invitation.dart, package:weeding_app/app/data/models/profile.dart, package:weeding_app/app/data/models/wedding_table.dart, main

### Community 29 - "guests_page.dart"
Cohesion: 0.08
Nodes (25): ../../core/utils/invitation_sender.dart, ../../core/widgets/shared_components.dart, _avatarColor, build, _buildField, _buildFilterChips, controller, createState (+17 more)

### Community 30 - "video_recorder_page.dart"
Cohesion: 0.12
Nodes (17): dart:io, ImagePicker, package:image_picker/image_picker.dart, build, createState, _formatDuration, _getVideoDuration, initState (+9 more)

### Community 31 - "admin_repository.dart"
Cohesion: 0.15
Nodes (12): ../models/platform_admin.dart, AdminRepository, _client, grantInvitations, isPlatformAdmin, listAccounts, listEvents, listOrganizations (+4 more)

### Community 32 - "tables_controller.dart"
Cohesion: 0.10
Nodes (19): ../../data/models/chair.dart, ../../data/models/wedding_table.dart, assignGuestToChair, createTable, deleteChair, deleteTable, getChairsForTable, getUnassignedGuests (+11 more)

### Community 33 - "invitation.dart"
Cohesion: 0.12
Nodes (16): chairId, copyWith, createdAt, deepLink, fromJson, guestId, id, Invitation (+8 more)

### Community 34 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.13
Nodes (10): package:flutter_test/flutter_test.dart, package:weeding_app/app/core/utils/invitation_card_generator.dart, package:weeding_app/app/data/models/event_venue.dart, package:weeding_app/app/data/models/platform_admin.dart, package:weeding_app/app/modules/navigation/main_navigation_controller.dart, main, main, main (+2 more)

### Community 35 - "Win32Window"
Cohesion: 0.05
Nodes (57): PluginRegistry, RECT, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT (+49 more)

### Community 36 - "media_player_page.dart"
Cohesion: 0.04
Nodes (54): AudioPlayer?, package:just_audio/just_audio.dart, package:video_player/video_player.dart, Random, VideoPlayerController?, _audioPlayer, _barCount, _bars (+46 more)

### Community 37 - "tables_page.dart"
Cohesion: 0.11
Nodes (17): FormState, build, _buildField, _capacityController, controller, createState, dispose, _formKey (+9 more)

### Community 38 - "event_venue.dart"
Cohesion: 0.11
Nodes (18): addressLine, city, countryCode, endsAt, eventId, EventVenue, fromJson, id (+10 more)

### Community 39 - "wedding_header.dart"
Cohesion: 0.14
Nodes (13): IconData, micro_interactions.dart, build, child, gradientColors, HeaderInfoBanner, icon, onBackPressed (+5 more)

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
Cohesion: 0.07
Nodes (28): ../../core/theme/app_text_styles.dart, ../../core/utils/venue_presentation.dart, TextEditingController, TextInputType?, VoidCallback, build, _GuestVenueCard, onMap (+20 more)

### Community 44 - "DESIGN.md"
Cohesion: 0.14
Nodes (13): Brand & Style, Buttons, Cards, Colors, Components, Elevation & Depth, Input Fields, Layout & Spacing (+5 more)

### Community 45 - "guest_link.dart"
Cohesion: 0.14
Nodes (13): copyWith, createdAt, fromJson, getInviteUrl, guestId, GuestLink, guestToken, id (+5 more)

### Community 46 - "chair.dart"
Cohesion: 0.15
Nodes (12): bool get, Chair, chairNumber, copyWith, createdAt, fromJson, guestId, guestName (+4 more)

### Community 47 - "Implementation Plan — Correction de 3 bugs (Mariage Kodjo & Marie Ange)"
Cohesion: 0.08
Nodes (25): Aucune migration de base de données nécessaire, Aucune migration de base de données nécessaire, Aucune migration de schéma nécessaire, Bug 1 — En-tête incorrect : "Mariage Entienne" au lieu de "Kodjo & Marie Ange", Bug 2 — QR Code non fonctionnel sur la carte d'invitation de l'invité, Bug 3 — Table et chaise affichées "Non assignée" malgré une assignation existante, Cause racine identifiée, Cause racine identifiée (+17 more)

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
Nodes (12): ../../data/repositories/wedding_theme_repository.dart, package:flutter/foundation.dart, Rx, _apply, isLoading, isSaving, loadForCurrentWedding, onInit (+4 more)

### Community 55 - "register_page.dart"
Cohesion: 0.10
Nodes (20): FocusNode?, build, _buildField, controller, createState, _ctrl, dispose, _emailFocus (+12 more)

### Community 56 - "app_pages.dart"
Cohesion: 0.07
Nodes (27): app_routes.dart, ../modules/admin/admin_console_page.dart, ../modules/auth/auth_binding.dart, ../modules/auth/login_page.dart, ../modules/auth/register_page.dart, ../modules/guests/guest_detail_page.dart, ../modules/guests/guests_binding.dart, ../modules/invitations/entrance_qr_page.dart (+19 more)

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
Nodes (14): ../../data/repositories/auth_repository.dart, RxBool, brideNameController, createWorkspace, eventDate, eventTitleController, groomNameController, isLoading (+6 more)

### Community 64 - "static const"
Cohesion: 0.25
Nodes (7): static const, ValueChanged, AppBottomNavBar, build, currentIndex, _icons, onTabSelected

### Community 65 - "secure_local_storage.dart"
Cohesion: 0.14
Nodes (13): dart:async, LocalStorage, package:flutter_secure_storage/flutter_secure_storage.dart, SharedPreferences?, accessToken, hasAccessToken, initialize, persistSession (+5 more)

### Community 66 - "invitation_repository.dart"
Cohesion: 0.20
Nodes (9): ../models/invitation.dart, _client, getAllInvitations, getInvitationByGuestId, getInvitationCount, getMediaCount, InvitationRepository, recordDelivery (+1 more)

### Community 67 - "1. Prompt Produit Reorganise"
Cohesion: 0.22
Nodes (9): 1. Prompt Produit Reorganise, Back-office metier, Espace invite, Espace maries, Fonctionnalites minimales MVP, Objectif principal, Parcours attendu, Regle metier principale (+1 more)

### Community 68 - "venues_controller.dart"
Cohesion: 0.13
Nodes (14): ../../core/utils/venue_map_launcher.dart, ../../data/repositories/event_venue_repository.dart, RxList, deleteVenue, isLoading, isSaving, loadVenues, _nullIfEmpty (+6 more)

### Community 69 - "SupabaseClient"
Cohesion: 0.29
Nodes (6): ../../core/constants/supabase_config.dart, ../models/entrance_qr.dart, SupabaseClient, _client, EntranceRepository, getOrCreate

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

### Community 79 - "../../core/theme/app_colors.dart"
Cohesion: 0.08
Nodes (26): ../auth/auth_controller.dart, ../../core/theme/app_colors.dart, ../../core/widgets/animated_widgets.dart, ../../core/widgets/micro_interactions.dart, ../../core/widgets/wedding_rings_icon.dart, build, createState, initState (+18 more)

### Community 84 - "wedding_palette.dart"
Cohesion: 0.08
Nodes (23): int? get, accent, background, body, bodyFont, celestialRomance, colorFromHex, colorToHex (+15 more)

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

### Community 98 - "package:flutter/material.dart"
Cohesion: 0.20
Nodes (8): package:flutter/material.dart, web_audio_recorder.dart, web_video_recorder.dart, buildWebAudioRecorderPage, buildWebVideoRecorderPage, buildWebAudioRecorderPage, buildWebVideoRecorderPage, minDurationSeconds

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
Cohesion: 0.06
Nodes (40): admin_controller.dart, StatelessWidget, _AccountsTab, actions, AdminConsolePage, _Badge, build, _Card (+32 more)

### Community 103 - "app_binding.dart"
Cohesion: 0.20
Nodes (9): ../modules/admin/admin_controller.dart, ../modules/auth/auth_controller.dart, ../modules/guests/guests_controller.dart, ../modules/home/home_controller.dart, ../modules/invitations/invitations_controller.dart, ../modules/navigation/main_navigation_controller.dart, ../modules/subscription/subscription_controller.dart, ../modules/tables/tables_controller.dart (+1 more)

### Community 104 - "invitation_sender.dart"
Cohesion: 0.05
Nodes (37): aborted, awaiting, build, _BulkRecapSheet, _BulkStepResult, _ChannelTile, createState, email (+29 more)

### Community 105 - "plans_page.dart"
Cohesion: 0.09
Nodes (22): ../../data/models/subscription.dart, ../../routes/app_routes.dart, subscription_controller.dart, SubscriptionPlan, build, isCurrent, label, plan (+14 more)

### Community 106 - "whatsapp_helper.dart"
Cohesion: 0.05
Nodes (37): ../constants/supabase_config.dart, ../../data/repositories/wedding_settings_repository.dart, return, bride, buffer, _buildInvitationMessage, ceremonyDate, _ceremonyTime (+29 more)

### Community 107 - "admin_controller.dart"
Cohesion: 0.09
Nodes (21): ../../data/models/platform_admin.dart, ../../data/repositories/admin_repository.dart, RxString, accounts, actions, availablePlans, errorMessage, events (+13 more)

### Community 108 - "package:get/get.dart"
Cohesion: 0.14
Nodes (13): auth_controller.dart, Bindings, guest_access_controller.dart, home_controller.dart, package:get/get.dart, AppBinding, AuthBinding, dependencies (+5 more)

### Community 109 - "guest.dart"
Cohesion: 0.12
Nodes (15): copyWith, createdAt, email, fromJson, fullName, Guest, hasRsvpResponded, id (+7 more)

### Community 110 - "subscription_controller.dart"
Cohesion: 0.12
Nodes (15): ../../data/repositories/subscription_repository.dart, List, Rxn, SubscriptionOverview, clear, currentPlanId, isLoading, isLoadingPlans (+7 more)

### Community 111 - "guest_media.dart"
Cohesion: 0.13
Nodes (14): double?, clientDurationSeconds, clientValidated, fromJson, guestId, GuestMedia, id, isValid (+6 more)

### Community 112 - "home_page_layout_test.dart"
Cohesion: 0.14
Nodes (15): package:shared_preferences/shared_preferences.dart, package:weeding_app/app/modules/auth/auth_controller.dart, package:weeding_app/app/modules/home/home_controller.dart, package:weeding_app/app/modules/home/home_page.dart, package:weeding_app/app/modules/subscription/subscription_controller.dart, ScrollableState, AuthController, HomeController (+7 more)

### Community 113 - "Color"
Cohesion: 0.17
Nodes (11): Color, CustomPainter, build, color, paint, shouldRepaint, size, strokeWidth (+3 more)

### Community 114 - "GetxController"
Cohesion: 0.22
Nodes (8): GetxController, WeddingThemeController, AdminController, dependencies, WorkspaceOnboardingBinding, WorkspaceOnboardingController, SubscriptionController, workspace_onboarding_controller.dart

### Community 115 - "Offre commerciale"
Cohesion: 0.18
Nodes (10): A. Packs mariage — paiement unique, B. Abonnements professionnels, Ce qui empêche de remettre le compteur à zéro, L'ancrage face au carton imprimé, Le moment du paiement, Le paiement mobile, Les trois leviers de conversion, Offre commerciale (+2 more)

### Community 116 - "High-level view"
Cohesion: 0.29
Nodes (6): High-level view, Name correction: migration scope and seed alignment, QR payload: meaningful URL replaces raw token, Seat display: UUID → human label, and the refresh timing gap, Test coverage, Three-bug fix: couple names, QR payload, table/seat display

### Community 117 - "package:supabase_flutter/supabase_flutter.dart"
Cohesion: 0.20
Nodes (8): ../models/subscription.dart, package:supabase_flutter/supabase_flutter.dart, package:weeding_app/app/modules/invitations/entrance_qr_page.dart, _client, getOverview, getPlans, SubscriptionRepository, main

### Community 118 - "invitation_message_test.dart"
Cohesion: 0.29
Nodes (6): package:flutter_dotenv/flutter_dotenv.dart, package:weeding_app/app/core/utils/whatsapp_helper.dart, package:weeding_app/app/data/models/guest.dart, package:weeding_app/app/data/repositories/wedding_settings_repository.dart, guest, main

### Community 119 - "FlutterMacOS"
Cohesion: 0.28
Nodes (5): Cocoa, FlutterMacOS, RunnerTests, XCTest, XCTestCase

### Community 120 - "ios/RunnerTests/RunnerTests.swift"
Cohesion: 0.28
Nodes (5): Flutter, FlutterSceneDelegate, UIKit, SceneDelegate, RunnerTests

### Community 121 - "app_colors_palette_test.dart"
Cohesion: 0.15
Nodes (11): package:weeding_app/app/core/theme/app_colors.dart, package:weeding_app/app/core/theme/app_theme.dart, package:weeding_app/app/core/theme/wedding_palette.dart, contrast, darker, la, lb, lighter (+3 more)

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

### Community 126 - "State"
Cohesion: 0.10
Nodes (32): _PasswordField, SingleTickerProviderStateMixin, State, StatefulWidget, FadeInSlide, _FadeInSlideState, ScaleIn, _ScaleInState (+24 more)

### Community 127 - "Widget?"
Cohesion: 0.32
Nodes (7): Offset, PageRouteBuilder, T, page, SlideFadeRoute, SlideUpRoute, Widget?

### Community 128 - "GuestsController"
Cohesion: 0.40
Nodes (4): guests_controller.dart, dependencies, GuestsBinding, GuestsController

### Community 129 - "supabase_config.dart"
Cohesion: 0.20
Nodes (9): static bool get, static const String, static String get, anonKey, eventId, guestPortalUrl, isConfigured, SupabaseConfig (+1 more)

### Community 130 - "venue_map_launcher.dart"
Cohesion: 0.20
Nodes (9): ../../data/models/event_venue.dart, package:url_launcher/url_launcher.dart, https, launchUrl, launchVenueMap, mapsUrl, query, uri (+1 more)

### Community 131 - "InvitationsController"
Cohesion: 0.40
Nodes (4): invitations_controller.dart, dependencies, InvitationsBinding, InvitationsController

### Community 136 - "subscription_test.dart"
Cohesion: 0.40
Nodes (4): package:weeding_app/app/data/models/subscription.dart, main, overviewJson, planJson

### Community 137 - "TablesController"
Cohesion: 0.40
Nodes (4): tables_controller.dart, dependencies, TablesBinding, TablesController

### Community 138 - "venues_binding.dart"
Cohesion: 0.40
Nodes (4): venues_controller.dart, dependencies, VenuesBinding, VenuesController

### Community 139 - "GetMiddleware"
Cohesion: 0.67
Nodes (3): GetMiddleware, AuthMiddleware, PlatformAdminMiddleware

## Knowledge Gaps
- **1535 isolated node(s):** `name`, `short_name`, `description`, `start_url`, `scope` (+1530 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **16 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `EventVenue` connect `event_venue.dart` to `venues_page.dart`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Why does `AuthController` connect `home_page_layout_test.dart` to `settings_page.dart`, `auth_controller.dart`, `app_binding.dart`, `package:get/get.dart`, `home_page.dart`, `../../core/theme/app_colors.dart`, `GetxController`, `register_page.dart`, `login_page.dart`, `home_controller.dart`, `app_pages.dart`, `workspace_onboarding_controller.dart`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **Why does `GuestRepository` connect `guest_repository.dart` to `tables_controller.dart`, `table_detail_page.dart`, `guest_access_controller.dart`, `invitations_page.dart`, `invitations_controller.dart`, `guests_controller.dart`, `home_controller.dart`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **What connects `name`, `short_name`, `description` to the rest of the system?**
  _1535 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_colors.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.031746031746031744 - nodes in this community are weakly interconnected._
- **Should `app_text_styles.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05405405405405406 - nodes in this community are weakly interconnected._
- **Should `settings_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04756871035940803 - nodes in this community are weakly interconnected._