#include <string_view>

#include "simdjson.h"

int main() {
  simdjson::dom::parser parser;
  simdjson::padded_string json(std::string_view(R"({"release":"26.13.0"})"));
  simdjson::dom::element document;
  if (parser.parse(json).get(document) != simdjson::SUCCESS) {
    return 1;
  }

  std::string_view release;
  if (document["release"].get(release) != simdjson::SUCCESS) {
    return 1;
  }
  return release == "26.13.0" && simdjson::SIMDJSON_VERSION_MAJOR == 5 &&
                 simdjson::SIMDJSON_VERSION_MINOR == 0 &&
                 simdjson::SIMDJSON_VERSION_REVISION == 3
             ? 0
             : 1;
}
