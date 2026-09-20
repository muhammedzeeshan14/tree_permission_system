class MasterService {
  static final List<String> applicationTypes = [
    "PL",
    "GL",
    "MCC",
    "SD",
  ];

  static final Map<String, List<String>> sections = {
    "Bogadi": [
      "Bogadi Beat",
      "Lingambudhi Beat",
    ],
    "Srirampura": [
      "Srirampura Beat",
      "Alanahalli Beat",
    ],
  };

  static final Map<String, String> beatToBFO = {
    "Bogadi Beat": "BFO Bogadi",
    "Lingambudhi Beat": "BFO Lingambudhi",
    "Srirampura Beat": "BFO Srirampura",
    "Alanahalli Beat": "BFO Alanahalli",
  };

  static final Map<String, String> beatToDRFO = {
    "Bogadi Beat": "DRFO Mysuru North",
    "Lingambudhi Beat": "DRFO Mysuru North",
    "Srirampura Beat": "DRFO Mysuru South",
    "Alanahalli Beat": "DRFO Mysuru South",
  };
}