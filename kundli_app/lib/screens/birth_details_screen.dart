    import 'dart:async';

    import 'package:flutter/material.dart';

    import '../models/location_model.dart';
    import '../services/location_service.dart';
    import 'result_screen.dart';
    import '../models/kundli_input_model.dart';
    import '../utils/coordinate_utils.dart';

    class BirthDetailsScreen extends StatefulWidget {
    const BirthDetailsScreen({super.key});

    @override
    State<BirthDetailsScreen> createState() => _BirthDetailsScreenState();
    }
    enum LocationInputMode {
  place,
  coordinates,
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

    final latDegController = TextEditingController();
    final latMinController = TextEditingController();

    String longitudeDirection = "E";
    String latitudeDirection = "N";
    bool isSearchingLocations = false;
    int searchVersion = 0;

    String? selectedDisplayName;
    double? selectedLatitude;
    double? selectedLongitude;
    String placeInputValue = '';

    void showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
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
          double latitude;
        double longitude;
  if (nameController.text.trim().isEmpty) {
    showError("Please enter name");
    return;
  }

  if (selectedDate == null) {
    showError("Please select date of birth");
    return;
  }

  if (selectedTime == null) {
    showError("Please select birth time");
    return;
  }

  if (locationMode == LocationInputMode.place &&
      selectedLocation == null) {
    showError("Please select a place");
    return;
  }

  if (locationMode == LocationInputMode.place && selectedLocation != null) {
  latitude = selectedLatitude!;
  longitude = selectedLongitude!;
} else {
  if (longDegController.text.isEmpty ||
      longMinController.text.isEmpty ||
      latDegController.text.isEmpty ||
      latMinController.text.isEmpty) {
    showError("Please enter coordinates");
    return;
  }

  latitude = CoordinateUtils.toDecimal(
    degree: int.parse(latDegController.text),
    minute: int.parse(latMinController.text),
    negative: latitudeDirection == "S",
  );

  longitude = CoordinateUtils.toDecimal(
    degree: int.parse(longDegController.text),
    minute: int.parse(longMinController.text),
    negative: longitudeDirection == "W",
  );
}

  if (locationMode == LocationInputMode.coordinates) {
    if (longDegController.text.isEmpty ||
        longMinController.text.isEmpty ||
        latDegController.text.isEmpty ||
        latMinController.text.isEmpty) {
      showError("Please enter coordinates");
      return;
    }
    else {
  latitude = CoordinateUtils.toDecimal(
    degree: int.parse(latDegController.text),
    minute: int.parse(latMinController.text),
    negative: latitudeDirection == "S",
  );

  longitude = CoordinateUtils.toDecimal(
    degree: int.parse(longDegController.text),
    minute: int.parse(longMinController.text),
    negative: longitudeDirection == "W",
  );
}
  }

  final kundliInput = KundliInput(
  name: nameController.text,
  birthDateTime: DateTime(
    selectedDate!.year,
    selectedDate!.month,
    selectedDate!.day,
    selectedTime!.hour,
    selectedTime!.minute,
  ),
  place: locationMode == LocationInputMode.place
      ? selectedDisplayName ?? ""
      : "${latDegController.text}°${latMinController.text}' $latitudeDirection, "
        "${longDegController.text}°${longMinController.text}' $longitudeDirection",
    latitude: latitude,
    longitude: longitude,
);

  Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ResultScreen(
      kundliInput: kundliInput,
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

const Text(
  "Location Method",
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
),

RadioListTile<LocationInputMode>(
  title: const Text("Search Place"),
  value: LocationInputMode.place,
  groupValue: locationMode,
  onChanged: (value) {
    setState(() {
      locationMode = value!;
    });
  },
),

RadioListTile<LocationInputMode>(
  title: const Text("Enter Coordinates"),
  value: LocationInputMode.coordinates,
  groupValue: locationMode,
  onChanged: (value) {
    setState(() {
      locationMode = value!;
    });
  },
),

const SizedBox(height: 16),

                if (locationMode == LocationInputMode.place)
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
if (locationMode == LocationInputMode.coordinates)
  Column(
    children: [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: longDegController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Long Degree",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: longMinController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Long Minute",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: longitudeDirection,
            items: const [
              DropdownMenuItem(
                value: "E",
                child: Text("E"),
              ),
              DropdownMenuItem(
                value: "W",
                child: Text("W"),
              ),
            ],
            onChanged: (value) {
              setState(() {
                longitudeDirection = value!;
              });
            },
          ),
        ],
      ),

      const SizedBox(height: 16),

      Row(
        children: [
          Expanded(
            child: TextField(
              controller: latDegController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Lat Degree",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: latMinController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Lat Minute",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: latitudeDirection,
            items: const [
              DropdownMenuItem(
                value: "N",
                child: Text("N"),
              ),
              DropdownMenuItem(
                value: "S",
                child: Text("S"),
              ),
            ],
            onChanged: (value) {
              setState(() {
                latitudeDirection = value!;
              });
            },
          ),
        ],
      ),
    ],
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