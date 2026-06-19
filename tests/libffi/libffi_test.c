#include <ffi.h>

static int add(int left, int right) { return left + right; }

int main(void) {
  ffi_cif cif;
  ffi_type *argument_types[] = {&ffi_type_sint, &ffi_type_sint};
  if (ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 2, &ffi_type_sint, argument_types) !=
      FFI_OK) {
    return 1;
  }

  int left = 20;
  int right = 22;
  void *arguments[] = {&left, &right};
  int result = 0;
  ffi_call(&cif, FFI_FN(add), &result, arguments);
  return result == 42 ? 0 : 1;
}
