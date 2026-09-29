#pragma once
#ifdef __cplusplus
extern "C" {
#endif
// Development validation only. Returned UTF-8 is released with free().
char *yoga_reference_run(const char *workload, const char *mode, int iterations, int size);

#ifdef __cplusplus
}
#endif
