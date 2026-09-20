class SessionService {
  SessionService._();

  static final SessionService instance =
      SessionService._();

  int? userId;

  String name = "";

  String username = "";

  String role = "";
  String designation = "";

String rangeName = "";

  int? sectionId;

  int? beatId;

  bool loggedIn = false;

  void login({

    required int userId,

    required String name,

    required String username,

    required String role,

    required int? sectionId,

    required int? beatId,

  }) {

    this.userId = userId;

    this.name = name;

    this.username = username;

    this.role = role;

    this.sectionId = sectionId;

    this.beatId = beatId;

    loggedIn = true;

  }

  void logout() {

    userId = null;

    name = "";

    username = "";

    role = "";

    sectionId = null;

    beatId = null;

    loggedIn = false;

  }

}