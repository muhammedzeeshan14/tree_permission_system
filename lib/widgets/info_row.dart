import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {

  final String title;
  final String value;

  const InfoRow({

    super.key,

    required this.title,

    required this.value,

  });

  @override
  Widget build(BuildContext context) {

    return Padding(

      padding:
          const EdgeInsets.symmetric(vertical: 3),

      child: Row(

        children: [

          SizedBox(

            width: 120,

            child: Text(

              title,

              style: const TextStyle(

                fontWeight: FontWeight.bold,

              ),

            ),

          ),

          Expanded(

            child: Text(value),

          ),

        ],

      ),

    );

  }

}