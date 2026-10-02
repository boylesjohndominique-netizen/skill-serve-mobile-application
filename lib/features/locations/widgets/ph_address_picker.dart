import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/api_error.dart';
import '../models/ph_address.dart';
import '../services/location_service.dart';

/// The Philippine address picker: Region → Province or City → City /
/// Municipality → Barangay, then street and ZIP — the way a government form
/// or a checkout asks for an address.
///
/// - [door] (sign-up, profile, booking): the barangay is required and street
///   and ZIP are asked for.
/// - otherwise (a service's area): a city or municipality is enough and the
///   barangay is optional.
///
/// A [FormField], so the surrounding form's `validate()` checks it.
class PhAddressPicker extends FormField<PhAddress> {
  PhAddressPicker({
    super.key,
    required PhAddress initial,
    required ValueChanged<PhAddress> onChanged,
    bool door = true,
    super.enabled = true,
    LocationService? service,
  }) : super(
          initialValue: initial,
          validator: (value) {
            if (door && !(value?.hasBarangay ?? false)) return 'Choose your barangay.';
            if (!door && !(value?.hasCity ?? false)) return 'Choose a city or municipality.';
            final zip = value?.postalCode.trim() ?? '';
            if (zip.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(zip)) return 'A ZIP code is 4 digits.';
            return null;
          },
          builder: (field) => _PickerBody(
            field: field,
            door: door,
            enabled: field.widget.enabled,
            service: service ?? LocationService(),
            onChanged: onChanged,
          ),
        );
}

class _PickerBody extends StatefulWidget {
  const _PickerBody({
    required this.field,
    required this.door,
    required this.enabled,
    required this.service,
    required this.onChanged,
  });

  final FormFieldState<PhAddress> field;
  final bool door;
  final bool enabled;
  final LocationService service;
  final ValueChanged<PhAddress> onChanged;

  @override
  State<_PickerBody> createState() => _PickerBodyState();
}

class _PickerBodyState extends State<_PickerBody> {
  late final _street = TextEditingController(text: _value.street);
  late final _zip = TextEditingController(text: _value.postalCode);

  PhAddress get _value => widget.field.value ?? PhAddress.empty;

  @override
  void dispose() {
    _street.dispose();
    _zip.dispose();
    super.dispose();
  }

  void _set(PhAddress address) {
    widget.field.didChange(address);
    widget.onChanged(address);
  }

  /// The second list mixes provinces with province-less cities (NCR), so what
  /// was picked there decides whether a city list follows.
  PhPlace? get _second => _value.province ?? _value.city;

  Future<void> _pick({
    required String title,
    required Future<List<PhPlace>> Function() load,
    required void Function(PhPlace place) onPicked,
  }) async {
    final picked = await showModalBottomSheet<PhPlace>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PlaceSheet(title: title, load: load),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final value = _value;
    final service = widget.service;
    final enabled = widget.enabled;

    final tiles = <Widget>[
      _SelectTile(
        label: 'Region',
        value: value.region?.name,
        enabled: enabled,
        onTap: () => _pick(
          title: 'Region',
          load: service.regions,
          onPicked: (region) => _set(PhAddress(region: region, street: _street.text, postalCode: _zip.text)),
        ),
      ),
      if (value.region != null)
        _SelectTile(
          label: 'Province or city',
          value: _second?.name,
          enabled: enabled,
          onTap: () => _pick(
            title: 'Province or city',
            load: () => service.children(value.region!.code),
            onPicked: (place) => _set(PhAddress(
              region: value.region,
              province: place.isProvince ? place : null,
              city: place.isLocality ? place : null,
              street: _street.text,
              postalCode: _zip.text,
            )),
          ),
        ),
      if (value.province != null)
        _SelectTile(
          label: 'City or municipality',
          value: value.city?.name,
          enabled: enabled,
          onTap: () => _pick(
            title: 'City or municipality',
            load: () => service.children(value.province!.code),
            onPicked: (city) => _set(PhAddress(
              region: value.region,
              province: value.province,
              city: city,
              street: _street.text,
              postalCode: _zip.text,
            )),
          ),
        ),
      if (value.city != null)
        _SelectTile(
          label: widget.door ? 'Barangay' : 'Barangay (optional)',
          value: value.barangay?.name,
          enabled: enabled,
          onTap: () => _pick(
            title: 'Barangay',
            load: () => service.children(value.city!.code),
            onPicked: (barangay) => _set(PhAddress(
              region: value.region,
              province: value.province,
              city: value.city,
              barangay: barangay,
              street: _street.text,
              postalCode: _zip.text,
            )),
          ),
        ),
      if (widget.door) ...[
        TextField(
          controller: _street,
          enabled: enabled,
          maxLength: 255,
          decoration: const InputDecoration(
            labelText: 'House no., street, subdivision (optional)',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          onChanged: (text) => _set(value.copyWith(street: text)),
        ),
        TextField(
          controller: _zip,
          enabled: enabled,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(labelText: 'ZIP code (optional)', border: OutlineInputBorder(), counterText: ''),
          onChanged: (text) => _set(value.copyWith(postalCode: text)),
        ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final tile in tiles) ...[tile, const SizedBox(height: 12)],
        if (widget.field.hasError)
          Text(
            widget.field.errorText!,
            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
          ),
      ],
    );
  }
}

/// One level of the address, showing what is chosen; tapping opens the list.
class _SelectTile extends StatelessWidget {
  const _SelectTile({required this.label, required this.value, required this.enabled, required this.onTap});

  final String label;
  final String? value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.expand_more_rounded),
          enabled: enabled,
        ),
        child: Text(
          value ?? 'Select ${label.toLowerCase().replaceAll(' (optional)', '')}',
          style: TextStyle(color: value == null ? AppColors.textSecondary : null),
        ),
      ),
    );
  }
}

/// A searchable list of places: some cities have over a hundred barangays.
class _PlaceSheet extends StatefulWidget {
  const _PlaceSheet({required this.title, required this.load});

  final String title;
  final Future<List<PhPlace>> Function() load;

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  late Future<List<PhPlace>> _places = widget.load();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                autofocus: false,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: OutlineInputBorder(),
                ),
                onChanged: (text) => setState(() => _query = text.trim().toLowerCase()),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<PhPlace>>(
                  future: _places,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(apiErrorMessage(snapshot.error!, 'Unable to load the list.'), textAlign: TextAlign.center),
                            TextButton(
                              onPressed: () => setState(() => _places = widget.load()),
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      );
                    }
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final places = snapshot.data!
                        .where((place) => _query.isEmpty || place.name.toLowerCase().contains(_query))
                        .toList();
                    if (places.isEmpty) return const Center(child: Text('No match.'));
                    return ListView.builder(
                      itemCount: places.length,
                      itemBuilder: (context, i) => ListTile(
                        title: Text(places[i].name),
                        onTap: () => Navigator.pop(context, places[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
