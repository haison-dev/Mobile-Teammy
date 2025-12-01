import 'package:flutter/material.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  int _selectedIndex = 0;

  final _tabs = const [
    _BottomTab(icon: Icons.menu_rounded, label: 'Timeline'),
    _BottomTab(icon: Icons.check_box_outlined, label: 'Việc của tôi'),
    _BottomTab(icon: Icons.view_kanban_outlined, label: 'Teams'),
    _BottomTab(icon: Icons.search, label: 'Tìm kiếm'),
    _BottomTab(icon: Icons.chat_bubble_outline_rounded, label: 'WorkChat'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Column(
        children: [
          const _TimelineAppBar(),
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF7F7F7),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFE3E5E9)),
            ),
          ),
          padding: const EdgeInsets.only(top: 6, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (index) {
              final tab = _tabs[index];
              final isActive = index == _selectedIndex;
              final color =
                  isActive ? const Color(0xFF4BAF50) : const Color(0xFF9CA3AF);
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = index),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab.icon, size: 22, color: color),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TimelineAppBar extends StatelessWidget {
  const _TimelineAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFE4E7EC),
              child: Icon(Icons.person, color: Color(0xFF81848F)),
            ),
            Text(
              'Timeline',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B2B57),
              ),
            ),
            Row(
              children: [
                Icon(Icons.notifications_none_rounded, color: Color(0xFF39476A)),
                SizedBox(width: 16),
                Icon(Icons.filter_alt_outlined, color: Color(0xFF39476A)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomTab {
  const _BottomTab({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
