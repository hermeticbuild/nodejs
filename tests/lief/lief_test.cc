#include <memory>

#include "LIEF/Abstract/Binary.hpp"
#include "LIEF/Abstract/Parser.hpp"
#include "LIEF/utils.hpp"

int main(int argc, char **argv) {
  const LIEF::lief_version_t version = LIEF::version();
  if (version.major != 0 || version.minor != 17 || version.patch != 0) {
    return 1;
  }
  if (argc != 1)
    return 1;
  std::unique_ptr<LIEF::Binary> binary = LIEF::Parser::parse(argv[0]);
  return binary ? 0 : 1;
}
