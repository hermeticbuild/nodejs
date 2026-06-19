#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct entry {
  char *destination;
  char *mtree_line;
};

struct entries {
  struct entry *items;
  size_t length;
  size_t capacity;
};

static void *allocate(size_t size) {
  void *result = malloc(size);
  if (result == NULL) {
    fprintf(stderr, "release_mtree: allocation failed\n");
    exit(1);
  }
  return result;
}

static void *resize(void *value, size_t size) {
  void *result = realloc(value, size);
  if (result == NULL) {
    fprintf(stderr, "release_mtree: allocation failed\n");
    exit(1);
  }
  return result;
}

static char *duplicate_string(const char *value) {
  size_t size = strlen(value) + 1;
  char *result = allocate(size);
  memcpy(result, value, size);
  return result;
}

static int read_line(FILE *input, char **buffer, size_t *capacity) {
  size_t length = 0;
  int character;
  if (*buffer == NULL) {
    *capacity = 256;
    *buffer = allocate(*capacity);
  }
  while ((character = fgetc(input)) != EOF) {
    if (length + 1 >= *capacity) {
      *capacity *= 2;
      *buffer = resize(*buffer, *capacity);
    }
    if (character == '\n') {
      break;
    }
    (*buffer)[length++] = (char)character;
  }
  if (ferror(input)) {
    return -1;
  }
  if (character == EOF && length == 0) {
    return 0;
  }
  if (length > 0 && (*buffer)[length - 1] == '\r') {
    --length;
  }
  (*buffer)[length] = '\0';
  return 1;
}

static int token_equals(const char *metadata, const char *expected) {
  size_t expected_length = strlen(expected);
  const char *cursor = metadata;
  while (*cursor != '\0') {
    const char *start;
    while (isspace((unsigned char)*cursor)) {
      ++cursor;
    }
    start = cursor;
    while (*cursor != '\0' && !isspace((unsigned char)*cursor)) {
      ++cursor;
    }
    if ((size_t)(cursor - start) == expected_length &&
        memcmp(start, expected, expected_length) == 0) {
      return 1;
    }
  }
  return 0;
}

static char *token_value(const char *metadata, const char *prefix) {
  size_t prefix_length = strlen(prefix);
  const char *cursor = metadata;
  while (*cursor != '\0') {
    const char *start;
    const char *end;
    while (isspace((unsigned char)*cursor)) {
      ++cursor;
    }
    start = cursor;
    while (*cursor != '\0' && !isspace((unsigned char)*cursor)) {
      ++cursor;
    }
    end = cursor;
    if ((size_t)(end - start) > prefix_length &&
        memcmp(start, prefix, prefix_length) == 0) {
      size_t value_length = (size_t)(end - start) - prefix_length;
      char *value = allocate(value_length + 1);
      memcpy(value, start + prefix_length, value_length);
      value[value_length] = '\0';
      return value;
    }
  }
  return NULL;
}

static void append_entry(struct entries *entries, char *destination,
                         char *mtree_line) {
  if (entries->length == entries->capacity) {
    entries->capacity = entries->capacity == 0 ? 256 : entries->capacity * 2;
    entries->items =
        resize(entries->items, entries->capacity * sizeof(entries->items[0]));
  }
  entries->items[entries->length].destination = destination;
  entries->items[entries->length].mtree_line = mtree_line;
  ++entries->length;
}

static int compare_entries(const void *left_value, const void *right_value) {
  const struct entry *left = left_value;
  const struct entry *right = right_value;
  return strcmp(left->destination, right->destination);
}

static int valid_root(const char *root) {
  static const char prefix[] = "node-v26.3.1-";
  const unsigned char *cursor = (const unsigned char *)root;
  if (strncmp(root, prefix, sizeof(prefix) - 1) != 0) {
    return 0;
  }
  for (; *cursor != '\0'; ++cursor) {
    if (!isalnum(*cursor) && *cursor != '.' && *cursor != '-') {
      return 0;
    }
  }
  return 1;
}

static char *destination_path(const char *root, const char *source) {
  static const char source_root[] = "release";
  const char *suffix;
  size_t size;
  char *result;
  if (strcmp(source, source_root) == 0 || strcmp(source, "release/") == 0) {
    return duplicate_string(root);
  }
  if (strncmp(source, "release/", sizeof(source_root)) != 0) {
    return NULL;
  }
  suffix = source + sizeof(source_root);
  size = strlen(root) + 1 + strlen(suffix) + 1;
  result = allocate(size);
  snprintf(result, size, "%s/%s", root, suffix);
  return result;
}

static char *directory_mtree_line(const char *destination) {
  const char *suffix = strchr(destination, '/') == NULL ? "/" : "";
  size_t capacity = strlen(destination) + 160;
  char *result = allocate(capacity);
  int length = snprintf(result, capacity,
                        "%s%s uid=0 gid=0 uname=root gname=root "
                        "time=1704067200 mode=0755 type=dir nlink=1",
                        destination, suffix);
  if (length < 0 || (size_t)length >= capacity) {
    fprintf(stderr, "release_mtree: failed to format %s\n", destination);
    exit(1);
  }
  return result;
}

static char *file_mtree_line(const char *destination, const char *content,
                             int executable) {
  const char *mode = executable ? "0755" : "0644";
  size_t capacity;
  char *result;
  int length;
  capacity = strlen(destination) + strlen(content) + 160;
  result = allocate(capacity);
  length = snprintf(result, capacity,
                    "%s uid=0 gid=0 uname=root gname=root time=1704067200 "
                    "mode=%s type=file nlink=1 content=%s",
                    destination, mode, content);
  if (length < 0 || (size_t)length >= capacity) {
    fprintf(stderr, "release_mtree: failed to format %s\n", destination);
    exit(1);
  }
  return result;
}

static int valid_relative_path(const char *path) {
  return path[0] != '\0' && path[0] != '/' && strstr(path, "../") == NULL &&
         strcmp(path, "..") != 0;
}

static int is_executable(int argc, char **argv, const char *root,
                         const char *destination) {
  size_t root_length = strlen(root);
  const char *relative;
  int index;
  if (strncmp(destination, root, root_length) != 0 ||
      destination[root_length] != '/') {
    return 0;
  }
  relative = destination + root_length + 1;
  for (index = 4; index < argc; ++index) {
    if (strcmp(relative, argv[index]) == 0) {
      return 1;
    }
  }
  return 0;
}

static char *link_mtree_line(const char *destination, const char *target) {
  size_t capacity = strlen(destination) + strlen(target) + 160;
  char *result = allocate(capacity);
  int length = snprintf(result, capacity,
                        "%s uid=0 gid=0 uname=root gname=root "
                        "time=1704067200 mode=0777 type=link nlink=1 link=%s",
                        destination, target);
  if (length < 0 || (size_t)length >= capacity) {
    fprintf(stderr, "release_mtree: failed to format %s\n", destination);
    exit(1);
  }
  return result;
}

static int contains_destination(const struct entries *entries,
                                const char *destination) {
  size_t index;
  for (index = 0; index < entries->length; ++index) {
    if (strcmp(entries->items[index].destination, destination) == 0) {
      return 1;
    }
  }
  return 0;
}

static void append_npm_link(struct entries *entries, const char *root,
                            const char *name, const char *target) {
  size_t destination_size = strlen(root) + strlen("/bin/") + strlen(name) + 1;
  char *destination = allocate(destination_size);
  snprintf(destination, destination_size, "%s/bin/%s", root, name);
  append_entry(entries, destination, link_mtree_line(destination, target));
}

int main(int argc, char **argv) {
  const char *input_path;
  const char *output_path;
  const char *root;
  FILE *input;
  FILE *output;
  char *line = NULL;
  size_t line_capacity = 0;
  int read_result;
  struct entries entries = {0};
  size_t index;
  char required_node[128];
  char required_npm[192];
  char required_npx[192];

  if (argc < 4 || !valid_root(argv[3])) {
    fprintf(stderr, "usage: release_mtree INPUT OUTPUT node-v26.3.1-PLATFORM "
                    "[EXECUTABLE ...]\n");
    return 2;
  }
  input_path = argv[1];
  output_path = argv[2];
  root = argv[3];
  for (index = 4; index < (size_t)argc; ++index) {
    if (!valid_relative_path(argv[index])) {
      fprintf(stderr, "release_mtree: invalid executable path %s\n",
              argv[index]);
      return 2;
    }
  }

  input = fopen(input_path, "rb");
  if (input == NULL) {
    fprintf(stderr, "release_mtree: cannot open %s: %s\n", input_path,
            strerror(errno));
    return 1;
  }
  while ((read_result = read_line(input, &line, &line_capacity)) > 0) {
    char *metadata;
    char *cursor = line;
    char *destination;
    while (*cursor != '\0' && !isspace((unsigned char)*cursor)) {
      ++cursor;
    }
    if (*cursor == '\0') {
      fprintf(stderr, "release_mtree: malformed mtree line: %s\n", line);
      return 1;
    }
    *cursor++ = '\0';
    metadata = cursor;
    destination = destination_path(root, line);
    if (destination == NULL) {
      fprintf(stderr, "release_mtree: path is outside release/: %s\n", line);
      return 1;
    }
    if (token_equals(metadata, "type=dir")) {
      append_entry(&entries, destination, directory_mtree_line(destination));
    } else if (token_equals(metadata, "type=file")) {
      char *content = token_value(metadata, "content=");
      if (content == NULL) {
        fprintf(stderr, "release_mtree: file has no content: %s\n", line);
        return 1;
      }
      append_entry(
          &entries, destination,
          file_mtree_line(destination, content,
                          is_executable(argc, argv, root, destination)));
      free(content);
    } else {
      fprintf(stderr, "release_mtree: unsupported entry type: %s\n", line);
      return 1;
    }
  }
  if (read_result < 0 || fclose(input) != 0) {
    fprintf(stderr, "release_mtree: cannot read %s: %s\n", input_path,
            strerror(errno));
    return 1;
  }
  free(line);

  snprintf(required_node, sizeof(required_node), "%s/bin/node", root);
  snprintf(required_npm, sizeof(required_npm),
           "%s/lib/node_modules/npm/bin/npm-cli.js", root);
  snprintf(required_npx, sizeof(required_npx),
           "%s/lib/node_modules/npm/bin/npx-cli.js", root);
  if (!contains_destination(&entries, required_node) ||
      !contains_destination(&entries, required_npm) ||
      !contains_destination(&entries, required_npx)) {
    fprintf(stderr,
            "release_mtree: release tree is missing node, npm, or npx\n");
    return 1;
  }
  append_npm_link(&entries, root, "npm",
                  "../lib/node_modules/npm/bin/npm-cli.js");
  append_npm_link(&entries, root, "npx",
                  "../lib/node_modules/npm/bin/npx-cli.js");

  qsort(entries.items, entries.length, sizeof(entries.items[0]),
        compare_entries);
  for (index = 1; index < entries.length; ++index) {
    if (strcmp(entries.items[index - 1].destination,
               entries.items[index].destination) == 0) {
      fprintf(stderr, "release_mtree: duplicate destination %s\n",
              entries.items[index].destination);
      return 1;
    }
  }

  output = fopen(output_path, "wb");
  if (output == NULL) {
    fprintf(stderr, "release_mtree: cannot open %s: %s\n", output_path,
            strerror(errno));
    return 1;
  }
  for (index = 0; index < entries.length; ++index) {
    if (fprintf(output, "%s\n", entries.items[index].mtree_line) < 0) {
      fprintf(stderr, "release_mtree: cannot write %s: %s\n", output_path,
              strerror(errno));
      fclose(output);
      remove(output_path);
      return 1;
    }
  }
  if (fclose(output) != 0) {
    fprintf(stderr, "release_mtree: cannot close %s: %s\n", output_path,
            strerror(errno));
    remove(output_path);
    return 1;
  }

  for (index = 0; index < entries.length; ++index) {
    free(entries.items[index].destination);
    free(entries.items[index].mtree_line);
  }
  free(entries.items);
  return 0;
}
