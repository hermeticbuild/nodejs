#include <node_api.h>
#include <openssl/opensslv.h>

static napi_value Answer(napi_env env, napi_callback_info info) {
  napi_value result;
  napi_create_int32(env, 42, &result);
  return result;
}

NAPI_MODULE_INIT() {
  napi_value answer;
  napi_create_function(env, "answer", NAPI_AUTO_LENGTH, Answer, nullptr, &answer);
  napi_set_named_property(env, exports, "answer", answer);
  return exports;
}
