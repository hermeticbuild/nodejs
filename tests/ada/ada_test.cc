#include <string_view>

#include "ada.h"

int main() {
  auto url = ada::parse("https://hermeticbuild.dev/nodejs/26.3.1");
  if (!url) {
    return 1;
  }
  return url->get_hostname() == "hermeticbuild.dev" &&
                 url->get_pathname() == "/nodejs/26.3.1" &&
                 std::string_view(ADA_VERSION) == "3.4.4"
             ? 0
             : 1;
}
