#include <string.h>

#include "brotli/decode.h"
#include "brotli/encode.h"

int main(void) {
  static const uint8_t input[] = "Node.js 26.3.1 bundled Brotli";
  uint8_t compressed[128];
  size_t compressed_size = sizeof(compressed);
  if (!BrotliEncoderCompress(BROTLI_DEFAULT_QUALITY, BROTLI_DEFAULT_WINDOW,
                             BROTLI_MODE_GENERIC, sizeof(input), input,
                             &compressed_size, compressed)) {
    return 1;
  }

  uint8_t output[sizeof(input)];
  size_t output_size = sizeof(output);
  if (BrotliDecoderDecompress(compressed_size, compressed, &output_size,
                              output) != BROTLI_DECODER_RESULT_SUCCESS) {
    return 1;
  }

  return output_size == sizeof(input) &&
                 memcmp(output, input, sizeof(input)) == 0
             ? 0
             : 1;
}
