/// Highlighted row of a list whose rows can change under it.
///
/// Holds the row's **id**, not its position. Resolved during build, never in
/// a post-frame callback. Port of `lib/hooks/use-row-cursor.ts`.
class BeuiRowCursor {
  BeuiRowCursor();

  String? _id;
  String _query = '';

  String? get id => _id;

  int activeIndex(List<String> rows, String query) {
    if (_id == null || _query != query) return rows.isEmpty ? -1 : 0;
    final at = rows.indexOf(_id!);
    if (at < 0) {
      _id = null;
      return rows.isEmpty ? -1 : 0;
    }
    return at;
  }

  void moveTo(String? id, String query) {
    _query = query;
    _id = id;
  }

  void moveActive(List<String> rows, String query, int direction) {
    if (rows.isEmpty) return;
    final last = rows.length - 1;
    final at = activeIndex(rows, query).clamp(0, last);
    final next = (at + direction).clamp(0, last);
    _id = rows[next];
    _query = query;
  }

  void clear() {
    _id = null;
    _query = '';
  }
}
