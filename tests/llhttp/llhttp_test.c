#include <string.h>

#include "llhttp.h"

int main(void) {
  static const char request[] =
      "GET /nodejs HTTP/1.1\r\nHost: hermeticbuild.dev\r\n\r\n";
  llhttp_settings_t settings;
  llhttp_settings_init(&settings);

  llhttp_t parser;
  llhttp_init(&parser, HTTP_REQUEST, &settings);
  if (llhttp_execute(&parser, request, strlen(request)) != HPE_OK) {
    return 1;
  }
  if (llhttp_finish(&parser) != HPE_OK) {
    return 1;
  }

  return parser.method == HTTP_GET && LLHTTP_VERSION_MAJOR == 9 &&
                 LLHTTP_VERSION_MINOR == 4 && LLHTTP_VERSION_PATCH == 2
             ? 0
             : 1;
}
