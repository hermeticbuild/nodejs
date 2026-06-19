#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include <cerrno>
#include <cstring>
#include <iostream>

namespace {

int Run(const char *description, char *const arguments[]) {
  const pid_t child = fork();
  if (child == -1) {
    std::cerr << "fork failed for " << description << ": "
              << std::strerror(errno) << '\n';
    return 1;
  }
  if (child == 0) {
    execv(arguments[0], arguments);
    std::cerr << "execv failed for " << description << ": "
              << std::strerror(errno) << '\n';
    _exit(127);
  }

  int status = 0;
  if (waitpid(child, &status, 0) == -1) {
    std::cerr << "waitpid failed for " << description << ": "
              << std::strerror(errno) << '\n';
    return 1;
  }
  if (WIFSIGNALED(status)) {
    std::cerr << description << " received signal " << WTERMSIG(status) << '\n';
    return 128 + WTERMSIG(status);
  }
  if (!WIFEXITED(status)) {
    std::cerr << description << " did not exit normally\n";
    return 1;
  }
  if (WEXITSTATUS(status) != 0) {
    std::cerr << description << " exited with status " << WEXITSTATUS(status)
              << '\n';
  }
  return WEXITSTATUS(status);
}

} // namespace

int main(int argc, char **argv) {
  if (argc != 4) {
    std::cerr << "expected d8, JavaScript, and ICU data paths\n";
    return 1;
  }

  char icu_data_flag[] = "--icu-data-file";
  char startup_expression[] = "quit(0)";
  char execute_flag[] = "-e";
  char *startup_arguments[] = {argv[1],      icu_data_flag,      argv[3],
                               execute_flag, startup_expression, nullptr};
  int status = Run("d8 startup", startup_arguments);
  if (status != 0)
    return status;

  char *temporal_arguments[] = {argv[1], icu_data_flag, argv[3], argv[2],
                                nullptr};
  return Run("Temporal.Instant evaluation", temporal_arguments);
}
