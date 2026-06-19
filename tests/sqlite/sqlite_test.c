#include <string.h>

#include "sqlite3.h"

int main(void) {
  if (strcmp(sqlite3_libversion(), "3.53.1") != 0 ||
      !sqlite3_compileoption_used("ENABLE_FTS5") ||
      !sqlite3_compileoption_used("ENABLE_SESSION")) {
    return 1;
  }

  sqlite3 *database = 0;
  if (sqlite3_open(":memory:", &database) != SQLITE_OK) {
    return 1;
  }

  char *error = 0;
  const int result = sqlite3_exec(database,
                                  "CREATE TABLE releases(version TEXT);"
                                  "INSERT INTO releases VALUES('26.3.1');",
                                  0, 0, &error);
  sqlite3_free(error);
  sqlite3_close(database);
  return result == SQLITE_OK ? 0 : 1;
}
