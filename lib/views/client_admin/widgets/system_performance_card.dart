import 'package:flutter/material.dart';

class SystemPerformanceCard extends StatelessWidget {
  const SystemPerformanceCard({super.key});

  static const List<double> chartValues = [
    0.40,
    0.55,
    0.45,
    0.70,
    0.60,
    0.78,
    0.95,
    0.75,
    0.65,
    0.80,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 560,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE9EFF2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D2D3436),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Performance',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF161D1F),
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'Booking trends for the current period',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF586062),
                      ),
                    ),
                  ],
                ),
              ),

              _ToggleChip(
                label: 'Week',
                selected: false,
              ),

              SizedBox(width: 8),

              _ToggleChip(
                label: 'Month',
                selected: true,
              ),
            ],
          ),

          const SizedBox(height: 52),

          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(chartValues.length, (index) {
                      final bool active = index == 6;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (active)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF161D1F),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '342',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),

                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                height: 280 * chartValues[index],
                                decoration: BoxDecoration(
                                  color: active
                                      ? const Color(0xFF00B894)
                                      : const Color(0xFFEEF5F7),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                  boxShadow: active
                                      ? const [
                                    BoxShadow(
                                      color: Color(0x6600B894),
                                      blurRadius: 10,
                                      offset: Offset(0, 0),
                                    ),
                                  ]
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 20),

                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ChartLabel('OCT 01'),
                    _ChartLabel('OCT 10'),
                    _ChartLabel('OCT 20'),
                    _ChartLabel('TODAY'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _ToggleChip({
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF006B55) : const Color(0xFFE3E9EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF161D1F),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ChartLabel extends StatelessWidget {
  final String label;

  const _ChartLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF586062),
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }
}