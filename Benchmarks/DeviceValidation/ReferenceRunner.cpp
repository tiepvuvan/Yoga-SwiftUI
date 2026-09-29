#include <sstream>
#include <cstring>
#include <cstdlib>
#define main yoga_reference_main
#include "ReferenceMain.cpp"
#undef main
#include "ReferenceRunner.h"

// Called synchronously, once at a time, from the validation application's main actor.
extern "C" char *yoga_reference_run(const char *workload, const char *mode, int iterations, int size) {
  std::string count = std::to_string(iterations), children = std::to_string(size);
  const char *arguments[] = {"reference", workload, mode, count.c_str(), children.c_str(), "1"};
  std::ostringstream output;
  auto previous = std::cout.rdbuf(output.rdbuf());
  int status = yoga_reference_main(6, const_cast<char **>(arguments));
  std::cout.rdbuf(previous);
  if (status != 0) return nullptr;
  return strdup(output.str().c_str());
}
