#include <string_view>

#include "simdjson.h"

int main() {
  simdjson::dom::parser parser;
  simdjson::padded_string json(std::string_view(R"({"release":"26.3.1"})"));
  simdjson::dom::element document;
  if (parser.parse(json).get(document) != simdjson::SUCCESS) {
    return 1;
  }

  std::string_view release;
  if (document["release"].get(release) != simdjson::SUCCESS) {
    return 1;
  }
  return release == "26.3.1" && simdjson::SIMDJSON_VERSION_MAJOR == 4 &&
                 simdjson::SIMDJSON_VERSION_MINOR == 6 &&
                 simdjson::SIMDJSON_VERSION_REVISION == 4
             ? 0
             : 1;
}
