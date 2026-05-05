enum UserRole { junior, senior, expert }
enum AppMode { exploration, reporting, survey, production }

enum ReliabilityLevel {
  high,
  medium,
  low,
  reject
}

enum AppDecision {
  autoAccept,
  showWithWarning,
  requireUserConfirmation,
  block
}

class UserContext {
  final UserRole role;
  final AppMode mode;

  const UserContext({
    this.role = UserRole.junior,
    this.mode = AppMode.exploration,
  });
}
