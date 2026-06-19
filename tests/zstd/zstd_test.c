#include <string.h>

#include "zstd.h"

int main(void) {
  static const char input[] = "Node.js 26.3.1 bundled zstd";
  char compressed[128];
  const size_t compressed_size =
      ZSTD_compress(compressed, sizeof(compressed), input, sizeof(input), 3);
  if (ZSTD_isError(compressed_size)) {
    return 1;
  }

  char output[sizeof(input)];
  const size_t output_size =
      ZSTD_decompress(output, sizeof(output), compressed, compressed_size);
  if (ZSTD_isError(output_size)) {
    return 1;
  }

  return ZSTD_versionNumber() == ZSTD_VERSION_NUMBER &&
                 strcmp(ZSTD_versionString(), "1.5.7") == 0 &&
                 output_size == sizeof(input) &&
                 memcmp(output, input, sizeof(input)) == 0
             ? 0
             : 1;
}
