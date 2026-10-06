import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const WatchaApp());

enum WatchStatus { wishlist, watching, completed }

enum MediaType { movie, series }

class WatchItem {
  WatchItem({
    required this.id,
    required this.title,
    required this.type,
    required this.year,
    required this.status,
    this.rating,
    this.note = '',
    this.posterUrl,
    this.watchUrl,
  });

  final int id;
  String title;
  MediaType type;
  int? year;
  WatchStatus status;
  int? rating;
  String note;
  String? posterUrl;
  String? watchUrl;
}

abstract class WatchlistRepository {
  Future<List<WatchItem>> getItems();
  Future<void> save(WatchItem item);
  Future<void> delete(int id);
}

const configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

final apiBaseUrl = configuredApiBaseUrl.isNotEmpty
    ? configuredApiBaseUrl
    : kIsWeb
    ? 'http://localhost:3000/api'
    : defaultTargetPlatform == TargetPlatform.android
    ? 'http://10.0.2.2:3000/api'
    : 'http://localhost:3000/api';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiClient implements WatchlistRepository {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  String? token;

  Uri _uri(String path) => Uri.parse('$apiBaseUrl$path');
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer ${token!}',
  };

  Future<Map<String, dynamic>> _request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final request = http.Request(method, _uri(path))..headers.addAll(_headers);
    if (body != null) request.body = jsonEncode(body);
    final response = await _client.send(request);
    final text = await response.stream.bytesToString();
    Map<String, dynamic> data = {};
    if (text.isNotEmpty) {
      try {
        data = jsonDecode(text) as Map<String, dynamic>;
      } catch (_) {
        throw ApiException('เซิร์ฟเวอร์ตอบกลับไม่ถูกต้อง');
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['message'] as String? ?? 'เกิดข้อผิดพลาด (${response.statusCode})',
      );
    }
    return data;
  }

  Future<Map<String, dynamic>> authenticate(
    String path,
    String email,
    String password, {
    String? name,
  }) async {
    final body = <String, dynamic>{'email': email, 'password': password};
    if (name != null) body['name'] = name;
    final data = await _request('POST', path, body);
    token = (data['data'] as Map<String, dynamic>)['token'] as String;
    return data['data'] as Map<String, dynamic>;
  }

  WatchItem _item(Map<String, dynamic> json) => WatchItem(
    id: (json['id'] as num).toInt(),
    title: json['title'] as String,
    type: json['type'] == 'series' ? MediaType.series : MediaType.movie,
    year: (json['year'] as num?)?.toInt(),
    status: WatchStatus.values.firstWhere(
      (value) => value.name == json['status'],
      orElse: () => WatchStatus.wishlist,
    ),
    rating: (json['rating'] as num?)?.toInt(),
    note: json['note'] as String? ?? '',
    posterUrl: json['poster_url'] as String?,
    watchUrl: json['watch_url'] as String?,
  );

  @override
  Future<List<WatchItem>> getItems() async {
    final data = await _request('GET', '/watchlist');
    return ((data['data'] as List<dynamic>?) ?? [])
        .map((item) => _item(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> save(WatchItem item) async {
    final body = {
      'title': item.title,
      'type': item.type.name,
      'year': item.year,
      'status': item.status.name,
      'rating': item.rating,
      'note': item.note,
      'poster_url': item.posterUrl,
      'watch_url': item.watchUrl,
    };
    await _request(
      item.id > 0 ? 'PUT' : 'POST',
      item.id > 0 ? '/watchlist/${item.id}' : '/watchlist',
      body,
    );
  }

  @override
  Future<void> delete(int id) async {
    await _request('DELETE', '/watchlist/$id');
  }
}

class WatchaApp extends StatefulWidget {
  const WatchaApp({super.key});

  @override
  State<WatchaApp> createState() => _WatchaAppState();
}

class _WatchaAppState extends State<WatchaApp> {
  final repository = ApiClient();
  final navigatorKey = GlobalKey<NavigatorState>();
  List<WatchItem> items = [];
  Map<String, dynamic>? user;
  bool loading = false;
  String? error;
  bool isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    repository.token = prefs.getString('watcha_token');
    if (repository.token != null) {
      try {
        final profile = await repository._request('GET', '/auth/profile');
        user = profile['data'] as Map<String, dynamic>;
        await _reload();
      } catch (_) {
        await _logout();
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _reload() async {
    try {
      final loaded = await repository.getItems();
      if (mounted) setState(() => items = loaded);
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } catch (_) {
      if (mounted) setState(() => error = 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้');
    }
  }

  Future<void> _login(String email, String password, {String? name}) async {
    final result = await repository.authenticate(
      name == null ? '/auth/login' : '/auth/register',
      email,
      password,
      name: name,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('watcha_token', repository.token!);
    user = result['user'] as Map<String, dynamic>;
    await _reload();
    if (mounted) setState(() => error = null);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('watcha_token');
    repository.token = null;
    if (mounted) {
      setState(() {
        user = null;
        items = [];
      });
    }
  }

  Future<WatchItem?> _openEditor([WatchItem? item]) async {
    final result = await navigatorKey.currentState!.push<WatchItem>(
      MaterialPageRoute(builder: (_) => EditItemPage(item: item)),
    );
    if (result != null) {
      try {
        await repository.save(result);
        await _reload();
        return items.where((entry) => entry.id == result.id).firstOrNull ??
            result;
      } on ApiException catch (exception) {
        if (mounted) setState(() => error = exception.message);
      }
    }
    return null;
  }

  Future<void> _openDetail(WatchItem item) async {
    await navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (_) => DetailPage(
          item: item,
          onChanged: _reload,
          onEdit: (currentItem) => _openEditor(currentItem),
          onDelete: () async {
            try {
              await repository.delete(item.id);
              await _reload();
            } on ApiException catch (exception) {
              if (mounted) setState(() => error = exception.message);
            }
          },
        ),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Watcha',
      theme: ThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: isDarkMode
            ? const Color(0xff101014)
            : const Color(0xfff7f7fa),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff9670ff),
          brightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),
        fontFamily: 'sans',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: isDarkMode ? const Color(0xff1c1c23) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      home: loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : user != null
          ? HomePage(
              items: items,
              onOpen: _openDetail,
              onAdd: () => _openEditor(),
              onLogout: _logout,
              user: user,
              isDarkMode: isDarkMode,
              onThemeChanged: (value) => setState(() => isDarkMode = value),
            )
          : LoginPage(onLogin: _login),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({required this.onLogin, super.key});
  final Future<void> Function(String email, String password, {String? name})
  onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  bool registering = false;
  bool submitting = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty ||
        password.text.isEmpty ||
        (registering && name.text.trim().isEmpty)) {
      setState(() => error = 'กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }
    if (registering && password.text.length < 8) {
      setState(() => error = 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
      return;
    }
    setState(() {
      submitting = true;
      error = null;
    });
    try {
      await widget.onLogin(
        email.text.trim(),
        password.text,
        name: registering ? name.text.trim() : null,
      );
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.movie_filter_rounded,
                size: 52,
                color: Color(0xffa681ff),
              ),
              const SizedBox(height: 24),
              Text(
                'Watcha App',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff9670ff),
                ),
              ),
              Text(
                registering ? 'สร้างบัญชี Watcha' : 'ยินดีต้อนรับกลับมา',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                registering
                    ? 'สมัครสมาชิกเพื่อเริ่มจัดการรายการของคุณ'
                    : 'เข้าสู่ระบบเพื่อจัดการรายการของคุณ',
                style: TextStyle(color: Colors.grey.shade400),
              ),
              const SizedBox(height: 32),
              if (registering) ...[
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'ชื่อ'),
                ),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'อีเมล'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
              ),
              const SizedBox(height: 22),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: submitting ? null : submit,
                  child: Text(
                    submitting
                        ? 'กำลังดำเนินการ...'
                        : registering
                        ? 'สมัครสมาชิก'
                        : 'เข้าสู่ระบบ',
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: submitting
                      ? null
                      : () => setState(() {
                          registering = !registering;
                          error = null;
                        }),
                  child: Text(
                    registering
                        ? 'มีบัญชีแล้ว? เข้าสู่ระบบ'
                        : 'ยังไม่มีบัญชี? สมัครสมาชิก',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({
    required this.items,
    required this.onOpen,
    required this.onAdd,
    required this.onLogout,
    required this.user,
    required this.isDarkMode,
    required this.onThemeChanged,
    super.key,
  });
  final List<WatchItem> items;
  final ValueChanged<WatchItem> onOpen;
  final VoidCallback onAdd;
  final VoidCallback onLogout;
  final Map<String, dynamic>? user;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  String query = '';
  MediaType? selectedType;

  List<WatchItem> get filtered {
    final source = widget.items.where(
      (item) =>
          item.title.toLowerCase().contains(query.trim().toLowerCase()) &&
          (selectedType == null || item.type == selectedType),
    );
    if (tab == 0) return source.toList();
    final status = WatchStatus.values[tab - 1];
    return source.where((item) => item.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['Home', 'Wishlist', 'Watching', 'Completed', 'Profile'];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(tab == 0 ? 'Watcha' : labels[tab]),
        actions: [
          IconButton(
            tooltip: 'โปรไฟล์',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => setState(() => tab = 4),
          ),
        ],
      ),
      body: tab == 4
          ? ProfileView(
              onLogout: widget.onLogout,
              user: widget.user,
              isDarkMode: widget.isDarkMode,
              onThemeChanged: widget.onThemeChanged,
            )
          : _content(),
      floatingActionButton: tab == 4
          ? null
          : FloatingActionButton(
              onPressed: widget.onAdd,
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Wishlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.live_tv_outlined),
            selectedIcon: Icon(Icons.live_tv),
            label: 'Watching',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Completed',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _content() {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              hintText: 'ค้นหาหนังหรือซีรีส์...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          if (tab == 0) ...[
            const SizedBox(height: 18),
            Row(
              children: WatchStatus.values.map((status) {
                final count = widget.items
                    .where((item) => item.status == status)
                    .length;
                return Expanded(
                  child: SummaryCard(label: statusLabel(status), count: count),
                );
              }).toList(),
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recently Added',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () => setState(() => tab = 1),
                  child: const Text('ดูทั้งหมด'),
                ),
              ],
            ),
          ],
          if (tab != 0) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('ทั้งหมด'),
                  selected: selectedType == null,
                  onSelected: (_) => setState(() => selectedType = null),
                ),
                FilterChip(
                  label: const Text('Movie'),
                  selected: selectedType == MediaType.movie,
                  onSelected: (_) => setState(
                    () => selectedType = selectedType == MediaType.movie
                        ? null
                        : MediaType.movie,
                  ),
                ),
                FilterChip(
                  label: const Text('Series'),
                  selected: selectedType == MediaType.series,
                  onSelected: (_) => setState(
                    () => selectedType = selectedType == MediaType.series
                        ? null
                        : MediaType.series,
                  ),
                ),
              ],
            ),
          ],
          if (filtered.isEmpty)
            const EmptyState()
          else if (tab == 0)
            ...filtered
                .take(5)
                .map(
                  (item) =>
                      RecentItem(item: item, onTap: () => widget.onOpen(item)),
                )
          else ...[
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 18,
                childAspectRatio: .62,
              ),
              itemBuilder: (_, index) => PosterCard(
                item: filtered[index],
                onTap: () => widget.onOpen(filtered[index]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({required this.label, required this.count, super.key});
  final String label;
  final int count;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(right: 8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Text('$count', style: Theme.of(context).textTheme.headlineSmall),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    ),
  );
}

class RecentItem extends StatelessWidget {
  const RecentItem({required this.item, required this.onTap, super.key});
  final WatchItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 6),
    onTap: onTap,
    leading: Poster(item: item, width: 62, height: 86),
    title: Text(
      item.title,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      '${typeLabel(item.type)} • ${item.year ?? '-'}\n${item.note.isEmpty ? 'ไม่มีบันทึก' : item.note}',
    ),
    trailing: Chip(
      label: Text(
        statusLabel(item.status),
        style: const TextStyle(fontSize: 11),
      ),
    ),
  );
}

class PosterCard extends StatelessWidget {
  const PosterCard({required this.item, required this.onTap, super.key});
  final WatchItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Poster(item: item)),
        const SizedBox(height: 7),
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          '${item.year ?? '-'} • ${statusLabel(item.status)}',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
      ],
    ),
  );
}

class Poster extends StatelessWidget {
  const Poster({required this.item, this.width, this.height, super.key});
  final WatchItem item;
  final double? width;
  final double? height;
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: const Color(0xff282433),
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 42,
          color: Colors.deepPurple.shade200,
        ),
      ),
    );
    final posterUrl = item.posterUrl?.trim();
    final posterUri = posterUrl == null ? null : Uri.tryParse(posterUrl);
    final hasValidPoster =
        posterUri != null &&
        (posterUri.scheme == 'http' || posterUri.scheme == 'https') &&
        posterUri.host.isNotEmpty;
    final image = !hasValidPoster
        ? fallback
        : Image.network(
            posterUri.toString(),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallback,
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: SizedBox(width: width, height: height, child: image),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 80),
    child: Column(
      children: [
        Icon(
          Icons.movie_filter_outlined,
          size: 56,
          color: Colors.grey.shade600,
        ),
        const SizedBox(height: 14),
        const Text('ยังไม่มีรายการในหมวดนี้'),
        Text(
          'ลองเพิ่มหนังหรือซีรีส์ที่อยากดู',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      ],
    ),
  );
}

class DetailPage extends StatefulWidget {
  const DetailPage({
    required this.item,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });
  final WatchItem item;
  final Future<void> Function() onChanged;
  final Future<WatchItem?> Function(WatchItem item) onEdit;
  final Future<void> Function() onDelete;
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late WatchItem item;

  @override
  void initState() {
    super.initState();
    item = widget.item;
  }

  Future<void> editItem() async {
    final updated = await widget.onEdit(item);
    if (updated != null && mounted) {
      setState(() => item = updated);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('รายละเอียด'),
      actions: [
        IconButton(onPressed: editItem, icon: const Icon(Icons.edit_outlined)),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Poster(item: item, height: 230),
        const SizedBox(height: 18),
        Text(
          item.title,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          '${typeLabel(item.type)} • ${item.year ?? '-'}',
          style: TextStyle(color: Colors.grey.shade400),
        ),
        if (item.watchUrl?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.tryParse(item.watchUrl!.trim());
              if (uri == null ||
                  (uri.scheme != 'http' && uri.scheme != 'https') ||
                  uri.host.isEmpty ||
                  !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ไม่สามารถเปิดลิงก์ได้')),
                  );
                }
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('เปิดลิงก์รับชม'),
          ),
        ],
        const SizedBox(height: 18),
        Text('สถานะการรับชม', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<WatchStatus>(
          segments: WatchStatus.values
              .map(
                (status) => ButtonSegment(
                  value: status,
                  label: Text(statusLabel(status)),
                ),
              )
              .toList(),
          selected: {item.status},
          onSelectionChanged: null,
        ),
        const SizedBox(height: 8),
        Text(
          'กดปุ่มดินสอด้านบนเพื่อเปลี่ยนสถานะ',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
        const Divider(height: 36),
        Text('คะแนนของคุณ', style: Theme.of(context).textTheme.titleMedium),
        Row(
          children: List.generate(
            5,
            (index) => Icon(
              index < (item.rating ?? 0) ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 28,
            ),
          ),
        ),
        Text(
          item.status == WatchStatus.completed
              ? '${item.rating ?? 0}/5'
              : 'แสดงเมื่อสถานะเป็น Completed',
          style: TextStyle(color: Colors.grey.shade400),
        ),
        const SizedBox(height: 18),
        Text('หมายเหตุ', style: Theme.of(context).textTheme.titleMedium),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(item.note.isEmpty ? 'ยังไม่มีบันทึก' : item.note),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('ลบรายการนี้?'),
                content: const Text('ข้อมูลจะถูกลบออกจากรายการของคุณ'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('ยกเลิก'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('ลบ'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await widget.onDelete();
              if (!context.mounted) return;
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('ลบรายการ'),
        ),
      ],
    ),
  );
}

class EditItemPage extends StatefulWidget {
  const EditItemPage({this.item, super.key});
  final WatchItem? item;
  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  late final TextEditingController title;
  late final TextEditingController year;
  late final TextEditingController note;
  late final TextEditingController posterUrl;
  late final TextEditingController watchUrl;
  late MediaType type;
  late WatchStatus status;
  int? rating;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    title = TextEditingController(text: item?.title);
    year = TextEditingController(text: item?.year?.toString());
    note = TextEditingController(text: item?.note);
    posterUrl = TextEditingController(text: item?.posterUrl);
    watchUrl = TextEditingController(text: item?.watchUrl);
    type = item?.type ?? MediaType.movie;
    status = item?.status ?? WatchStatus.wishlist;
    rating = item?.rating;
  }

  @override
  void dispose() {
    title.dispose();
    year.dispose();
    note.dispose();
    posterUrl.dispose();
    watchUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.item == null ? 'เพิ่มรายการใหม่' : 'แก้ไขรายการ'),
    ),
    body: Form(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: title,
            decoration: const InputDecoration(labelText: 'ชื่อหนัง / ซีรีส์ *'),
          ),
          const SizedBox(height: 16),
          Text('ประเภท *', style: TextStyle(color: Colors.grey.shade400)),
          const SizedBox(height: 7),
          SegmentedButton<MediaType>(
            segments: const [
              ButtonSegment(value: MediaType.movie, label: Text('Movie')),
              ButtonSegment(value: MediaType.series, label: Text('Series')),
            ],
            selected: {type},
            onSelectionChanged: (value) => setState(() => type = value.first),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: year,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'ปีที่ออกฉาย',
              hintText: 'YYYY',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<WatchStatus>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'สถานะการรับชม *'),
            items: WatchStatus.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(statusLabel(value)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  status = value;
                  if (status != WatchStatus.completed) rating = null;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Text(
            'คะแนน (เฉพาะดูจบแล้ว)',
            style: TextStyle(color: Colors.grey.shade400),
          ),
          Row(
            children: List.generate(
              5,
              (index) => IconButton(
                onPressed: status == WatchStatus.completed
                    ? () => setState(() => rating = index + 1)
                    : null,
                icon: Icon(
                  index < (rating ?? 0) ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
              ),
            ),
          ),
          TextFormField(
            controller: note,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'หมายเหตุ',
              hintText: 'เขียนบันทึกของคุณ...',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: posterUrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'URL โปสเตอร์',
              hintText: 'https://example.com/poster.jpg',
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: watchUrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'ลิงก์รับชม',
              hintText: 'https://example.com/watch',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              final parsedYear = int.tryParse(year.text);
              if (title.text.trim().isEmpty ||
                  (year.text.isNotEmpty &&
                      (parsedYear == null ||
                          parsedYear < 1888 ||
                          parsedYear > DateTime.now().year + 2))) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณาตรวจสอบชื่อและปีที่ออกฉาย'),
                  ),
                );
                return;
              }
              Navigator.pop(
                context,
                WatchItem(
                  id: widget.item?.id ?? 0,
                  title: title.text.trim(),
                  type: type,
                  year: parsedYear,
                  status: status,
                  rating: rating,
                  note: note.text.trim(),
                  posterUrl: posterUrl.text.trim().isEmpty
                      ? null
                      : posterUrl.text.trim(),
                  watchUrl: watchUrl.text.trim().isEmpty
                      ? null
                      : watchUrl.text.trim(),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Text('บันทึกรายการ'),
            ),
          ),
        ],
      ),
    ),
  );
}

class ProfileView extends StatelessWidget {
  const ProfileView({
    required this.onLogout,
    required this.user,
    required this.isDarkMode,
    required this.onThemeChanged,
    super.key,
  });
  final VoidCallback onLogout;
  final Map<String, dynamic>? user;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 42)),
      const SizedBox(height: 12),
      Center(
        child: Text(
          user?['name'] as String? ?? 'Watcha User',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      Center(
        child: Text(
          user?['email'] as String? ?? '',
          style: TextStyle(color: Colors.grey.shade400),
        ),
      ),
      const SizedBox(height: 30),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('ธีมมืด'),
              trailing: Switch(value: isDarkMode, onChanged: onThemeChanged),
            ),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('เกี่ยวกับ Watcha'),
              trailing: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: onLogout,
        icon: const Icon(Icons.logout),
        label: const Text('ออกจากระบบ'),
      ),
    ],
  );
}

String statusLabel(WatchStatus status) => switch (status) {
  WatchStatus.wishlist => 'Wishlist',
  WatchStatus.watching => 'Watching',
  WatchStatus.completed => 'Completed',
};
String typeLabel(MediaType type) =>
    type == MediaType.movie ? 'Movie' : 'Series';
