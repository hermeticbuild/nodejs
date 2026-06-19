#include <string.h>
#include <uv.h>

int main(void) {
  return strcmp(uv_version_string(), "1.52.1");
}
