import 'package:flutter/material.dart';
import 'package:inspection_tracker/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api/api_client.dart';
import 'core/config/app_config.dart';
import 'core/config/locale_controller.dart';
import 'core/storage/offline_queue.dart';
import 'core/storage/token_store.dart';
import 'core/ui/language_menu.dart';
import 'core/utils/localization_extensions.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/session_controller.dart';
import 'features/inspections/data/inspections_repository.dart';
import 'features/inspections/data/models.dart';
import 'features/inspections/presentation/customer_home_screen.dart';
import 'features/inspections/presentation/inspector_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.current;
  final tokenStore = TokenStore();
  final apiClient = ApiClient(config: config, tokenStore: tokenStore);
  final offlineQueue = await OfflineQueueService.init();
  final preferences = await SharedPreferences.getInstance();
  final localeController = LocaleController(preferences: preferences);

  runApp(AppRoot(
    config: config,
    tokenStore: tokenStore,
    apiClient: apiClient,
    offlineQueue: offlineQueue,
    localeController: localeController,
  ));
}

class AppRoot extends StatelessWidget {
  const AppRoot({
    required this.config,
    required this.tokenStore,
    required this.apiClient,
    required this.offlineQueue,
    required this.localeController,
    super.key,
  });

  final AppConfig config;
  final TokenStore tokenStore;
  final ApiClient apiClient;
  final OfflineQueueService offlineQueue;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        Provider<TokenStore>.value(value: tokenStore),
        Provider<ApiClient>.value(value: apiClient),
        Provider<OfflineQueueService>.value(value: offlineQueue),
        ChangeNotifierProvider<LocaleController>.value(value: localeController),
        ProxyProvider2<ApiClient, OfflineQueueService, InspectionsRepository>(
          update: (_, api, queue, __) => InspectionsRepository(apiClient: api, offlineQueueService: queue),
        ),
        ProxyProvider2<ApiClient, TokenStore, AuthRepository>(
          update: (_, api, tokens, __) => AuthRepository(apiClient: api, tokenStore: tokens),
        ),
        ChangeNotifierProvider<SessionController>(
          create: (context) => SessionController(context.read<AuthRepository>()),
        ),
      ],
      child: MaterialApp(
        onGenerateTitle: (context) => context.l10n.appTitle,
        locale: context.watch<LocaleController>().locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2B5876),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF6F9FC),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: const BorderSide(width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.zero,
          ),
        ),
        home: const _RootNavigator(),
      ),
    );
  }
}

class _RootNavigator extends StatelessWidget {
  const _RootNavigator();

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionController>(
      builder: (context, session, _) {
        if (!session.isAuthenticated) {
          return const LoginScreen();
        }
        final profile = session.profile!;
        if (profile.isInspector) {
          return InspectorHomeScreen(profile: profile);
        }
        if (profile.isCustomer) {
          return CustomerHomeScreen(profile: profile);
        }
        return _UnsupportedRoleScreen(profile: profile);
      },
    );
  }
}

class _UnsupportedRoleScreen extends StatelessWidget {
  const _UnsupportedRoleScreen({required this.profile});

  final PortalProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appTitleShort),
        actions: const [LanguageMenu()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.desktop_windows_outlined, size: 48),
              const SizedBox(height: 12),
              Text(
                context.l10n.unsupportedGreeting(profile.fullName),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.unsupportedMessage,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.read<SessionController>().logout(),
                icon: const Icon(Icons.logout),
                label: Text(context.l10n.commonSignOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
