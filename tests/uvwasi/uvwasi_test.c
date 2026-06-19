#include <string.h>

#include "uvwasi.h"

int main(void) {
  if (strcmp(UVWASI_VERSION_STRING, "0.0.23") != 0) {
    return 1;
  }

  uvwasi_options_t options;
  uvwasi_options_init(&options);

  uvwasi_t uvwasi;
  if (uvwasi_init(&uvwasi, &options) != UVWASI_ESUCCESS) {
    return 1;
  }
  uvwasi_destroy(&uvwasi);
  return 0;
}
