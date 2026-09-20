import 'package:flutter/material.dart';

class ApplicationVerificationPage extends StatelessWidget {

  final Widget child;

  const ApplicationVerificationPage({

    super.key,

    required this.child,

  });

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(

      padding: const EdgeInsets.all(16),

      child: child,

    );

  }

}