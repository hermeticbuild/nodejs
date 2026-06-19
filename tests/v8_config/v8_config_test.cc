#include <string_view>

#include "v8-promise.h"

#ifndef ENABLE_DISASSEMBLER
#error "ENABLE_DISASSEMBLER must be defined"
#endif

#ifndef OBJECT_PRINT
#error "OBJECT_PRINT must be defined"
#endif

#ifndef V8_ALLOCATION_FOLDING
#error "V8_ALLOCATION_FOLDING must be defined"
#endif

#ifndef V8_ALLOCATION_SITE_TRACKING
#error "V8_ALLOCATION_SITE_TRACKING must be defined"
#endif

#ifndef V8_ATOMIC_OBJECT_FIELD_WRITES
#error "V8_ATOMIC_OBJECT_FIELD_WRITES must be defined"
#endif

#ifndef V8_ENABLE_JAVASCRIPT_PROMISE_HOOKS
#error "V8_ENABLE_JAVASCRIPT_PROMISE_HOOKS must be defined"
#endif

#ifndef V8_ENABLE_LEAPTIERING
#error "V8_ENABLE_LEAPTIERING must be defined"
#endif

#ifndef V8_ENABLE_REGEXP_INTERPRETER_THREADED_DISPATCH
#error "V8_ENABLE_REGEXP_INTERPRETER_THREADED_DISPATCH must be defined"
#endif

#ifndef V8_ENABLE_SEEDED_ARRAY_INDEX_HASH
#error "V8_ENABLE_SEEDED_ARRAY_INDEX_HASH must be defined"
#endif

#ifndef V8_ENABLE_WEBASSEMBLY
#error "V8_ENABLE_WEBASSEMBLY must be defined"
#endif

#ifndef V8_USE_SIPHASH
#error "V8_USE_SIPHASH must be defined"
#endif

#ifdef V8_31BIT_SMIS_ON_64BIT_ARCH
#error "V8_31BIT_SMIS_ON_64BIT_ARCH must not be defined"
#endif

#ifdef V8_COMPRESS_POINTERS
#error "V8_COMPRESS_POINTERS must not be defined"
#endif

#ifdef V8_COMPRESS_POINTERS_IN_MULTIPLE_CAGES
#error "V8_COMPRESS_POINTERS_IN_MULTIPLE_CAGES must not be defined"
#endif

#ifdef V8_COMPRESS_POINTERS_IN_SHARED_CAGE
#error "V8_COMPRESS_POINTERS_IN_SHARED_CAGE must not be defined"
#endif

#ifdef V8_ENABLE_EXTENSIBLE_RO_SNAPSHOT
#error "V8_ENABLE_EXTENSIBLE_RO_SNAPSHOT must not be defined"
#endif

#ifdef V8_DEPRECATION_WARNINGS
#error "V8_DEPRECATION_WARNINGS must not be defined"
#endif

#ifdef V8_IMMINENT_DEPRECATION_WARNINGS
#error "V8_IMMINENT_DEPRECATION_WARNINGS must not be defined"
#endif

#ifdef V8_ENABLE_SANDBOX
#error "V8_ENABLE_SANDBOX must not be defined"
#endif

#ifdef V8_ENABLE_UNDEFINED_DOUBLE
#error "V8_ENABLE_UNDEFINED_DOUBLE must not be defined"
#endif

#ifdef V8_EXTERNAL_CODE_SPACE
#error "V8_EXTERNAL_CODE_SPACE must not be defined"
#endif

#ifdef V8_STATIC_ROOTS
#error "V8_STATIC_ROOTS must not be defined"
#endif

#if defined(__x86_64__) || defined(_M_X64)
#ifndef V8_SHORT_BUILTIN_CALLS
#error "V8_SHORT_BUILTIN_CALLS must be defined on x86-64"
#endif
#else
#ifdef V8_SHORT_BUILTIN_CALLS
#error "V8_SHORT_BUILTIN_CALLS must not be defined outside x86-64"
#endif
#endif

#if defined(__linux__) && (defined(__x86_64__) || defined(_M_X64))
#ifndef ENABLE_GDB_JIT_INTERFACE
#error "ENABLE_GDB_JIT_INTERFACE must be defined on Linux x86-64"
#endif
#else
#ifdef ENABLE_GDB_JIT_INTERFACE
#error "ENABLE_GDB_JIT_INTERFACE must not be defined outside Linux x86-64"
#endif
#endif

static_assert(v8::Promise::kEmbedderFieldCount == 1);
static_assert(std::string_view(V8_EMBEDDER_STRING) == "-node.20");

int main() { return 0; }
