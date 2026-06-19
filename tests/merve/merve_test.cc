#include <string_view>

#include "merve.h"

int main() {
  auto analysis = lexer::parse_commonjs(
      "exports.release = '26.3.1'; module.exports.build = true;");
  if (!analysis || analysis->exports.size() != 2) {
    return 1;
  }
  return lexer::get_string_view(analysis->exports[0]) == "release" &&
                 lexer::get_string_view(analysis->exports[1]) == "build" &&
                 std::string_view(MERVE_VERSION) == "1.2.2"
             ? 0
             : 1;
}
