#include "hdr/hdr_histogram.h"
#include "hdr/hdr_histogram_version.h"

int main(void) {
  struct hdr_histogram *histogram = 0;
  if (hdr_init(1, 1000000, 3, &histogram) != 0) {
    return 1;
  }

  const int valid = hdr_record_value(histogram, 2631) &&
                    hdr_value_at_percentile(histogram, 100.0) == 2631 &&
                    HDR_HISTOGRAM_VERSION[0] == '0';
  hdr_close(histogram);
  return valid ? 0 : 1;
}
