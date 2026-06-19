#include <array>

#include "nbytes.h"

int main() {
  std::array<char, 8> bytes = {1, 2, 3, 4, 5, 6, 7, 8};
  nbytes::SwapBytes32(bytes.data(), bytes.size());
  constexpr std::array<char, 8> expected = {4, 3, 2, 1, 8, 7, 6, 5};
  return bytes == expected && nbytes::NBYTES_VERSION_MAJOR == 0 &&
                 nbytes::NBYTES_VERSION_MINOR == 1 &&
                 nbytes::NBYTES_VERSION_REVISION == 4
             ? 0
             : 1;
}
