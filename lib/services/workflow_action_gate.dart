/// Synchronous acquisition prevents two clicks from starting before a rebuild.
class WorkflowActionGate {
  final _active = <Object>{};
  bool isRunning(Object page) => _active.contains(page);
  bool acquire(Object page) => _active.add(page);
  void release(Object page) => _active.remove(page);
}
