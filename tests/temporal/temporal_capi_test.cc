#include <cstdint>
#include <memory>
#include <utility>

#include "temporal_rs/Instant.hpp"

int main() {
  auto result = temporal_rs::Instant::from_epoch_milliseconds(0);
  if (!result.is_ok())
    return 1;

  auto instant = std::move(result).ok();
  if (!instant.has_value())
    return 1;
  return (*instant)->epoch_milliseconds() == 0 ? 0 : 1;
}
