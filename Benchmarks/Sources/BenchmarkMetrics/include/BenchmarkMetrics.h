#ifndef YOGA_BENCHMARK_METRICS_H
#define YOGA_BENCHMARK_METRICS_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef struct {
    uint64_t wall_ns;
    uint64_t cpu_ns;
    uint64_t cycles;
    uint64_t instructions;
    uint64_t heap_bytes;
    int hardware_counters_available;
} YogaBenchmarkMetrics;
YogaBenchmarkMetrics yoga_benchmark_metrics(void);
typedef struct {
    uint64_t allocations;
    uint64_t allocated_bytes;
    int available;
} YogaAllocationMetrics;
int yoga_benchmark_allocations_begin(void);
YogaAllocationMetrics yoga_benchmark_allocations_end(void);
#ifdef __cplusplus
}
#endif
#endif
