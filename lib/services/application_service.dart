import '../models/application_model.dart';

class ApplicationService {
 static void submitToBFO(ApplicationModel application) {
  application.status = "Pending BFO";
}
  static final List<ApplicationModel> _applications = [];

  static final Map<String, int> _runningNumbers = {};

  static String generateOfficeNumber(String applicationType) {
    final year = DateTime.now().year.toString();

    final key = "$applicationType-$year";

    _runningNumbers[key] = (_runningNumbers[key] ?? 0) + 1;

    final runningNo = _runningNumbers[key]
        .toString()
        .padLeft(4, '0');

    return "MYS/RFO/$applicationType/$year/$runningNo";
  }

  static void saveApplication(ApplicationModel application) {
    _applications.add(application);
  }

  static List<ApplicationModel> getApplications() {
    return _applications;
  }

  static void updateApplication(
      int index,
      ApplicationModel application,
      ) {
    _applications[index] = application;
  }

  static void deleteApplication(int index) {
    _applications.removeAt(index);
  }
}