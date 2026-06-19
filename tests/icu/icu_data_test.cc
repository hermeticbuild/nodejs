#include <unicode/udat.h>
#include <unicode/uloc.h>
#include <unicode/utypes.h>

#include <iostream>

int main() {
  const int32_t locale_count = uloc_countAvailable();
  if (locale_count < 500) {
    std::cerr << "expected at least 500 ICU locales, found " << locale_count
              << '\n';
    return 1;
  }

  UErrorCode status = U_ZERO_ERROR;
  const UChar utc[] = {0x55, 0x54, 0x43, 0};
  UDateFormat *format =
      udat_open(UDAT_FULL, UDAT_NONE, "fr_FR", utc, -1, nullptr, 0, &status);
  if (U_FAILURE(status)) {
    std::cerr << "udat_open failed: " << u_errorName(status) << '\n';
    return 1;
  }

  UChar output[128];
  const int32_t length = udat_format(format, 0, output, 128, nullptr, &status);
  udat_close(format);
  if (U_FAILURE(status) || length <= 0) {
    std::cerr << "udat_format failed: " << u_errorName(status) << '\n';
    return 1;
  }

  return 0;
}
