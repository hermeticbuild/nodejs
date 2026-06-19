#define _GNU_SOURCE

#include <dlfcn.h>
#include <errno.h>
#include <netdb.h>
#include <pthread.h>
#include <string.h>

typedef int (*getaddrinfo_function)(const char *, const char *,
                                    const struct addrinfo *,
                                    struct addrinfo **);

static getaddrinfo_function system_getaddrinfo;
static pthread_once_t system_getaddrinfo_once = PTHREAD_ONCE_INIT;

static void find_system_getaddrinfo(void) {
  union {
    void *object;
    getaddrinfo_function function;
  } symbol = {dlsym(RTLD_NEXT, "getaddrinfo")};
  system_getaddrinfo = symbol.function;
}

int getaddrinfo(const char *node, const char *service,
                const struct addrinfo *hints, struct addrinfo **result) {
  struct addrinfo localhost_hints;
  int return_code;

  pthread_once(&system_getaddrinfo_once, find_system_getaddrinfo);
  if (system_getaddrinfo == NULL) {
    errno = ENOSYS;
    return EAI_SYSTEM;
  }

  return_code = system_getaddrinfo(node, service, hints, result);
  if (return_code != 0 && node != NULL && hints != NULL &&
      strcmp(node, "localhost") == 0) {
    const char *localhost_address =
        hints->ai_family == AF_INET6 ? "::1" : "127.0.0.1";
    localhost_hints = *hints;
    localhost_hints.ai_flags = AI_NUMERICHOST;
    return system_getaddrinfo(localhost_address, service, &localhost_hints,
                              result);
  }

  return return_code;
}
