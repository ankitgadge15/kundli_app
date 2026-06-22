    import 'dart:async';

    import 'package:flutter/material.dart';

    import '../models/location_model.dart';
    import '../services/location_service.dart';
    import 'result_screen.dart';

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
    bool isSearchingLocations = false;
    int searchVersion = 0;

    String? selectedDisplayName;
    double? selectedLatitude;
    double? selectedLongitude;
    String placeInputValue = '';

    @override
    void dispose() {
        debounceTimer?.cancel();
        nameController.dispose();
        super.dispose();
    }

    Future<void> searchLocations(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.length < 3) {
        debounceTimer?.cancel();

        setState(() {
        locationSuggestions.clear();
        isSearchingLocations = false;
        });

        return;
    }

    final currentVersion = ++searchVersion;

    debounceTimer?.cancel();

    debounceTimer = Timer(const Duration(milliseconds: 500), () async {
        if (!mounted) return;

        setState(() {
        isSearchingLocations = true;
        });

        try {
        final results = await locationService.search(trimmedQuery);

        if (!mounted) return;

        if (currentVersion != searchVersion ||
            placeInputValue.trim() != trimmedQuery) {
            return;
        }

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
        selectedLocation = location;
        selectedDisplayName = location.displayName;
        selectedLatitude = location.latitude;
        selectedLongitude = location.longitude;
        placeInputValue = location.displayName;

        locationSuggestions.clear();
        isSearchingLocations = false;
    });
    }

    Future<void> pickDate() async {
        final date = await showDatePicker(
        context: context,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        initialDate: DateTime.now(),
        );

        if (date != null) {
        setState(() {
            selectedDate = date;
        });
        }
    }

    Future<void> pickTime() async {
        final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        );

        if (time != null) {
        setState(() {
            selectedTime = time;
        });
        }
    }

    void generateKundli() {
        Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ResultScreen(
            name: nameController.text,
            dob: selectedDate?.toString() ?? "",
            birthTime: selectedTime?.format(context) ?? "",
            place: selectedDisplayName ?? placeInputValue,
            ),
        ),
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
        appBar: AppBar(
            title: const Text("Birth Details"),
            centerTitle: true,
        ),
        body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
            children: [
                TextField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                ),
                ),

                const SizedBox(height: 16),

                FilledButton.tonal(
                onPressed: pickDate,
                child: Text(
                    selectedDate == null
                        ? "Select Date of Birth"
                        : selectedDate.toString().split(" ")[0],
                ),
                ),

                const SizedBox(height: 16),

                FilledButton.tonal(
                onPressed: pickTime,
                child: Text(
                    selectedTime == null
                        ? "Select Birth Time"
                        : selectedTime!.format(context),
                ),
                ),

                const SizedBox(height: 16),

                Autocomplete<LocationModel>(
  optionsBuilder: (TextEditingValue textEditingValue) {
    return locationSuggestions;
  },
  displayStringForOption: (LocationModel option) =>
      option.displayName,
  onSelected: selectLocation,
  fieldViewBuilder: (
    BuildContext context,
    TextEditingController fieldController,
    FocusNode focusNode,
    VoidCallback onFieldSubmitted,
  ) {
    if (placeInputValue.isNotEmpty &&
        fieldController.text != placeInputValue) {
      fieldController.text = placeInputValue;
    }

    return TextField(
      controller: fieldController,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: "Place of Birth",
        hintText: "Type at least 3 characters",
        border: const OutlineInputBorder(),
        suffixIcon: isSearchingLocations
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              )
            : const Icon(Icons.place_outlined),
      ),
      onChanged: (value) {
        placeInputValue = value;

        if (selectedLocation != null &&
            value != selectedLocation!.displayName) {
          selectedLocation = null;
          selectedDisplayName = null;
          selectedLatitude = null;
          selectedLongitude = null;
        }

        searchLocations(value);
      },
      onSubmitted: (_) => onFieldSubmitted(),
    );
  },
  optionsViewBuilder: (
    BuildContext context,
    AutocompleteOnSelected<LocationModel> onSelected,
    Iterable<LocationModel> options,
  ) {
    final optionList = options.toList();

    if (optionList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 250,
            maxWidth: 700,
          ),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: optionList.length,
            itemBuilder: (context, index) {
              final option = optionList[index];

              return ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(
                  option.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => onSelected(option),
              );
            },
          ),
        ),
      ),
    );
  },
),

                const SizedBox(height: 8),

                const SizedBox(height: 32),

                SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: generateKundli,
                    child: const Text("Generate Kundli"),
                ),
                ),
            ],
            ),
        ),
        );
    }
    }