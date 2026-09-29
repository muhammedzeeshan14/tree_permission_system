import 'package:flutter/material.dart';
import '../screens/tree_permission/application_search_screen.dart';

class ApplicationSearchAction extends StatelessWidget {
  const ApplicationSearchAction({super.key});
  static void open(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const ApplicationSearchScreen()));
  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => open(context), icon: const Icon(Icons.search),
    label: const Text('SEARCH'),
  );
}
