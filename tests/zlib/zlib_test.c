#include <string.h>

#include "zlib.h"

int main(void) {
  static const Bytef input[] = "Node.js 26.3.1 bundled zlib";
  Bytef compressed[128];
  uLongf compressed_size = sizeof(compressed);
  if (compress2(compressed, &compressed_size, input, sizeof(input),
                Z_BEST_COMPRESSION) != Z_OK) {
    return 1;
  }

  Bytef output[sizeof(input)];
  uLongf output_size = sizeof(output);
  if (uncompress(output, &output_size, compressed, compressed_size) != Z_OK) {
    return 1;
  }

  return strcmp(zlibVersion(), "1.3.1") == 0 && output_size == sizeof(input) &&
                 memcmp(output, input, sizeof(input)) == 0
             ? 0
             : 1;
}
