#include <string.h>

#include "ares.h"

int main(void) {
  if (ares_library_init(ARES_LIB_INIT_ALL) != ARES_SUCCESS) {
    return 1;
  }

  int version = 0;
  const char *version_string = ares_version(&version);
  const int valid =
      version == ARES_VERSION && strcmp(version_string, "1.34.6") == 0;
  ares_library_cleanup();
  return valid ? 0 : 1;
}
