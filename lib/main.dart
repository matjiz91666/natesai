
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const navy = Color(0xFF06121F);
const navy2 = Color(0xFF0B1E31);
const card = Color(0xFF10263A);
const gold = Color(0xFFD8A23A);
const goldBright = Color(0xFFFFC857);
const green = Color(0xFF37B65C);
const red = Color(0xFFD64545);
const orange = Color(0xFFFF9F1C);
const muted = Color(0xFF9AA7B4);

void main() => runApp(const App());

String f(double v, [int d = 2]) => v.toStringAsFixed(d);
String f0(double v) => v.toStringAsFixed(0);

class Product {
  String id;
  String name;
  double dryWeightPerFeed;
  double secondsPerFeed;
  double growthRate;
  double finishedCasesNeeded;
  double caseWeight;
  double cookMinutes;
  bool favorite;

  Product({
    required this.id,
    required this.name,
    required this.dryWeightPerFeed,
    required this.secondsPerFeed,
    required this.growthRate,
    required this.finishedCasesNeeded,
    required this.caseWeight,
    required this.cookMinutes,
    this.favorite = false,
  });

  Product copyWith({
    String? id,
    String? name,
    double? dryWeightPerFeed,
    double? secondsPerFeed,
    double? growthRate,
    double? finishedCasesNeeded,
    double? caseWeight,
    double? cookMinutes,
    bool? favorite,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    dryWeightPerFeed: dryWeightPerFeed ?? this.dryWeightPerFeed,
    secondsPerFeed: secondsPerFeed ?? this.secondsPerFeed,
    growthRate: growthRate ?? this.growthRate,
    finishedCasesNeeded: finishedCasesNeeded ?? this.finishedCasesNeeded,
    caseWeight: caseWeight ?? this.caseWeight,
    cookMinutes: cookMinutes ?? this.cookMinutes,
    favorite: favorite ?? this.favorite,
  );

  Map<String, dynamic> toJson() => {
    "id": id, "name": name, "dryWeightPerFeed": dryWeightPerFeed,
    "secondsPerFeed": secondsPerFeed, "growthRate": growthRate,
    "finishedCasesNeeded": finishedCasesNeeded, "caseWeight": caseWeight,
    "cookMinutes": cookMinutes, "favorite": favorite,
  };

  static Product fromJson(Map<String, dynamic> j) => Product(
    id: j["id"] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: j["name"] ?? "Product",
    dryWeightPerFeed: (j["dryWeightPerFeed"] ?? 20).toDouble(),
    secondsPerFeed: (j["secondsPerFeed"] ?? 33).toDouble(),
    growthRate: (j["growthRate"] ?? 2.05).toDouble(),
    finishedCasesNeeded: (j["finishedCasesNeeded"] ?? 1000).toDouble(),
    caseWeight: (j["caseWeight"] ?? 20).toDouble(),
    cookMinutes: (j["cookMinutes"] ?? 13).toDouble(),
    favorite: j["favorite"] ?? false,
  );
}

class HourEntry {
  String id;
  String label;
  double actualCases;
  double actualDryLb;
  double actualCookedLb;
  double minutes;
  String note;

  HourEntry({
    required this.id,
    required this.label,
    required this.actualCases,
    required this.actualDryLb,
    required this.actualCookedLb,
    this.minutes = 60,
    this.note = "",
  });

  Map<String, dynamic> toJson() => {
    "id": id, "label": label, "actualCases": actualCases,
    "actualDryLb": actualDryLb, "actualCookedLb": actualCookedLb,
    "minutes": minutes, "note": note,
  };

  static HourEntry fromJson(Map<String, dynamic> j) => HourEntry(
    id: j["id"] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    label: j["label"] ?? "Hour",
    actualCases: (j["actualCases"] ?? 0).toDouble(),
    actualDryLb: (j["actualDryLb"] ?? 0).toDouble(),
    actualCookedLb: (j["actualCookedLb"] ?? 0).toDouble(),
    minutes: (j["minutes"] ?? 60).toDouble(),
    note: j["note"] ?? "",
  );
}

class Calc {
  final double dryLbMin, cookedLbMin, casesHour, dryHour, cookedHour, stopCases;
  Calc(this.dryLbMin, this.cookedLbMin, this.casesHour, this.dryHour, this.cookedHour, this.stopCases);
}

Calc calc(Product p) {
  final feedsMin = 60 / p.secondsPerFeed;
  final dryLbMin = feedsMin * p.dryWeightPerFeed;
  final cookedLbMin = dryLbMin * p.growthRate;
  final casesHour = (cookedLbMin * 60) / p.caseWeight;
  final dryHour = dryLbMin * 60;
  final cookedHour = cookedLbMin * 60;
  final flushCases = (cookedLbMin * p.cookMinutes) / p.caseWeight;
  final stopCases = (p.finishedCasesNeeded - flushCases).clamp(0, 999999).toDouble();
  return Calc(dryLbMin, cookedLbMin, casesHour, dryHour, cookedHour, stopCases);
}

class Store extends ChangeNotifier {
  List<Product> products = [];
  List<HourEntry> hours = [];
  Product? active;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final pRaw = sp.getString("products");
    final hRaw = sp.getString("hours");
    if (pRaw == null) {
      products = [
        Product(id: "1", name: "Penne Rigate", dryWeightPerFeed: 20, secondsPerFeed: 33, growthRate: 2.05, finishedCasesNeeded: 1000, caseWeight: 20, cookMinutes: 13, favorite: true),
      ];
    } else {
      products = (jsonDecode(pRaw) as List).map((e) => Product.fromJson(e)).toList();
    }
    if (hRaw != null) hours = (jsonDecode(hRaw) as List).map((e) => HourEntry.fromJson(e)).toList();
    active = products.isNotEmpty ? products.first : null;
    notifyListeners();
  }

  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString("products", jsonEncode(products.map((e) => e.toJson()).toList()));
    await sp.setString("hours", jsonEncode(hours.map((e) => e.toJson()).toList()));
  }

  Future<void> upsertProduct(Product p) async {
    final i = products.indexWhere((x) => x.id == p.id);
    if (i >= 0) products[i] = p; else products.add(p);
    active = p;
    await save();
    notifyListeners();
  }

  Future<void> addHour(HourEntry h) async {
    hours.insert(0, h);
    await save();
    notifyListeners();
  }

  Future<void> deleteHour(HourEntry h) async {
    hours.removeWhere((x) => x.id == h.id);
    await save();
    notifyListeners();
  }

  Future<void> clearHours() async {
    hours.clear();
    await save();
    notifyListeners();
  }
}

class App extends StatelessWidget {
  const App({super.key});
  @override Widget build(BuildContext context) {
    return MaterialApp(
      title: "Nate's Production Pro",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: navy,
        colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final store = Store();
  int tab = 0;
  bool ready = false;

  @override void initState() {
    super.initState();
    store.load().then((_) => setState(() => ready = true));
  }

  @override Widget build(BuildContext context) {
    if (!ready) return const Scaffold(body: Center(child: CircularProgressIndicator(color: gold)));
    return AnimatedBuilder(animation: store, builder: (_, __) {
      final pages = [
        Dashboard(store: store, go: (i) => setState(() => tab = i)),
        CalculatorPage(store: store),
        RateTrackerPage(store: store),
        ProductsPage(store: store),
        AdvisorPage(store: store),
      ];
      return Scaffold(
        body: SafeArea(child: pages[tab]),
        bottomNavigationBar: NavigationBar(
          backgroundColor: const Color(0xFF040B13),
          indicatorColor: gold.withOpacity(.2),
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: gold), label: "Home"),
            NavigationDestination(icon: Icon(Icons.calculate_outlined), selectedIcon: Icon(Icons.calculate, color: gold), label: "Calc"),
            NavigationDestination(icon: Icon(Icons.bar_chart), selectedIcon: Icon(Icons.bar_chart, color: gold), label: "Rate"),
            NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2, color: gold), label: "Products"),
            NavigationDestination(icon: Icon(Icons.psychology), selectedIcon: Icon(Icons.psychology, color: gold), label: "Advisor"),
          ],
        ),
      );
    });
  }
}

Widget logo([double h = 74]) => Image.asset("assets/nates_logo.png", height: h, fit: BoxFit.contain);

class Header extends StatelessWidget {
  final String title;
  final Widget? action;
  const Header(this.title, {super.key, this.action});
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Row(children: [logo(42), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))), if (action != null) action!]),
  );
}

class ProCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const ProCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    padding: padding,
    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.08)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 20, offset: const Offset(0, 10))]),
    child: child,
  );
}

class GoldButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  const GoldButton(this.text, this.icon, this.onTap, {super.key});
  @override Widget build(BuildContext context) => ElevatedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, color: navy),
    label: Text(text, style: const TextStyle(color: navy, fontWeight: FontWeight.w900)),
    style: ElevatedButton.styleFrom(backgroundColor: gold, minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
  );
}

Widget stat(String label, String value, [Color c = gold]) => Expanded(child: Container(
  margin: const EdgeInsets.all(4),
  padding: const EdgeInsets.all(13),
  decoration: BoxDecoration(color: navy2, borderRadius: BorderRadius.circular(14)),
  child: Column(children: [Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))]),
));

class Dashboard extends StatelessWidget {
  final Store store;
  final ValueChanged<int> go;
  const Dashboard({super.key, required this.store, required this.go});
  @override Widget build(BuildContext context) {
    final p = store.active;
    final c = p == null ? null : calc(p);
    final totalCases = store.hours.fold<double>(0, (a,b) => a + b.actualCases);
    final totalDry = store.hours.fold<double>(0, (a,b) => a + b.actualDryLb);
    return ListView(children: [
      const SizedBox(height: 14), Center(child: logo(90)),
      const Center(child: Text("NATE'S PRODUCTION PRO", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
      const Center(child: Text("Pounds Per Hour + Blancher Tracking", style: TextStyle(color: gold, fontWeight: FontWeight.w600))),
      ProCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("CURRENT PRODUCT", style: TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 12)),
        Text(p?.name ?? "No product selected", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        Text(p == null ? "Create a product to begin" : "Theoretical: ${f0(c!.cookedHour)} cooked lb/hr • ${f0(c.casesHour)} cases/hr", style: const TextStyle(color: muted)),
        const SizedBox(height: 14),
        GoldButton("OPEN RATE TRACKER", Icons.bar_chart, () => go(2)),
      ])),
      ProCard(child: Column(children: [
        const Text("SHIFT TOTALS ENTERED", style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Row(children: [stat("CASES", f0(totalCases)), stat("DRY LB", f0(totalDry))]),
      ])),
    ]);
  }
}

class CalculatorPage extends StatefulWidget {
  final Store store;
  const CalculatorPage({super.key, required this.store});
  @override State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  late TextEditingController name, dry, sec, yieldC, cases, caseW, cook;
  Calc? result;

  @override void initState() { super.initState(); load(widget.store.active); }

  void load(Product? p) {
    p ??= Product(id: DateTime.now().millisecondsSinceEpoch.toString(), name: "New Product", dryWeightPerFeed: 20, secondsPerFeed: 33, growthRate: 2.05, finishedCasesNeeded: 1000, caseWeight: 20, cookMinutes: 13);
    name = TextEditingController(text: p.name);
    dry = TextEditingController(text: f(p.dryWeightPerFeed));
    sec = TextEditingController(text: f(p.secondsPerFeed));
    yieldC = TextEditingController(text: f(p.growthRate));
    cases = TextEditingController(text: f(p.finishedCasesNeeded));
    caseW = TextEditingController(text: f(p.caseWeight));
    cook = TextEditingController(text: f(p.cookMinutes));
  }

  double v(TextEditingController c) => double.tryParse(c.text) ?? 0;
  Product current() => Product(id: widget.store.active?.id ?? DateTime.now().millisecondsSinceEpoch.toString(), name: name.text.trim().isEmpty ? "Unnamed Product" : name.text.trim(), dryWeightPerFeed: v(dry), secondsPerFeed: v(sec), growthRate: v(yieldC), finishedCasesNeeded: v(cases), caseWeight: v(caseW), cookMinutes: v(cook), favorite: widget.store.active?.favorite ?? false);

  @override Widget build(BuildContext context) => ListView(children: [
    Header("Calculator", action: IconButton(icon: const Icon(Icons.save, color: gold), onPressed: () => widget.store.upsertProduct(current()))),
    ProCard(child: Column(children: [
      field("Product name", name, "", false),
      field("Dry weight per feed", dry, "lb"),
      field("Seconds per feed", sec, "sec"),
      field("Growth rate / yield", yieldC, "x"),
      field("Finished cases needed", cases, "cases"),
      field("Case weight", caseW, "lb"),
      field("Blancher cook duration", cook, "min"),
      const SizedBox(height: 10),
      GoldButton("CALCULATE", Icons.calculate, () => setState(() => result = calc(current()))),
    ])),
    if (result != null) ProCard(child: Column(children: [
      const Text("STOP FEEDING WHEN PACKED CASES REACH", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
      Text(f(result!.stopCases), style: const TextStyle(fontSize: 52, color: goldBright, fontWeight: FontWeight.w900)),
      const Divider(color: Colors.white12),
      row("Dry pounds/hour", "${f0(result!.dryHour)} lb/hr"),
      row("Cooked pounds/hour", "${f0(result!.cookedHour)} lb/hr"),
      row("Cases/hour", "${f0(result!.casesHour)} cases/hr"),
    ])),
  ]);

  Widget field(String label, TextEditingController c, String suffix, [bool number = true]) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: TextField(controller: c, keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, decoration: InputDecoration(labelText: label, suffixText: suffix, filled: true, fillColor: navy2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
  );
  Widget row(String a, String b) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [Expanded(child: Text(a, style: const TextStyle(color: muted))), Text(b, style: const TextStyle(fontWeight: FontWeight.w900))]));
}

class RateTrackerPage extends StatelessWidget {
  final Store store;
  const RateTrackerPage({super.key, required this.store});

  @override Widget build(BuildContext context) {
    final p = store.active;
    if (p == null) return const Center(child: Text("No product selected"));
    final c = calc(p);
    final totalCases = store.hours.fold<double>(0, (a,b) => a + b.actualCases);
    final totalDry = store.hours.fold<double>(0, (a,b) => a + b.actualDryLb);
    final totalCooked = store.hours.fold<double>(0, (a,b) => a + b.actualCookedLb);
    final totalMinutes = store.hours.fold<double>(0, (a,b) => a + b.minutes);
    final actualCookedHr = totalMinutes > 0 ? totalCooked / (totalMinutes / 60) : 0;
    final actualCasesHr = totalMinutes > 0 ? totalCases / (totalMinutes / 60) : 0;
    final efficiency = c.cookedHour > 0 ? (actualCookedHr / c.cookedHour * 100).clamp(0, 999).toDouble() : 0.0;
    final expectedCasesByTime = c.casesHour * (totalMinutes / 60);
    final pace = totalCases - expectedCasesByTime;

    return ListView(children: [
      Header("Pounds Per Hour", action: IconButton(icon: const Icon(Icons.add, color: gold), onPressed: () => openHourEditor(context, store, p))),
      ProCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const Text("Theoretical production rate", style: TextStyle(color: muted)),
        const SizedBox(height: 10),
        Row(children: [stat("COOKED LB/HR", f0(c.cookedHour)), stat("CASES/HR", f0(c.casesHour))]),
        Row(children: [stat("DRY LB/HR", f0(c.dryHour)), stat("FEED SEC", f(p.secondsPerFeed))]),
      ])),
      ProCard(child: Column(children: [
        const Text("ACTUAL SHIFT RATE", style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Row(children: [stat("ACTUAL LB/HR", f0(actualCookedHr.toDouble()), efficiency >= 95 ? green : efficiency >= 85 ? orange : red), stat("ACTUAL CASES/HR", f0(actualCasesHr.toDouble())),
        Row(children: [stat("EFFICIENCY", "${f0(efficiency)}%", efficiency >= 95 ? green : efficiency >= 85 ? orange : red), stat("PACE", "${pace >= 0 ? "+" : ""}${f0(pace)} cases", pace >= 0 ? green : red)]),
        const SizedBox(height: 8),
        Text(pace >= 0 ? "Ahead of theoretical pace" : "Behind theoretical pace", style: TextStyle(color: pace >= 0 ? green : red, fontWeight: FontWeight.w900)),
      ])),
      ProCard(child: Column(children: [
        const Text("SHIFT TOTALS", style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Row(children: [stat("CASES", f0(totalCases)), stat("DRY LB", f0(totalDry))]),
        Row(children: [stat("COOKED LB", f0(totalCooked)), stat("HOURS", f(totalMinutes / 60))]),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => confirmClear(context, store), icon: const Icon(Icons.delete, color: red), label: const Text("Clear shift entries", style: TextStyle(color: red))),
      ])),
      if (store.hours.isEmpty) const ProCard(child: Text("No hourly entries yet. Tap + to add an hour or time block.")),
      ...store.hours.map((h) {
        final hCookedHr = h.minutes > 0 ? h.actualCookedLb / (h.minutes / 60) : 0;
        final hCasesHr = h.minutes > 0 ? h.actualCases / (h.minutes / 60) : 0;
        final hEfficiency = c.cookedHour > 0 ? (hCookedHr / c.cookedHour * 100).clamp(0, 999).toDouble() : 0.0;
        return ProCard(child: Row(children: [
          Container(width: 5, height: 72, decoration: BoxDecoration(color: hEfficiency >= 95 ? green : hEfficiency >= 85 ? orange : red, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text("${f0(h.actualCookedLb)} cooked lb • ${f0(h.actualCases)} cases", style: const TextStyle(color: muted)),
            Text("${f0(hCookedHr.toDouble())} lb/hr • ${f0(hCasesHr.toDouble())} cases/hr • ${f0(hEfficiency.toDouble())}%", style: const TextStyle(color: muted)),
          ])),
          IconButton(onPressed: () => store.deleteHour(h), icon: const Icon(Icons.delete_outline, color: red)),
        ]));
      }),
    ]);
  }

  void confirmClear(BuildContext context, Store store) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text("Clear shift entries?"),
      content: const Text("This will remove all hourly production tracking entries."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        TextButton(onPressed: () { store.clearHours(); Navigator.pop(context); }, child: const Text("Clear", style: TextStyle(color: red))),
      ],
    ));
  }

  void openHourEditor(BuildContext context, Store store, Product p) {
    final c = calc(p);
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: navy, builder: (_) => HourEditor(store: store, calcData: c, product: p));
  }
}

class HourEditor extends StatefulWidget {
  final Store store;
  final Calc calcData;
  final Product product;
  const HourEditor({super.key, required this.store, required this.calcData, required this.product});
  @override State<HourEditor> createState() => _HourEditorState();
}

class _HourEditorState extends State<HourEditor> {
  late TextEditingController label, cases, dry, cooked, minutes;
  @override void initState() {
    super.initState();
    final next = widget.store.hours.length + 1;
    label = TextEditingController(text: "Hour $next");
    cases = TextEditingController();
    dry = TextEditingController();
    cooked = TextEditingController();
    minutes = TextEditingController(text: "60");
  }
  double v(TextEditingController c) => double.tryParse(c.text) ?? 0;

  void fillTheoretical() {
    final mins = v(minutes) <= 0 ? 60 : v(minutes);
    final factor = mins / 60;
    cases.text = f(widget.calcData.casesHour * factor);
    dry.text = f(widget.calcData.dryHour * factor);
    cooked.text = f(widget.calcData.cookedHour * factor);
    setState(() {});
  }

  @override Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: MediaQuery.of(context).viewInsets.bottom + 18),
    child: SingleChildScrollView(child: Column(children: [
      const Text("Add Production Block", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      const Text("Enter what actually happened for an hour or any time block.", style: TextStyle(color: muted), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      e("Label", label, "", false),
      e("Minutes", minutes, "min"),
      e("Actual cases", cases, "cases"),
      e("Actual dry pounds", dry, "lb"),
      e("Actual cooked pounds", cooked, "lb"),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: fillTheoretical, icon: const Icon(Icons.auto_fix_high, color: gold), label: const Text("Fill with theoretical rate", style: TextStyle(color: gold))),
      const SizedBox(height: 10),
      GoldButton("SAVE ENTRY", Icons.save, () {
        widget.store.addHour(HourEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          label: label.text.trim().isEmpty ? "Hour" : label.text.trim(),
          actualCases: v(cases),
          actualDryLb: v(dry),
          actualCookedLb: v(cooked),
          minutes: v(minutes) <= 0 ? 60 : v(minutes),
        ));
        Navigator.pop(context);
      }),
    ])),
  );
  Widget e(String l, TextEditingController c, String suffix, [bool number = true]) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: TextField(controller: c, keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, decoration: InputDecoration(labelText: l, suffixText: suffix, filled: true, fillColor: card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))));
}

class ProductsPage extends StatelessWidget {
  final Store store;
  const ProductsPage({super.key, required this.store});
  @override Widget build(BuildContext context) {
    return ListView(children: [
      const Header("Products"),
      ...store.products.map((p) => ProCard(child: Row(children: [
        Icon(p.favorite ? Icons.star : Icons.inventory_2, color: gold),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text("${f(p.dryWeightPerFeed)} lb every ${f(p.secondsPerFeed)} sec • yield ${f(p.growthRate)}", style: const TextStyle(color: muted)),
        ])),
        TextButton(onPressed: () { store.active = p; store.notifyListeners(); }, child: const Text("Select")),
      ]))),
    ]);
  }
}

class AdvisorPage extends StatelessWidget {
  final Store store;
  const AdvisorPage({super.key, required this.store});
  @override Widget build(BuildContext context) {
    final p = store.active;
    if (p == null) return const Center(child: Text("No product selected"));
    final c = calc(p);
    final totalCases = store.hours.fold<double>(0, (a,b) => a + b.actualCases);
    final totalCooked = store.hours.fold<double>(0, (a,b) => a + b.actualCookedLb);
    final totalMinutes = store.hours.fold<double>(0, (a,b) => a + b.minutes);
    final actualHr = totalMinutes > 0 ? totalCooked / (totalMinutes / 60) : 0;
    final efficiency = c.cookedHour > 0 ? (actualHr / c.cookedHour * 100).toDouble() : 0.0;
    return ListView(children: [
      const Header("AI Advisor"),
      ProCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const Text("Production tracking advice", style: TextStyle(color: gold, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        advice("Pounds/hour", actualHr == 0 ? "Add an hourly entry to compare actual pounds/hour against theoretical." : "Actual cooked pounds/hour is ${f0(actualHr.toDouble())} versus theoretical ${f0(c.cookedHour)}."),
        advice("Efficiency", efficiency == 0 ? "No efficiency yet." : efficiency >= 95 ? "Efficiency is strong at ${f0(efficiency)}%. Keep current pace." : efficiency >= 85 ? "Efficiency is ${f0(efficiency)}%. Check feed timing, line delays, and pack-out speed." : "Efficiency is low at ${f0(efficiency)}%. Check for downtime, slow feeding, or pack-out bottleneck."),
        advice("Cases", "Total tracked cases this shift: ${f0(totalCases)}."),
      ])),
    ]);
  }
  Widget advice(String title, String body) => Container(width: double.infinity, margin: const EdgeInsets.symmetric(vertical: 6), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: navy2, borderRadius: BorderRadius.circular(14), border: const Border(left: BorderSide(color: gold, width: 5))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: gold, fontWeight: FontWeight.w900)), Text(body, style: const TextStyle(color: Colors.white70))]));
}
