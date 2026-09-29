class UserMappingRules {
  static bool conflicts(Map<String,dynamic> existing, {int? id, required String role, int? sectionId, int? beatId}) {
    if(existing['id']==id || existing['isActive']!=1 || existing['role']!=role) return false;
    return role=='RFO' || (role=='DRFO' && existing['sectionId']==sectionId) ||
        (role=='BFO' && existing['beatId']==beatId);
  }
}
