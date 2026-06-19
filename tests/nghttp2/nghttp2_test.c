#include <string.h>

#include "nghttp2/nghttp2.h"

int main(void) {
  const nghttp2_info *info = nghttp2_version(0);
  if (info == 0 || info->version_num != NGHTTP2_VERSION_NUM ||
      strcmp(info->version_str, "1.69.0") != 0) {
    return 1;
  }

  nghttp2_session_callbacks *callbacks = 0;
  if (nghttp2_session_callbacks_new(&callbacks) != 0) {
    return 1;
  }

  nghttp2_session *session = 0;
  const int result = nghttp2_session_client_new(&session, callbacks, 0);
  nghttp2_session_callbacks_del(callbacks);
  if (result != 0) {
    return 1;
  }
  nghttp2_session_del(session);
  return 0;
}
