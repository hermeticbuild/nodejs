#include <array>
#include <cstring>
#include <string_view>

#include "ncrypto.h"

int main() {
  if (std::string_view(NCRYPTO_VERSION) != "0.0.1")
    return 1;

  static constexpr std::array<unsigned char, 3> kInput = {'a', 'b', 'c'};
  static constexpr std::array<unsigned char, 32> kExpected = {
      0xba, 0x78, 0x16, 0xbf, 0x8f, 0x01, 0xcf, 0xea, 0x41, 0x41, 0x40,
      0xde, 0x5d, 0xae, 0x22, 0x23, 0xb0, 0x03, 0x61, 0xa3, 0x96, 0x17,
      0x7a, 0x9c, 0xb4, 0x10, 0xff, 0x61, 0xf2, 0x00, 0x15, 0xad,
  };
  const ncrypto::Buffer<const unsigned char> input = {
      .data = kInput.data(),
      .len = kInput.size(),
  };
  auto digest = ncrypto::hashDigest(input, ncrypto::Digest::SHA256);
  if (!digest || digest.size() != kExpected.size())
    return 1;
  if (std::memcmp(digest.get(), kExpected.data(), kExpected.size()) != 0) {
    return 1;
  }

  std::array<unsigned char, 32> random{};
  return ncrypto::CSPRNG(random.data(), random.size()) ? 0 : 1;
}
