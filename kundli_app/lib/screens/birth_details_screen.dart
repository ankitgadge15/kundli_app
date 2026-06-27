import 'dart:async';
import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';
import 'result_screen.dart';
import '../models/kundli_input_model.dart';
import '../utils/coordinate_utils.dart';
import '../services/astrology_service.dart';

enum LocationInputMode { place, coordinates }

class BirthDetailsScreen extends StatefulWidget {
  const BirthDetailsScreen({super.key});

  @override
  State<BirthDetailsScreen> createState() => _BirthDetailsScreenState();
}

class _BirthDetailsScreenState extends State<BirthDetailsScreen> {
  final TextEditingController nameController = TextEditingController();
  final LocationService locationService = LocationService();
  final List<LocationModel> locationSuggestions = [];

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  Timer? debounceTimer;
  LocationModel? selectedLocation;
  LocationInputMode locationMode = LocationInputMode.place;

  final longDegController = TextEditingController();
  final longMinController = TextEditingController();
  final latDegController  = TextEditingController();
  final latMinController  = TextEditingController();

  String longitudeDirection = 'E';
  String latitudeDirection  = 'N';
  bool isSearchingLocations = false;
  int searchVersion = 0;

  String? selectedDisplayName;
  double? selectedLatitude;
  double? selectedLongitude;
  String placeInputValue = '';

  double selectedTimezoneOffset = 5.5;
  bool isCalculating = false;

  final List<Map<String, dynamic>> timezoneOffsets = [
    {'name': 'GMT-12:00 (IDLW)', 'value': -12.0},
    {'name': 'GMT-11:00 (SST)',  'value': -11.0},
    {'name': 'GMT-10:00 (HST)',  'value': -10.0},
    {'name': 'GMT-09:30 (MIT)',  'value': -9.5},
    {'name': 'GMT-09:00 (AKST)','value': -9.0},
    {'name': 'GMT-08:00 (PST)',  'value': -8.0},
    {'name': 'GMT-07:00 (MST)',  'value': -7.0},
    {'name': 'GMT-06:00 (CST)',  'value': -6.0},
    {'name': 'GMT-05:00 (EST)',  'value': -5.0},
    {'name': 'GMT-04:00 (AST)',  'value': -4.0},
    {'name': 'GMT-03:30 (NST)',  'value': -3.5},
    {'name': 'GMT-03:00 (BRT)',  'value': -3.0},
    {'name': 'GMT-02:00 (FNT)',  'value': -2.0},
    {'name': 'GMT-01:00 (AZOT)','value': -1.0},
    {'name': 'GMT+00:00 (UTC)',  'value':  0.0},
    {'name': 'GMT+01:00 (CET)',  'value':  1.0},
    {'name': 'GMT+02:00 (EET)',  'value':  2.0},
    {'name': 'GMT+03:00 (MSK)',  'value':  3.0},
    {'name': 'GMT+03:30 (IRT)',  'value':  3.5},
    {'name': 'GMT+04:00 (GST)',  'value':  4.0},
    {'name': 'GMT+04:30 (AFT)',  'value':  4.5},
    {'name': 'GMT+05:00 (PKT)',  'value':  5.0},
    {'name': 'GMT+05:30 (IST)',  'value':  5.5},
    {'name': 'GMT+05:45 (NPT)',  'value':  5.75},
    {'name': 'GMT+06:00 (BST)',  'value':  6.0},
    {'name': 'GMT+06:30 (MMT)',  'value':  6.5},
    {'name': 'GMT+07:00 (ICT)',  'value':  7.0},
    {'name': 'GMT+08:00 (SGT)',  'value':  8.0},
    {'name': 'GMT+09:00 (JST)',  'value':  9.0},
    {'name': 'GMT+09:30 (ACST)','value':  9.5},
    {'name': 'GMT+10:00 (AEST)','value': 10.0},
    {'name': 'GMT+11:00 (SBT)',  'value': 11.0},
    {'name': 'GMT+12:00 (NZST)','value': 12.0},
    {'name': 'GMT+13:00 (TKT)',  'value': 13.0},
    {'name': 'GMT+14:00 (LINT)','value': 14.0},
  ];

  @override
  void initState() {
    super.initState();
    final localOffset = DateTime.now().timeZoneOffset.inMinutes / 60.0;
    selectedTimezoneOffset = localOffset;
    if (!timezoneOffsets.any((e) => e['value'] == localOffset)) {
      final sign  = localOffset >= 0 ? '+' : '-';
      final abs   = localOffset.abs();
      final h     = abs.floor();
      final m     = ((abs - h) * 60).round().toString().padLeft(2, '0');
      timezoneOffsets.add({'name': 'GMT$sign$h:$m (Local)', 'value': localOffset});
      timezoneOffsets.sort((a, b) =>
          (a['value'] as double).compareTo(b['value'] as double));
    }
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    nameController.dispose();
    longDegController.dispose();
    longMinController.dispose();
    latDegController.dispose();
    latMinController.dispose();
    super.dispose();
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      debounceTimer?.cancel();
      setState(() {
        locationSuggestions.clear();
        isSearchingLocations = false;
      });
      return;
    }

    final version = ++searchVersion;
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => isSearchingLocations = true);
      try {
        final results = await locationService.search(trimmed);
        if (!mounted || version != searchVersion) return;
        setState(() {
          locationSuggestions
            ..clear()
            ..addAll(results);
          isSearchingLocations = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          locationSuggestions.clear();
          isSearchingLocations = false;
        });
      }
    });
  }

  void selectLocation(LocationModel location) {
    debounceTimer?.cancel();
    setState(() {
      selectedLocation    = location;
      selectedDisplayName = location.displayName;
      selectedLatitude    = location.latitude;
      selectedLongitude   = location.longitude;
      placeInputValue     = location.displayName;
      locationSuggestions.clear();
      isSearchingLocations = false;
    });
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate:   DateTime(1900),
      lastDate:    DateTime.now(),
      initialDate: selectedDate ?? DateTime(1990),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) setState(() => selectedTime = time);
  }

  Future<void> generateKundli() async {
    if (isCalculating) return;

    if (nameController.text.trim().isEmpty) { showError('Please enter name'); return; }
    if (selectedDate == null)  { showError('Please select date of birth'); return; }
    if (selectedTime == null)  { showError('Please select birth time'); return; }
    if (locationMode == LocationInputMode.place && selectedLocation == null) {
      showError('Please select a place from suggestions'); return;
    }

    double latitude, longitude;

    if (locationMode == LocationInputMode.place) {
      latitude  = selectedLatitude!;
      longitude = selectedLongitude!;
    } else {
      if (latDegController.text.isEmpty || latMinController.text.isEmpty ||
          longDegController.text.isEmpty || longMinController.text.isEmpty) {
        showError('Please enter all coordinate fields'); return;
      }
      latitude  = CoordinateUtils.toDecimal(
        degree: int.parse(latDegController.text),
        minute: int.parse(latMinController.text),
        negative: latitudeDirection == 'S',
      );
      longitude = CoordinateUtils.toDecimal(
        degree: int.parse(longDegController.text),
        minute: int.parse(longMinController.text),
        negative: longitudeDirection == 'W',
      );
    }

    setState(() => isCalculating = true);
    try {
      final kundliInput = KundliInput(
        name: nameController.text.trim(),
        birthDateTime: DateTime(
          selectedDate!.year, selectedDate!.month, selectedDate!.day,
          selectedTime!.hour, selectedTime!.minute,
        ),
        timezoneOffset: selectedTimezoneOffset,
        place: locationMode == LocationInputMode.place
            ? selectedDisplayName ?? ''
            : '${latDegController.text}°${latMinController.text}\' $latitudeDirection, '
              '${longDegController.text}°${longMinController.text}\' $longitudeDirection',
        latitude:  latitude,
        longitude: longitude,
      );

      final result = await AstrologyService().generateKundli(kundliInput);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            kundliInput:  kundliInput,
            kundliResult: result,
          ),
        ),
      );
    } catch (e) {
      showError('Error generating Kundli: $e');
    } finally {
      if (mounted) setState(() => isCalculating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Fancy header ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            centerTitle: true,
            title: const Text('Birth Details',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A148C), Color(0xFF1A1030)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 40),
                      Text('🔯', style: TextStyle(fontSize: 44)),
                      SizedBox(height: 8),
                      Text(
                        'Calculate Planetary Positions & Lagna',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              collapseMode: CollapseMode.parallax,
            ),
          ),

          // ── Form ──────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Name
                _sectionLabel('Personal Info'),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),

                const SizedBox(height: 24),
                _sectionLabel('Date & Time of Birth'),
                const SizedBox(height: 10),

                // Date picker
                _pickButton(
                  icon: Icons.calendar_today_outlined,
                  label: selectedDate == null
                      ? 'Select Date of Birth'
                      : '${selectedDate!.day} / ${selectedDate!.month} / ${selectedDate!.year}',
                  onTap: pickDate,
                  isSet: selectedDate != null,
                ),

                const SizedBox(height: 12),

                // Time picker
                _pickButton(
                  icon: Icons.access_time_outlined,
                  label: selectedTime == null
                      ? 'Select Birth Time'
                      : selectedTime!.format(context),
                  onTap: pickTime,
                  isSet: selectedTime != null,
                ),

                const SizedBox(height: 24),
                _sectionLabel('Timezone'),
                const SizedBox(height: 10),

                DropdownButtonFormField<double>(
                  value: selectedTimezoneOffset,
                  dropdownColor: const Color(0xFF241840),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.public),
                    labelText: 'Timezone Offset',
                  ),
                  items: timezoneOffsets.map((tz) => DropdownMenuItem<double>(
                    value: tz['value'] as double,
                    child: Text(tz['name'] as String),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => selectedTimezoneOffset = v);
                  },
                ),

                const SizedBox(height: 24),
                _sectionLabel('Place of Birth'),
                const SizedBox(height: 10),

                // Location mode toggle
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF241840),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      _modeTab('Search Place', LocationInputMode.place),
                      _modeTab('Coordinates',  LocationInputMode.coordinates),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                if (locationMode == LocationInputMode.place) ...[
                  Autocomplete<LocationModel>(
                    optionsBuilder: (_) => locationSuggestions,
                    displayStringForOption: (o) => o.displayName,
                    onSelected: selectLocation,
                    fieldViewBuilder: (ctx, fieldCtrl, focusNode, onSubmit) {
                      if (placeInputValue.isNotEmpty &&
                          fieldCtrl.text != placeInputValue) {
                        fieldCtrl.text = placeInputValue;
                      }
                      return TextField(
                        controller: fieldCtrl,
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Search city / town',
                          hintText: 'e.g. Goa, Mumbai, Delhi…',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: isSearchingLocations
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.purpleAccent),
                                  ))
                              : selectedLocation != null
                                  ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                                  : const Icon(Icons.place_outlined),
                        ),
                        onChanged: (v) {
                          placeInputValue = v;
                          if (selectedLocation != null && v != selectedLocation!.displayName) {
                            selectedLocation    = null;
                            selectedDisplayName = null;
                            selectedLatitude    = null;
                            selectedLongitude   = null;
                          }
                          searchLocations(v);
                        },
                        onSubmitted: (_) => onSubmit(),
                      );
                    },
                    optionsViewBuilder: (ctx, onSelected, options) {
                      final list = options.toList();
                      if (list.isEmpty) return const SizedBox.shrink();
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          color: const Color(0xFF241840),
                          elevation: 8,
                          borderRadius: BorderRadius.circular(12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                                maxHeight: 280, maxWidth: 700),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: list.length,
                              separatorBuilder: (_, index) =>
                                  Divider(height: 1, color: Colors.purple.withOpacity(0.2)),
                              itemBuilder: (_, i) {
                                final opt = list[i];
                                return ListTile(
                                  leading: const Icon(Icons.location_on_outlined,
                                      color: Colors.purpleAccent, size: 20),
                                  title: Text(
                                    opt.displayName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 13),
                                  ),
                                  onTap: () => onSelected(opt),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],

                if (locationMode == LocationInputMode.coordinates) ...[
                  _coordRow(
                    label: 'Longitude',
                    degCtrl: longDegController,
                    minCtrl: longMinController,
                    direction: longitudeDirection,
                    options: const ['E', 'W'],
                    onDir: (v) => setState(() => longitudeDirection = v!),
                  ),
                  const SizedBox(height: 12),
                  _coordRow(
                    label: 'Latitude',
                    degCtrl: latDegController,
                    minCtrl: latMinController,
                    direction: latitudeDirection,
                    options: const ['N', 'S'],
                    onDir: (v) => setState(() => latitudeDirection = v!),
                  ),
                ],

                const SizedBox(height: 36),

                // Generate button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: isCalculating ? null : generateKundli,
                    child: isCalculating
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, size: 20),
                              SizedBox(width: 10),
                              Text('Generate Kundli',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          color: Colors.purple.shade300,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.8,
        ),
      );

  Widget _pickButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isSet,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF241840),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSet
                ? Colors.purple.withOpacity(0.7)
                : Colors.purple.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSet ? Colors.purpleAccent : Colors.purple.shade300,
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSet ? Colors.white : Colors.white54,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.purple.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _modeTab(String label, LocationInputMode mode) {
    final isActive = locationMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => locationMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.purple.shade700 : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white54,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _coordRow({
    required String label,
    required TextEditingController degCtrl,
    required TextEditingController minCtrl,
    required String direction,
    required List<String> options,
    required ValueChanged<String?> onDir,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: TextField(
              controller: degCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Degrees'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: minCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Minutes'),
            ),
          ),
          const SizedBox(width: 10),
          DropdownButton<String>(
            value: direction,
            dropdownColor: const Color(0xFF241840),
            style: const TextStyle(color: Colors.white),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: onDir,
          ),
        ]),
      ],
    );
  }
}