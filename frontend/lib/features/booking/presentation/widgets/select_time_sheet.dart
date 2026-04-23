import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/booking_entities.dart';
import '../providers/availability_notifier.dart';
import '../../../customer/addresses/presentation/providers/dependency_injection.dart';
import '../../../customer/addresses/presentation/widgets/address_selector_sheet.dart';
import 'modal_bottom_sheet_layout.dart';
import 'review_booking_sheet.dart';

class SelectTimeSheet extends ConsumerStatefulWidget {
  final TechnicianProfileEntity technician;
  final int? serviceId;
  final int? subServiceId;

  const SelectTimeSheet({
    super.key,
    required this.technician,
    this.serviceId,
    this.subServiceId,
  });

  @override
  ConsumerState<SelectTimeSheet> createState() => _SelectTimeSheetState();
}

class _SelectTimeSheetState extends ConsumerState<SelectTimeSheet> {
  late DateTime _selectedDate;
  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dates = List.generate(7, (index) => DateTime.now().add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final availabilityAsync = ref.watch(availabilityProvider(
      technicianId: widget.technician.id,
      date: dateString,
      serviceId: widget.serviceId,
      subServiceId: widget.subServiceId,
    ));

    final defaultAddressAsync = ref.watch(defaultAddressProvider);

    return ModalBottomSheetLayout(
      title: 'Select a Time',
      footer: availabilityAsync.whenOrNull(
        data: (state) {
          final isEnabled = state.selectedSlot != null;
          return ElevatedButton(
            onPressed: isEnabled
                ? () {
                    final defaultAddress = defaultAddressAsync.value;
                    if (defaultAddress == null) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AddressSelectorSheet(),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => ReviewBookingSheet(
                        technician: widget.technician,
                        selectedDate: _selectedDate,
                        selectedSlot: state.selectedSlot!,
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0051AE),
              disabledBackgroundColor: const Color(0xFFE1E9F3),
              foregroundColor: Colors.white,
              disabledForegroundColor: const Color(0xFF727785),
              elevation: isEnabled ? 8 : 0,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isEnabled
                      ? 'Continue with ${state.selectedSlot!.timeString}'
                      : 'Select a time slot',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isEnabled) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ],
            ),
          );
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Strip
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _dates.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final date = _dates[index];
                final isSelected = date.day == _selectedDate.day &&
                    date.month == _selectedDate.month &&
                    date.year == _selectedDate.year;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 72,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFB6CCFE)
                          : const Color(0xFFE7EFF9),
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(
                              color: const Color(0xFF0051AE).withOpacity(0.1),
                              width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date), // 'Mon', 'Tue'
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF0051AE)
                                : const Color(0xFF424753),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.bold,
                            color: isSelected
                                ? const Color(0xFF0051AE)
                                : const Color(0xFF151C24),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // Slots Area
          availabilityAsync.when(
            data: (state) {
              if (state.slots.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Text(
                      'No slots available on this date.',
                      style: TextStyle(
                        color: Color(0xFF727785),
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }

              final morningSlots =
                  state.slots.where((s) => s.period == 'AM').toList();
              final afternoonSlots =
                  state.slots.where((s) => s.period == 'PM').toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (morningSlots.isNotEmpty) ...[
                    _PeriodSection(
                      title: 'Morning',
                      icon: Icons.wb_sunny_outlined, // Simplified icon
                      slots: morningSlots,
                      selectedSlot: state.selectedSlot,
                      onSlotSelected: (slot) => ref
                          .read(availabilityProvider(
                            technicianId: widget.technician.id,
                            date: dateString,
                            serviceId: widget.serviceId,
                            subServiceId: widget.subServiceId,
                          ).notifier)
                          .selectSlot(slot),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (afternoonSlots.isNotEmpty)
                    _PeriodSection(
                      title: 'Afternoon',
                      icon: Icons.wb_sunny, // Simplified icon
                      slots: afternoonSlots,
                      selectedSlot: state.selectedSlot,
                      onSlotSelected: (slot) => ref
                          .read(availabilityProvider(
                            technicianId: widget.technician.id,
                            date: dateString,
                            serviceId: widget.serviceId,
                            subServiceId: widget.subServiceId,
                          ).notifier)
                          .selectSlot(slot),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'Error loading slots.\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<AvailabilitySlotEntity> slots;
  final AvailabilitySlotEntity? selectedSlot;
  final ValueChanged<AvailabilitySlotEntity> onSlotSelected;

  const _PeriodSection({
    required this.title,
    required this.icon,
    required this.slots,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF424753)),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Color(0xFF424753),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: slots.map((slot) {
            final isSelected = selectedSlot == slot;

            return GestureDetector(
              onTap: () => onSlotSelected(slot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF0051AE), Color(0xFF0969DA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : const Color(0xFFE1E9F3),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0051AE).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                  border: isSelected
                      ? Border.all(
                          color: const Color(0xFF0051AE).withOpacity(0.1),
                          width: 4)
                      : null,
                ),
                child: Text(
                  slot.timeString,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF151C24),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
