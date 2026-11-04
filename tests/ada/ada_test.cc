#include <string_view>

#include "ada.h"

int main() {
  auto url = ada::parse("https://hermeticbuild.dev/nodejs/26.13.0");
  if (!url) {
    return 1;
  }
  return url->get_hostname() == "hermeticbuild.dev" &&
                 url->get_pathname() == "/nodejs/26.13.0" &&
                 std::string_view(ADA_VERSION) == "4.0.0"
             ? 0
             : 1;
}
