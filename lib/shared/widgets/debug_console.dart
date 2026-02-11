import 'package:flutter/material.dart';

/// A simple debug console to display logs in-app.
class DebugConsole extends StatefulWidget {
  final List<String> logs;
  final VoidCallback onClear;
  final bool visible;

  const DebugConsole({
    super.key,
    required this.logs,
    required this.onClear,
    this.visible = false,
  });

  @override
  State<DebugConsole> createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(DebugConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && widget.logs.length != oldWidget.logs.length) {
      // Auto-scroll to bottom on new logs
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.black.withValues(alpha: 0.8),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DEBUG CONSOLE',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white, size: 16),
                  onPressed: widget.onClear,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          // Logs
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: widget.logs.length,
              itemBuilder: (context, index) {
                return Text(
                  widget.logs[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
