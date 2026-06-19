#include "node.h"

int main() {
  node::ArrayBufferAllocator* allocator = node::CreateArrayBufferAllocator();
  if (allocator == nullptr) return 1;
  node::FreeArrayBufferAllocator(allocator);
  return 0;
}
