import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerUtil {

  static Future<void> pickDate(
    BuildContext context,
    TextEditingController controller,
  ) async {

    DateTime initialDate = DateTime.now();

    try {

      if (controller.text.isNotEmpty &&
          controller.text != "DD/MM/YYYY") {

        initialDate = DateFormat(
          "dd/MM/yyyy",
        ).parse(controller.text);

      }

    } catch (_) {}

    final DateTime? picked = await showDatePicker(

      context: context,

      initialDate: initialDate,

      firstDate: DateTime(2000),

      lastDate: DateTime(2100),

    );

    if (picked != null) {

      controller.text =
          DateFormat("dd/MM/yyyy").format(picked);

    }

  }

}