import 'package:flutter/material.dart';

class VerificationNavigationBar extends StatelessWidget {

  final Widget child;

  const VerificationNavigationBar({

    super.key,

    required this.child,

  });

  @override
  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(15),

      child: child,

    );

  }

}