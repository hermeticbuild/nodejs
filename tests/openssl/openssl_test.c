#include <string.h>

#include "openssl/crypto.h"
#include "openssl/evp.h"

int main(void) {
  if (strncmp(OpenSSL_version(OPENSSL_VERSION), "OpenSSL 3.5.7 ", 14) != 0) {
    return 1;
  }

  static const unsigned char input[] = "Node.js 26.3.1 bundled OpenSSL";
  unsigned char digest[EVP_MAX_MD_SIZE];
  unsigned int digest_size = 0;
  if (!EVP_Digest(input, sizeof(input), digest, &digest_size, EVP_sha256(),
                  0)) {
    return 1;
  }
  return digest_size == 32 ? 0 : 1;
}
