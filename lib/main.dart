import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _navy = Color(0xFF0D1B2A);
const _navy2 = Color(0xFF172D46);
const _cream = Color(0xFFF7F2E8);
const _gold = Color(0xFFD8B36A);
const _blue = Color(0xFF5E8FC6);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(QuranAzkarApp(prefs: prefs));
}

class QuranAzkarApp extends StatefulWidget {
  final SharedPreferences prefs;
  const QuranAzkarApp({super.key, required this.prefs});

  @override
  State<QuranAzkarApp> createState() => _QuranAzkarAppState();
}

class _QuranAzkarAppState extends State<QuranAzkarApp> {
  bool get dark => widget.prefs.getBool('dark') ?? false;

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: dark ? const Color(0xFF09131F) : _cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _gold,
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      textTheme: GoogleFonts.cairoTextTheme(),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'رفيق القرآن',
      theme: base,
      home: widget.prefs.getBool('onboardingDone') == true
          ? MainNavigationScreen(
              prefs: widget.prefs,
              onThemeChanged: () => setState(() {}),
            )
          : OnboardingScreen(prefs: widget.prefs, onFinished: () => setState(() {})),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final VoidCallback onFinished;
  const OnboardingScreen({super.key, required this.prefs, required this.onFinished});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController controller = PageController();
  int page = 0;
  final slides = const [
    ('رفيق القرآن', 'اقرأ وتدبر واجعل القرآن نورًا يرافق يومك', Icons.menu_book_rounded),
    ('كل عبادتك في مكان واحد', 'القرآن، الأذكار، مواقيت الصلاة، التسبيح والمفضلة', Icons.auto_awesome_rounded),
    ('ابدأ رحلتك بهدوء', 'تجربة عربية أنيقة صُممت لتساعدك على الاستمرار', Icons.nightlight_round),
  ];

  Future<void> finish() async {
    await widget.prefs.setBool('onboardingDone', true);
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _navy,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: finish,
                  child: const Text('تخطي', style: TextStyle(color: Colors.white70)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  itemCount: slides.length,
                  onPageChanged: (v) => setState(() => page = v),
                  itemBuilder: (_, i) {
                    final s = slides[i];
                    return Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [_gold, Color(0xFF8B6A35)]),
                              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 30)],
                            ),
                            child: Icon(s.$3, size: 88, color: _navy),
                          ),
                          const SizedBox(height: 42),
                          Text(s.$1, style: GoogleFonts.amiri(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 14),
                          Text(s.$2, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 16, height: 1.8, color: Colors.white70)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(slides.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(4),
                  width: i == page ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(color: i == page ? _gold : Colors.white24, borderRadius: BorderRadius.circular(20)),
                )),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 18, 28, 30),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: _navy),
                    onPressed: page == slides.length - 1 ? finish : () => controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut),
                    child: Text(page == slides.length - 1 ? 'ابدأ الآن' : 'التالي', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final VoidCallback onThemeChanged;
  const MainNavigationScreen({super.key, required this.prefs, required this.onThemeChanged});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(prefs: widget.prefs, onOpenTab: (v) => setState(() => index = v)),
      const SurahListScreen(),
      const AzkarScreen(),
      FavoritesScreen(prefs: widget.prefs),
      SettingsScreen(prefs: widget.prefs, onChanged: widget.onThemeChanged),
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: pages[index],
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 8))]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: 'الرئيسية', selected: index == 0, onTap: () => setState(() => index = 0)),
                _NavItem(icon: Icons.menu_book_rounded, label: 'القرآن', selected: index == 1, onTap: () => setState(() => index = 1)),
                _NavItem(icon: Icons.auto_awesome_rounded, label: 'الأذكار', selected: index == 2, onTap: () => setState(() => index = 2)),
                _NavItem(icon: Icons.bookmark_rounded, label: 'المفضلة', selected: index == 3, onTap: () => setState(() => index = 3)),
                _NavItem(icon: Icons.settings_rounded, label: 'الإعدادات', selected: index == 4, onTap: () => setState(() => index = 4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: onTap,
    child: SizedBox(width: 66, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: selected ? _gold : Colors.white60),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.cairo(fontSize: 9, color: selected ? _gold : Colors.white60)),
    ])),
  );
}

class IslamicHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  const IslamicHeader({super.key, required this.title, required this.subtitle, this.action});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(22, 52, 22, 28),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [_navy, _navy2], begin: Alignment.topRight, end: Alignment.bottomLeft),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.amiri(fontSize: 33, color: Colors.white, fontWeight: FontWeight.bold)),
        Text(subtitle, style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70)),
      ])),
      if (action != null) action!,
    ]),
  );
}

class HomeScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final ValueChanged<int> onOpenTab;
  const HomeScreen({super.key, required this.prefs, required this.onOpenTab});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final lastNumber = widget.prefs.getInt('lastSurahNumber');
    final lastName = widget.prefs.getString('lastSurahName');
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          IslamicHeader(
            title: 'السلام عليكم',
            subtitle: 'رفيقك اليومي للقرآن والذكر',
            action: Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.nightlight_round, color: _gold)),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (lastNumber != null) _ContinueCard(number: lastNumber, name: lastName ?? 'السورة', prefs: widget.prefs),
              const SizedBox(height: 18),
              _PrayerCard(),
              const SizedBox(height: 22),
              Text('خدمات رفيق القرآن', style: GoogleFonts.amiri(fontSize: 25, fontWeight: FontWeight.bold, color: _navy)),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _Feature(icon: Icons.menu_book_rounded, title: 'القرآن الكريم', subtitle: '114 سورة', onTap: () => widget.onOpenTab(1)),
                  _Feature(icon: Icons.auto_awesome_rounded, title: 'الأذكار', subtitle: 'صباح ومساء', onTap: () => widget.onOpenTab(2)),
                  _Feature(icon: Icons.timelapse_rounded, title: 'المسبحة', subtitle: 'سبّح الآن', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasbihScreen()))),
                  _Feature(icon: Icons.format_quote_rounded, title: 'حديث اليوم', subtitle: 'كلمة نور', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyHadithScreen()))),
                ],
              ),
              const SizedBox(height: 16),
              _HourlyReminderCard(prefs: widget.prefs),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _Feature({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: _gold, size: 30),
          const SizedBox(height: 7),
          Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: _navy, fontSize: 13)),
          Text(subtitle, style: GoogleFonts.cairo(color: Colors.black45, fontSize: 10)),
        ]),
      ),
    ),
  );
}

class _ContinueCard extends StatelessWidget {
  final int number;
  final String name;
  final SharedPreferences prefs;
  const _ContinueCard({required this.number, required this.name, required this.prefs});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [_navy, _navy2]), borderRadius: BorderRadius.circular(28)),
    child: Row(children: [
      const Icon(Icons.menu_book_rounded, color: _gold, size: 42),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('تابع قراءتك', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
        Text(name, style: GoogleFonts.amiri(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
      ])),
      IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahDetailScreen(number: number, name: name, prefs: prefs))), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _gold)),
    ]),
  );
}

class _PrayerCard extends StatefulWidget {
  @override
  State<_PrayerCard> createState() => _PrayerCardState();
}
class _PrayerCardState extends State<_PrayerCard> {
  Future<Map<String, String>>? future;
  @override void initState() { super.initState(); future = load(); }
  Future<Map<String, String>> load() async {
    final uri = Uri.parse('https://api.aladhan.com/v1/timingsByCity?city=Cairo&country=Egypt&method=5');
    final r = await http.get(uri).timeout(const Duration(seconds: 15));
    final data = jsonDecode(r.body);
    final t = Map<String, dynamic>.from(data['data']['timings']);
    return {'الفجر': '${t['Fajr']}'.split(' ')[0], 'الظهر': '${t['Dhuhr']}'.split(' ')[0], 'العصر': '${t['Asr']}'.split(' ')[0], 'المغرب': '${t['Maghrib']}'.split(' ')[0], 'العشاء': '${t['Isha']}'.split(' ')[0]};
  }
  @override Widget build(BuildContext context) => FutureBuilder<Map<String,String>>(
    future: future,
    builder: (_, s) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.mosque_rounded, color: _gold), const SizedBox(width: 8), Text('مواقيت الصلاة - القاهرة', style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold, color: _navy)), const Spacer(), IconButton(onPressed: () => setState(() => future = load()), icon: const Icon(Icons.refresh_rounded))]),
        if (s.hasError) Text('تعذر تحميل المواقيت الآن', style: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 11)) else if (!s.hasData) const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()) else Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: s.data!.entries.map((e) => Column(children: [Text(e.key, style: GoogleFonts.cairo(fontSize: 10, color: Colors.black54)), Text(e.value, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: _navy, fontSize: 12))])).toList()),
      ]),
    ),
  );
}

class _HourlyReminderCard extends StatefulWidget {
  final SharedPreferences prefs;
  const _HourlyReminderCard({required this.prefs});
  @override State<_HourlyReminderCard> createState() => _HourlyReminderCardState();
}
class _HourlyReminderCardState extends State<_HourlyReminderCard> {
  bool get enabled => widget.prefs.getBool('hourlyReminder') ?? true;
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: const Color(0xFFF1E5CB), borderRadius: BorderRadius.circular(24)),
    child: Row(children: [const Icon(Icons.favorite_rounded, color: _gold), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('تذكير بالصلاة على النبي ﷺ', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: _navy, fontSize: 12)), Text('يمكنك تشغيل التذكير من الإعدادات', style: GoogleFonts.cairo(fontSize: 10, color: Colors.black54))])), Switch(value: enabled, onChanged: (v) async { await widget.prefs.setBool('hourlyReminder', v); setState(() {}); })]),
  );
}

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  List<dynamic> all = [];
  List<dynamic> filtered = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await http
          .get(Uri.parse('https://api.alquran.cloud/v1/surah'))
          .timeout(const Duration(seconds: 20));
      final data = jsonDecode(response.body);

      if (data['data'] is List) {
        all = List<dynamic>.from(data['data']);
        filtered = all;
      } else {
        error = 'تعذر تحميل السور';
      }
    } catch (_) {
      error = 'تحقق من الإنترنت ثم حاول مرة أخرى';
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  void search(String query) {
    final value = query.trim().toLowerCase();
    setState(() {
      filtered = value.isEmpty
          ? all
          : all
              .where(
                (surah) =>
                    '${surah['name']} ${surah['englishName']} ${surah['number']}'
                        .toLowerCase()
                        .contains(value),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          IslamicHeader(
            title: 'القرآن الكريم',
            subtitle: 'اقرأ كتاب الله وتدبر آياته',
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'ابحث عن سورة...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(error!),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: load,
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final surah = filtered[index];
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  if (!context.mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SurahDetailScreen(
                                        number: surah['number'],
                                        name: '${surah['name']}',
                                        prefs: prefs,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(13),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _cream,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Text(
                                          '${surah['number']}',
                                          style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                            color: _navy,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${surah['name']}',
                                              style: GoogleFonts.amiri(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: _navy,
                                              ),
                                            ),
                                            Text(
                                              '${surah['revelationType'] == 'Meccan' ? 'مكية' : 'مدنية'} • ${surah['numberOfAyahs']} آية',
                                              style: GoogleFonts.cairo(
                                                fontSize: 10,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${surah['englishName']}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 9,
                                          color: _blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class SurahDetailScreen extends StatefulWidget {
  final int number;
  final String name;
  final SharedPreferences prefs;

  const SurahDetailScreen({
    super.key,
    required this.number,
    required this.name,
    required this.prefs,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  late Future<List<dynamic>> future;
  double size = 29;
  bool playing = false;
  late AudioPlayer player;

  bool get favorite => widget.prefs
          .getStringList('favorites')
          ?.contains('${widget.number}|${widget.name}') ??
      false;

  @override
  void initState() {
    super.initState();
    widget.prefs.setInt('lastSurahNumber', widget.number);
    widget.prefs.setString('lastSurahName', widget.name);
    future = load();
    player = AudioPlayer();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<List<dynamic>> load() async {
    final response = await http
        .get(
          Uri.parse(
            'https://api.alquran.cloud/v1/surah/${widget.number}/quran-uthmani',
          ),
        )
        .timeout(const Duration(seconds: 20));
    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['data']?['ayahs'] is! List) {
      throw Exception('تعذر تحميل السورة');
    }

    return List<dynamic>.from(data['data']['ayahs']);
  }

  Future<void> toggleFav() async {
    final key = '${widget.number}|${widget.name}';
    final list = [...(widget.prefs.getStringList('favorites') ?? [])];

    if (favorite) {
      list.remove(key);
    } else {
      list.add(key);
    }

    await widget.prefs.setStringList(
      'favorites',
      list.map((item) => item.toString()).toList(),
    );
    setState(() {});
  }

  Future<void> toggleAudio() async {
    if (playing) {
      await player.stop();
      if (mounted) setState(() => playing = false);
      return;
    }

    final number = widget.number.toString().padLeft(3, '0');
    await player.play(
      UrlSource(
        'https://download.quranicaudio.com/quran/muhammad_siddeeq_al-minshaawee/murattal/$number.mp3',
      ),
    );

    if (mounted) setState(() => playing = true);
  }

  void fontSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'حجم الخط',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: size,
              min: 20,
              max: 42,
              divisions: 11,
              onChanged: (value) => setState(() => size = value),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _cream,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_navy, _navy2]),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            widget.name,
                            style: GoogleFonts.amiri(
                              fontSize: 31,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'سورة من القرآن الكريم',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: fontSheet,
                      icon: const Icon(Icons.text_fields, color: _gold),
                    ),
                    IconButton(
                      onPressed: toggleFav,
                      icon: Icon(
                        favorite ? Icons.bookmark : Icons.bookmark_border,
                        color: _gold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: future,
                  builder: (_, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: ElevatedButton(
                          onPressed: () => setState(() => future = load()),
                          child: const Text('إعادة المحاولة'),
                        ),
                      );
                    }

                    final ayahs = snapshot.data ?? [];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: _gold.withValues(alpha: .7),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                                  style: GoogleFonts.amiri(
                                    fontSize: 28,
                                    color: _navy,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    children: ayahs
                                        .map(
                                          (ayah) => TextSpan(
                                            text:
                                                '${ayah['text']} ﴿${ayah['numberInSurah']}﴾ ',
                                            style: GoogleFonts.amiri(
                                              fontSize: size,
                                              height: 2.05,
                                              color: _navy,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 90),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 14),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: _cream,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: _navy),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الشيخ محمد صديق المنشاوي',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: _navy,
                            ),
                          ),
                          Text(
                            'استماع للسورة كاملة',
                            style: GoogleFonts.cairo(
                              fontSize: 9,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: toggleAudio,
                      icon: Icon(
                        playing
                            ? Icons.stop_circle_rounded
                            : Icons.play_circle_fill_rounded,
                        size: 46,
                        color: _navy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AzkarScreen extends StatelessWidget {
  const AzkarScreen({super.key});

  // مجموعة موسعة من الأذكار اليومية داخل التطبيق حتى لا تكون الصفحة تجريبية.
  static const Map<String, List<String>> data = {
    'أذكار الصباح': [
      'أصبحنا وأصبح الملك لله والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
      'اللهم بك أصبحنا وبك أمسينا وبك نحيا وبك نموت وإليك النشور.',
      'رضيت بالله ربًا، وبالإسلام دينًا، وبمحمد ﷺ نبيًا.',
      'اللهم إني أصبحت أشهدك وأشهد حملة عرشك وملائكتك وجميع خلقك أنك أنت الله لا إله إلا أنت وحدك لا شريك لك وأن محمدًا عبدك ورسولك.',
      'اللهم ما أصبح بي من نعمة أو بأحد من خلقك فمنك وحدك لا شريك لك، فلك الحمد ولك الشكر.',
      'حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم.',
      'بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم.',
      'أعوذ بكلمات الله التامات من شر ما خلق.',
      'سبحان الله وبحمده.',
      'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
      'اللهم إني أسألك العفو والعافية في الدنيا والآخرة.',
      'يا حي يا قيوم برحمتك أستغيث، أصلح لي شأني كله ولا تكلني إلى نفسي طرفة عين.',
      'أصبحنا على فطرة الإسلام، وعلى كلمة الإخلاص، وعلى دين نبينا محمد ﷺ، وعلى ملة أبينا إبراهيم حنيفًا مسلمًا وما كان من المشركين.',
    ],
    'أذكار المساء': [
      'أمسينا وأمسى الملك لله والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
      'اللهم بك أمسينا وبك أصبحنا وبك نحيا وبك نموت وإليك المصير.',
      'رضيت بالله ربًا، وبالإسلام دينًا، وبمحمد ﷺ نبيًا.',
      'اللهم إني أمسيت أشهدك وأشهد حملة عرشك وملائكتك وجميع خلقك أنك أنت الله لا إله إلا أنت وحدك لا شريك لك وأن محمدًا عبدك ورسولك.',
      'اللهم ما أمسى بي من نعمة أو بأحد من خلقك فمنك وحدك لا شريك لك، فلك الحمد ولك الشكر.',
      'حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم.',
      'بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم.',
      'أعوذ بكلمات الله التامات من شر ما خلق.',
      'سبحان الله وبحمده.',
      'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
      'اللهم إني أسألك العفو والعافية في الدنيا والآخرة.',
      'أمسينا على فطرة الإسلام، وعلى كلمة الإخلاص، وعلى دين نبينا محمد ﷺ، وعلى ملة أبينا إبراهيم حنيفًا مسلمًا وما كان من المشركين.',
    ],
    'أذكار بعد الصلاة': [
      'أستغفر الله.',
      'اللهم أنت السلام ومنك السلام تباركت يا ذا الجلال والإكرام.',
      'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
      'اللهم لا مانع لما أعطيت ولا معطي لما منعت ولا ينفع ذا الجد منك الجد.',
      'سبحان الله.',
      'الحمد لله.',
      'الله أكبر.',
      'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
    ],
    'أذكار النوم': [
      'باسمك اللهم أموت وأحيا.',
      'اللهم أسلمت نفسي إليك، وفوضت أمري إليك، ووجهت وجهي إليك، وألجأت ظهري إليك، رغبة ورهبة إليك، لا ملجأ ولا منجى منك إلا إليك.',
      'باسمك ربي وضعت جنبي وبك أرفعه، فإن أمسكت نفسي فارحمها وإن أرسلتها فاحفظها بما تحفظ به عبادك الصالحين.',
      'سبحان الله.',
      'الحمد لله.',
      'الله أكبر.',
      'آية الكرسي.',
      'الإخلاص والفلق والناس.',
    ],
    'أذكار الاستيقاظ': [
      'الحمد لله الذي أحيانا بعدما أماتنا وإليه النشور.',
      'الحمد لله الذي عافاني في جسدي ورد علي روحي وأذن لي بذكره.',
      'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
    ],
    'أذكار دخول المنزل والخروج منه': [
      'بسم الله ولجنا وبسم الله خرجنا وعلى ربنا توكلنا.',
      'اللهم إني أعوذ بك أن أضل أو أزل أو أظلم أو أُظلم أو أجهل أو يُجهل علي.',
      'بسم الله، توكلت على الله، ولا حول ولا قوة إلا بالله.',
    ],
    'أذكار الطعام': [
      'بسم الله.',
      'الحمد لله الذي أطعمني هذا ورزقنيه من غير حول مني ولا قوة.',
      'الحمد لله حمدًا كثيرًا طيبًا مباركًا فيه، غير مكفي ولا مودع ولا مستغنى عنه ربنا.',
    ],
    'أذكار المسجد': [
      'اللهم افتح لي أبواب رحمتك.',
      'اللهم إني أسألك من فضلك.',
      'أعوذ بالله العظيم وبوجهه الكريم وسلطانه القديم من الشيطان الرجيم.',
    ],
    'أدعية جامعة': [
      'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار.',
      'ربنا لا تؤاخذنا إن نسينا أو أخطأنا.',
      'ربنا أفرغ علينا صبرًا وثبت أقدامنا.',
      'رب اشرح لي صدري ويسر لي أمري.',
      'رب زدني علمًا.',
      'اللهم إنك عفو كريم تحب العفو فاعف عنا.',
      'اللهم إني أسألك الهدى والتقى والعفاف والغنى.',
      'اللهم أصلح لي ديني الذي هو عصمة أمري، وأصلح لي دنياي التي فيها معاشي، وأصلح لي آخرتي التي إليها معادي.',
      'يا مقلب القلوب ثبت قلبي على دينك.',
      'اللهم أعني على ذكرك وشكرك وحسن عبادتك.',
    ],
    'أدعية الكرب والهم': [
      'لا إله إلا أنت سبحانك إني كنت من الظالمين.',
      'حسبي الله ونعم الوكيل.',
      'لا حول ولا قوة إلا بالله.',
      'اللهم رحمتك أرجو فلا تكلني إلى نفسي طرفة عين.',
      'يا حي يا قيوم برحمتك أستغيث.',
    ],
  };

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: [
            IslamicHeader(
              title: 'الأذكار',
              subtitle: 'أذكار يومية متنوعة لتبقى قريبًا من الله',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: data.entries
                    .map((entry) => _ZikrCategory(
                          title: entry.key,
                          items: entry.value,
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      );
}

class _ZikrCategory extends StatelessWidget {
  final String title;
  final List<String> items;

  const _ZikrCategory({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ExpansionTile(
          leading: const Icon(Icons.auto_awesome_rounded, color: _gold),
          title: Text(
            title,
            style: GoogleFonts.amiri(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          children: items.map((item) => _ZikrItem(text: item)).toList(),
        ),
      );
}

class _ZikrItem extends StatefulWidget {
  final String text;
  const _ZikrItem({required this.text});

  @override
  State<_ZikrItem> createState() => _ZikrItemState();
}

class _ZikrItemState extends State<_ZikrItem> {
  int count = 0;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        child: InkWell(
          onTap: () => setState(() => count++),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    height: 1.8,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'عدد التكرار: $count',
                  style: GoogleFonts.cairo(fontSize: 10, color: _gold),
                ),
              ],
            ),
          ),
        ),
      );
}

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int count = 0;
  String phrase = 'سبحان الله';
  final phrases = [
    'سبحان الله',
    'الحمد لله',
    'الله أكبر',
    'لا إله إلا الله',
    'أستغفر الله',
  ];

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text('المسبحة', style: GoogleFonts.amiri(fontSize: 26)),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                DropdownButton<String>(
                  value: phrase,
                  isExpanded: true,
                  items: phrases
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => phrase = value ?? phrase),
                ),
                const Spacer(),
                Text(
                  phrase,
                  style: GoogleFonts.amiri(fontSize: 36, color: _navy),
                ),
                const SizedBox(height: 25),
                GestureDetector(
                  onTap: () => setState(() => count++),
                  child: Container(
                    width: 230,
                    height: 230,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [_navy, _navy2]),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 24),
                      ],
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.cairo(
                        fontSize: 56,
                        color: _gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'اضغط على الدائرة للتسبيح',
                  style: GoogleFonts.cairo(color: Colors.black54),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => count = 0),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة الضبط'),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
}

class DailyHadithScreen extends StatefulWidget { const DailyHadithScreen({super.key}); @override State<DailyHadithScreen> createState()=>_DailyHadithScreenState(); }
class _DailyHadithScreenState extends State<DailyHadithScreen>{int i=0;final h=const [('إنما الأعمال بالنيات، وإنما لكل امرئ ما نوى.','متفق عليه'),('من كان يؤمن بالله واليوم الآخر فليقل خيرًا أو ليصمت.','رواه البخاري ومسلم'),('خيركم من تعلم القرآن وعلمه.','رواه البخاري'),('لا يؤمن أحدكم حتى يحب لأخيه ما يحب لنفسه.','متفق عليه')];@override Widget build(BuildContext context)=>Scaffold(body:Column(children:[IslamicHeader(title:'حديث اليوم',subtitle:'كلمة نور ترافق يومك'),Expanded(child:Center(child:Padding(padding:const EdgeInsets.all(22),child:Container(width:double.infinity,padding:const EdgeInsets.all(28),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(30)),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.format_quote_rounded,size:56,color:_gold),Text(h[i].$1,textAlign:TextAlign.center,style:GoogleFonts.amiri(fontSize:29,height:1.8,color:_navy)),const SizedBox(height:12),Text(h[i].$2,style:GoogleFonts.cairo(fontSize:11,color:Colors.black54)),const SizedBox(height:20),ElevatedButton.icon(style:ElevatedButton.styleFrom(backgroundColor:_navy,foregroundColor:Colors.white),onPressed:()=>setState(()=>i=(i+1)%h.length),icon:const Icon(Icons.refresh),label:const Text('حديث آخر'))])))))]));}

class FavoritesScreen extends StatefulWidget { final SharedPreferences prefs; const FavoritesScreen({super.key,required this.prefs}); @override State<FavoritesScreen> createState()=>_FavoritesScreenState(); }
class _FavoritesScreenState extends State<FavoritesScreen>{@override Widget build(BuildContext context){final list=widget.prefs.getStringList('favorites')??[];return Scaffold(body:Column(children:[IslamicHeader(title:'المفضلة',subtitle:'السور التي اخترتها للعودة إليها سريعًا'),Expanded(child:list.isEmpty?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.bookmark_border_rounded,size:60,color:_gold),const SizedBox(height:10),Text('لا توجد سور في المفضلة بعد',style:GoogleFonts.cairo(color:Colors.black54))])):ListView.builder(padding:const EdgeInsets.all(16),itemCount:list.length,itemBuilder:(_,i){final p=list[i].split('|');return Card(child:ListTile(leading:CircleAvatar(backgroundColor:_cream,child:Text(p[0])),title:Text(p.length>1?p[1]:'سورة',style:GoogleFonts.amiri(fontSize:23,color:_navy)),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()async{list.removeAt(i);await widget.prefs.setStringList('favorites',list);setState((){});}),onTap:(){if(p.length>1)Navigator.push(context,MaterialPageRoute(builder:(_)=>SurahDetailScreen(number:int.parse(p[0]),name:p[1],prefs:widget.prefs)));}));}))]));}}

class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final VoidCallback onChanged;
  const SettingsScreen({super.key, required this.prefs, required this.onChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool get dark => widget.prefs.getBool('dark') ?? false;
  bool get hourly => widget.prefs.getBool('hourlyReminder') ?? true;

  Future<void> setBool(String key, bool value) async {
    await widget.prefs.setBool(key, value);
    if (mounted) setState(() {});
    widget.onChanged();
  }

  void open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
      if (mounted) setState(() {});
      widget.onChanged();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: [
            IslamicHeader(title: 'الإعدادات العامة', subtitle: 'تحكم في تجربة رفيق القرآن بالطريقة التي تناسبك'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  _SettingsSection('المظهر والتجربة'),
                  _SettingTile(
                    icon: Icons.dark_mode_rounded,
                    title: 'الوضع الداكن',
                    subtitle: 'تغيير ألوان التطبيق',
                    value: dark,
                    onChanged: (v) => setBool('dark', v),
                  ),
                  _SettingsButton(
                    icon: Icons.translate_rounded,
                    title: 'اللغة',
                    subtitle: 'اختيار لغة واجهة التطبيق',
                    onTap: () => open(AppLanguageScreen(prefs: widget.prefs)),
                  ),
                  _SettingsButton(
                    icon: Icons.format_size_rounded,
                    title: 'حجم خط القرآن',
                    subtitle: 'تكبير أو تصغير خط القراءة',
                    onTap: () => open(QuranReadingSettingsScreen(prefs: widget.prefs)),
                  ),
                  const SizedBox(height: 14),
                  _SettingsSection('الصلاة والأذان'),
                  _SettingsButton(
                    icon: Icons.mosque_rounded,
                    title: 'مواقيت الصلاة والأذان',
                    subtitle: 'التنبيهات، طريقة الحساب وصوت الأذان',
                    onTap: () => open(PrayerAdhanSettingsScreen(prefs: widget.prefs)),
                  ),
                  const SizedBox(height: 14),
                  _SettingsSection('الأذكار والتنبيهات'),
                  _SettingsButton(
                    icon: Icons.auto_stories_rounded,
                    title: 'إعدادات الأذكار',
                    subtitle: 'الصباح والمساء والنوم والأذكار العائمة',
                    onTap: () => open(AzkarSettingsScreen(prefs: widget.prefs)),
                  ),
                  _SettingTile(
                    icon: Icons.favorite_rounded,
                    title: 'تذكير بالصلاة على النبي ﷺ',
                    subtitle: 'تفعيل التذكير داخل التطبيق',
                    value: hourly,
                    onChanged: (v) => setBool('hourlyReminder', v),
                  ),
                  _SettingsButton(
                    icon: Icons.notifications_active_rounded,
                    title: 'إعدادات التنبيهات المستمرة',
                    subtitle: 'الحديث اليومي والجمعة والتنبيهات العامة',
                    onTap: () => open(NotificationSettingsScreen(prefs: widget.prefs)),
                  ),
                  const SizedBox(height: 14),
                  _SettingsSection('المحتوى والبيانات'),
                  _SettingsButton(
                    icon: Icons.favorite_border_rounded,
                    title: 'المفضلة والتقدم',
                    subtitle: 'إدارة السور المحفوظة وآخر قراءة',
                    onTap: () => open(FavoritesScreen(prefs: widget.prefs)),
                  ),
                  _SettingsButton(
                    icon: Icons.delete_sweep_rounded,
                    title: 'مسح بيانات التطبيق',
                    subtitle: 'حذف المفضلة والتفضيلات المحفوظة',
                    onTap: () => _confirmClear(),
                  ),
                  const SizedBox(height: 14),
                  _SettingsSection('حول التطبيق'),
                  _SettingsButton(
                    icon: Icons.star_rate_rounded,
                    title: 'قيّم التطبيق',
                    subtitle: 'شاركنا رأيك لتطوير رفيق القرآن',
                    onTap: () => _snack('شكراً لدعمك ❤️ سيتم ربط صفحة التقييم بالمتجر عند النشر.'),
                  ),
                  _SettingsButton(
                    icon: Icons.info_outline_rounded,
                    title: 'عن التطبيق',
                    subtitle: 'رفيق القرآن • الإصدار 2.1.0',
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'رفيق القرآن',
                      applicationVersion: '2.1.0',
                      children: [
                        Text('تطبيق عربي يجمع القرآن الكريم والأذكار ومواقيت الصلاة والتسبيح والحديث اليومي في تجربة واحدة.', style: GoogleFonts.cairo()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('مسح البيانات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('سيتم حذف المفضلة والإعدادات المحفوظة داخل التطبيق.', style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('مسح')),
        ],
      ),
    );
    if (ok == true) {
      await widget.prefs.clear();
      await widget.prefs.setBool('onboardingDone', true);
      if (mounted) {
        setState(() {});
        widget.onChanged();
        _snack('تم مسح البيانات المحفوظة');
      }
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text, style: GoogleFonts.cairo())));
}

class PrayerAdhanSettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const PrayerAdhanSettingsScreen({super.key, required this.prefs});

  @override
  State<PrayerAdhanSettingsScreen> createState() => _PrayerAdhanSettingsScreenState();
}

class _PrayerAdhanSettingsScreenState extends State<PrayerAdhanSettingsScreen> {
  final AudioPlayer _adhanPlayer = AudioPlayer();

  bool get prayerNotifications => widget.prefs.getBool('prayerNotifications') ?? true;
  bool get adhanEnabled => widget.prefs.getBool('adhanEnabled') ?? true;
  bool get preReminder => widget.prefs.getBool('prePrayerReminder') ?? true;
  int get reminderMinutes => widget.prefs.getInt('prePrayerMinutes') ?? 10;
  String get voiceId => widget.prefs.getString('adhanVoiceId') ?? 'adhan_short';
  String get method => widget.prefs.getString('prayerMethod') ?? 'الهيئة المصرية العامة للمساحة';

  final List<Map<String, String>> _fallbackVoices = const [
    {
      'id': 'adhan_short',
      'name': 'أذان قصير',
      'url': 'https://upload.wikimedia.org/wikipedia/commons/e/e7/Adhan.ogg',
    },
    {
      'id': 'beautiful_adhan',
      'name': 'أذان جميل',
      'url': 'https://upload.wikimedia.org/wikipedia/commons/b/b0/Beautiful_adhan.ogg',
    },
    {
      'id': 'adhan_public_domain',
      'name': 'أذان من المدينة',
      'url': 'https://upload.wikimedia.org/wikipedia/commons/1/1f/Oraci%C3%B3n_Al-Azzan.ogg',
    },
  ];

  late List<Map<String, String>> _voices;
  bool _loadingVoices = true;
  bool _playing = false;

  final methods = const [
    'الهيئة المصرية العامة للمساحة',
    'رابطة العالم الإسلامي',
    'أم القرى',
  ];

  @override
  void initState() {
    super.initState();
    _voices = List<Map<String, String>>.from(_fallbackVoices);
    _loadVoices();
    _adhanPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  Future<void> _loadVoices() async {
    try {
      final raw = await services.rootBundle.loadString('assets/data/adhan_voices.json');
      final decoded = jsonDecode(raw);
      final items = decoded is Map<String, dynamic> ? decoded['voices'] : null;
      if (items is List) {
        final loaded = items
            .whereType<Map>()
            .map((item) => <String, String>{
                  'id': '${item['id'] ?? ''}',
                  'name': '${item['name'] ?? ''}',
                  'url': '${item['url'] ?? ''}',
                })
            .where((item) => item['id']!.isNotEmpty && item['name']!.isNotEmpty && item['url']!.isNotEmpty)
            .toList();
        if (loaded.isNotEmpty && mounted) {
          setState(() {
            _voices = loaded;
            _loadingVoices = false;
          });
          return;
        }
      }
    } catch (_) {
      // The built-in fallback keeps the screen usable if the JSON is unavailable.
    }
    if (mounted) setState(() => _loadingVoices = false);
  }

  String voiceName(String id) {
    for (final voice in _voices) {
      if (voice['id'] == id) return voice['name']!;
    }
    return _voices.first['name']!;
  }

  String normalizedVoiceId() {
    final saved = widget.prefs.getString('adhanVoiceId');
    if (saved != null && _voices.any((v) => v['id'] == saved)) return saved;

    // Migrate the old Arabic-label preference used by previous versions.
    final old = widget.prefs.getString('adhanVoice');
    if (old != null) {
      final match = _voices.where((v) => v['name'] == old).toList();
      if (match.isNotEmpty) return match.first['id']!;
    }
    return _voices.first['id']!;
  }

  Future<void> setBool(String key, bool value) async {
    await widget.prefs.setBool(key, value);
    if (mounted) setState(() {});
  }

  Future<void> setString(String key, String value) async {
    await widget.prefs.setString(key, value);
    if (mounted) setState(() {});
  }

  Future<void> setInt(String key, int value) async {
    await widget.prefs.setInt(key, value);
    if (mounted) setState(() {});
  }

  Future<void> selectVoice(String id) async {
    await widget.prefs.setString('adhanVoiceId', id);
    await widget.prefs.setString('adhanVoice', voiceName(id));
    if (mounted) setState(() {});
  }

  Future<void> previewAdhan() async {
    final id = normalizedVoiceId();
    final selected = _voices.firstWhere(
      (voice) => voice['id'] == id,
      orElse: () => _voices.first,
    );

    try {
      await _adhanPlayer.stop();
      await _adhanPlayer.setReleaseMode(ReleaseMode.stop);
      await _adhanPlayer.play(UrlSource(selected['url']!));
      if (mounted) setState(() => _playing = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تشغيل صوت الأذان. تأكد من اتصال الإنترنت ثم حاول مرة أخرى.',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
    }
  }

  Future<void> stopAdhan() async {
    await _adhanPlayer.stop();
    if (mounted) setState(() => _playing = false);
  }

  @override
  void dispose() {
    _adhanPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedVoiceId = normalizedVoiceId();

    return Scaffold(
      body: Column(
        children: [
          IslamicHeader(
            title: 'مواقيت الصلاة والأذان',
            subtitle: 'خصص تنبيهات الصلاة وصوت الأذان',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                _SettingTile(
                  icon: Icons.notifications_active_rounded,
                  title: 'تفعيل تنبيهات الصلاة',
                  subtitle: 'إظهار تنبيه عند دخول وقت الصلاة',
                  value: prayerNotifications,
                  onChanged: (v) => setBool('prayerNotifications', v),
                ),
                _SettingTile(
                  icon: Icons.volume_up_rounded,
                  title: 'تشغيل الأذان',
                  subtitle: 'تشغيل صوت الأذان عند التنبيه',
                  value: adhanEnabled,
                  onChanged: (v) => setBool('adhanEnabled', v),
                ),
                _SettingTile(
                  icon: Icons.alarm_rounded,
                  title: 'تنبيه قبل الصلاة',
                  subtitle: 'تذكير قبل دخول وقت الصلاة',
                  value: preReminder,
                  onChanged: (v) => setBool('prePrayerReminder', v),
                ),
                if (preReminder)
                  _ChoiceCard<int>(
                    icon: Icons.schedule_rounded,
                    title: 'موعد التذكير',
                    value: reminderMinutes,
                    values: const [5, 10, 15, 20],
                    label: (v) => 'قبل الصلاة بـ $v دقائق',
                    onChanged: (v) => setInt('prePrayerMinutes', v),
                  ),
                if (_loadingVoices)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text('جاري تحميل أصوات الأذان...', style: GoogleFonts.cairo(fontSize: 12, color: _navy)),
                      ],
                    ),
                  ),
                _ChoiceCard<String>(
                  icon: Icons.record_voice_over_rounded,
                  title: 'صوت الأذان',
                  value: selectedVoiceId,
                  values: _voices.map((v) => v['id']!).toList(),
                  label: voiceName,
                  onChanged: selectVoice,
                ),
                _SettingsButton(
                  icon: _playing ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded,
                  title: _playing ? 'إيقاف الأذان' : 'تجربة صوت الأذان',
                  subtitle: 'الصوت المختار: ${voiceName(selectedVoiceId)}',
                  onTap: _playing ? stopAdhan : previewAdhan,
                ),
                _ChoiceCard<String>(
                  icon: Icons.calculate_rounded,
                  title: 'طريقة حساب المواقيت',
                  value: method,
                  values: methods,
                  label: (v) => v,
                  onChanged: (v) => setString('prayerMethod', v),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'أصوات الأذان في هذه النسخة مصدرها ملفات متاحة للاستخدام العام، ويحتاج تشغيلها إلى اتصال بالإنترنت.',
                    style: GoogleFonts.cairo(fontSize: 10, color: _navy, height: 1.7),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AzkarSettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const AzkarSettingsScreen({super.key, required this.prefs});
  @override State<AzkarSettingsScreen> createState() => _AzkarSettingsScreenState();
}
class _AzkarSettingsScreenState extends State<AzkarSettingsScreen> {
  bool b(String k, bool d) => widget.prefs.getBool(k) ?? d;
  Future<void> setB(String k, bool v) async { await widget.prefs.setBool(k, v); if (mounted) setState(() {}); }
  Future<void> setS(String k, String v) async { await widget.prefs.setString(k, v); if (mounted) setState(() {}); }
  @override Widget build(BuildContext context) => Scaffold(body: Column(children: [
    IslamicHeader(title: 'إعدادات الأذكار', subtitle: 'خصص طريقة ظهور وتشغيل الأذكار'),
    Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16,16,16,40), children: [
      _SettingTile(icon: Icons.visibility_rounded, title: 'عرض شاشة الأذكار أثناء التنبيه', subtitle: 'فتح شاشة الذكر عند الضغط على التنبيه', value: b('azkarShowScreen', true), onChanged: (v)=>setB('azkarShowScreen',v)),
      _SettingTile(icon: Icons.play_circle_fill_rounded, title: 'التشغيل التلقائي للأذكار الصوتية', subtitle: 'تشغيل الصوت تلقائياً عند فتح الذكر', value: b('azkarAutoPlay', true), onChanged: (v)=>setB('azkarAutoPlay',v)),
      _SettingTile(icon: Icons.volume_up_rounded, title: 'تفعيل التنبيه الصوتي', subtitle: 'تشغيل صوت مع تذكيرات الأذكار', value: b('azkarSound', false), onChanged: (v)=>setB('azkarSound',v)),
      _SettingTile(icon: Icons.wb_sunny_rounded, title: 'تنبيه أذكار الصباح', subtitle: 'تفعيل التذكير الصباحي', value: b('morningAzkar', true), onChanged: (v)=>setB('morningAzkar',v)),
      _SettingTile(icon: Icons.nightlight_round, title: 'تنبيه أذكار المساء', subtitle: 'تفعيل التذكير المسائي', value: b('eveningAzkar', true), onChanged: (v)=>setB('eveningAzkar',v)),
      _SettingTile(icon: Icons.bedtime_rounded, title: 'تنبيه أذكار النوم', subtitle: 'تفعيل التذكير قبل النوم', value: b('sleepAzkar', false), onChanged: (v)=>setB('sleepAzkar',v)),
      _SettingTile(icon: Icons.bubble_chart_rounded, title: 'تفعيل الأذكار العائمة', subtitle: 'ظهور تذكيرات متفرقة حسب اختيارك', value: b('floatingAzkar', true), onChanged: (v)=>setB('floatingAzkar',v)),
      _ChoiceCard<String>(icon: Icons.tune_rounded, title: 'معدل ظهور الأذكار العائمة', value: widget.prefs.getString('floatingRate') ?? 'متوسط: 11-17 يومياً', values: const ['عالي: 20 فأكثر يومياً','متوسط: 11-17 يومياً','منخفض: 5-10 يومياً','نادر: 1-3 يومياً'], label: (v)=>v, onChanged:(v)=>setS('floatingRate',v)),
    ])),
  ]));
}

class NotificationSettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const NotificationSettingsScreen({super.key, required this.prefs});
  @override State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}
class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool b(String k, bool d) => widget.prefs.getBool(k) ?? d;
  Future<void> setB(String k, bool v) async { await widget.prefs.setBool(k,v); if(mounted)setState((){}); }
  @override Widget build(BuildContext context)=>Scaffold(body:Column(children:[
    IslamicHeader(title:'إعدادات التنبيهات',subtitle:'التحكم في الحديث اليومي وتذكيرات الجمعة'),
    Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(16,16,16,40),children:[
      _SettingTile(icon:Icons.menu_book_rounded,title:'الحديث اليومي',subtitle:'إرسال حديث قصير يومياً',value:b('dailyHadith',true),onChanged:(v)=>setB('dailyHadith',v)),
      _SettingTile(icon:Icons.favorite_rounded,title:'الصلاة على النبي ﷺ',subtitle:'تذكير دوري خلال اليوم',value:b('hourlyReminder',true),onChanged:(v)=>setB('hourlyReminder',v)),
      _SettingTile(icon:Icons.calendar_month_rounded,title:'تذكير يوم الجمعة',subtitle:'تنبيه خاص بيوم الجمعة',value:b('fridayReminder',true),onChanged:(v)=>setB('fridayReminder',v)),
      _SettingTile(icon:Icons.auto_stories_rounded,title:'تذكير سورة الكهف',subtitle:'تنبيه لقراءة سورة الكهف يوم الجمعة',value:b('kahfReminder',true),onChanged:(v)=>setB('kahfReminder',v)),
      _SettingTile(icon:Icons.vibration_rounded,title:'الاهتزاز مع التنبيهات',subtitle:'تشغيل اهتزاز عند وصول التنبيه',value:b('vibration',true),onChanged:(v)=>setB('vibration',v)),
    ])),
  ]));
}

class QuranReadingSettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const QuranReadingSettingsScreen({super.key, required this.prefs});
  @override State<QuranReadingSettingsScreen> createState()=>_QuranReadingSettingsScreenState();
}
class _QuranReadingSettingsScreenState extends State<QuranReadingSettingsScreen>{
  double get font => widget.prefs.getDouble('quranFontSize') ?? 24;
  bool get save => widget.prefs.getBool('saveLastReading') ?? true;
  Future<void> setFont(double v) async { await widget.prefs.setDouble('quranFontSize',v); if(mounted)setState((){}); }
  Future<void> setSave(bool v) async { await widget.prefs.setBool('saveLastReading',v); if(mounted)setState((){}); }
  @override Widget build(BuildContext context)=>Scaffold(body:Column(children:[
    IslamicHeader(title:'القرآن والقراءة',subtitle:'خصص تجربة القراءة داخل التطبيق'),
    Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(16,16,16,40),children:[
      Container(padding:const EdgeInsets.all(18),margin:const EdgeInsets.only(bottom:10),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('حجم خط القرآن',style:GoogleFonts.cairo(fontWeight:FontWeight.bold,color:_navy)),Slider(value:font,min:18,max:34,divisions:16,label:font.toStringAsFixed(0),onChanged:setFont),Text('بسم الله الرحمن الرحيم',textAlign:TextAlign.center,style:GoogleFonts.amiri(fontSize:font,color:_navy))])),
      _SettingTile(icon:Icons.bookmark_added_rounded,title:'حفظ آخر قراءة',subtitle:'العودة إلى آخر سورة تم فتحها',value:save,onChanged:setSave),
    ])),
  ]));
}

class AppLanguageScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const AppLanguageScreen({super.key, required this.prefs});

  @override
  State<AppLanguageScreen> createState() => _AppLanguageScreenState();
}

class _AppLanguageScreenState extends State<AppLanguageScreen> {
  String get lang => widget.prefs.getString('appLanguage') ?? 'العربية';

  Future<void> choose(String v) async {
    await widget.prefs.setString('appLanguage', v);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const languages = ['العربية', 'English'];

    return Scaffold(
      body: Column(
        children: [
          IslamicHeader(title: 'اللغة', subtitle: 'اختر لغة واجهة التطبيق'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                RadioGroup<String>(
                  groupValue: lang,
                  onChanged: (value) {
                    if (value != null) choose(value);
                  },
                  child: Column(
                    children: languages
                        .map(
                          (v) => RadioListTile<String>(
                            value: v,
                            title: Text(
                              v,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                color: _navy,
                              ),
                            ),
                            secondary: Icon(
                              v == 'العربية' ? Icons.translate : Icons.language,
                              color: _gold,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  const _SettingsSection(this.title);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 8), child: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: _gold, fontSize: 14)));
}

class _SettingsButton extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _SettingsButton({required this.icon,required this.title,required this.subtitle,required this.onTap});
  @override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(bottom:10),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:ListTile(onTap:onTap,leading:Icon(icon,color:_gold),title:Text(title,style:GoogleFonts.cairo(fontWeight:FontWeight.bold,color:_navy,fontSize:13)),subtitle:Text(subtitle,style:GoogleFonts.cairo(fontSize:10,color:Colors.black54)),trailing:const Icon(Icons.arrow_forward_ios_rounded,size:16,color:_gold)));
}

class _ChoiceCard<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final T value;
  final List<T> values;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  const _ChoiceCard({required this.icon,required this.title,required this.value,required this.values,required this.label,required this.onChanged});
  @override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.symmetric(horizontal:16,vertical:4),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:Row(children:[Icon(icon,color:_gold),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:GoogleFonts.cairo(fontWeight:FontWeight.bold,color:_navy,fontSize:13)),DropdownButton<T>(isExpanded:true,value:value,underline:const SizedBox(),items:values.map((v)=>DropdownMenuItem<T>(value:v,child:Text(label(v),style:GoogleFonts.cairo(fontSize:11)))).toList(),onChanged:(v){if(v!=null)onChanged(v);} )]))]));
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingTile({required this.icon,required this.title,required this.subtitle,required this.value,required this.onChanged});
  @override Widget build(BuildContext context)=>Container(margin:const EdgeInsets.only(bottom:10),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:SwitchListTile(secondary:Icon(icon,color:_gold),title:Text(title,style:GoogleFonts.cairo(fontWeight:FontWeight.bold,color:_navy,fontSize:13)),subtitle:Text(subtitle,style:GoogleFonts.cairo(fontSize:10,color:Colors.black54)),value:value,onChanged:onChanged));
}
