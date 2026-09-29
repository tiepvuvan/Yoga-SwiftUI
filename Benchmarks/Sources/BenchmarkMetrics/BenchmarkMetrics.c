#include "BenchmarkMetrics.h"
#include <time.h>
#include <stdlib.h>
#include <stdatomic.h>
#ifdef __APPLE__
#include <dlfcn.h>
#include <TargetConditionals.h>
#if TARGET_OS_OSX
#include <libproc.h>
#endif
#include <malloc/malloc.h>
#include <unistd.h>
#endif

// Development-only macOS diagnostic hook. Runtime detection and a real malloc
// probe are required: unavailable logging must never be reported as zero work.
// Event format: apple-oss-distributions/libmalloc, src/malloc.c.
#if defined(__APPLE__) && TARGET_OS_OSX
typedef void (*YogaMallocLogger)(uint32_t, uintptr_t, uintptr_t, uintptr_t, uintptr_t, uint32_t);
static YogaMallocLogger *logger_slot;
static _Atomic uint64_t allocation_count;
static _Atomic uint64_t allocation_bytes;
static int allocation_logging_active;

static void allocation_logger(uint32_t type, uintptr_t arg1, uintptr_t arg2,
                              uintptr_t arg3, uintptr_t result, uint32_t skip) {
    (void)arg1; (void)skip;
    if ((type & 2) && (type & 8) && result) {
        atomic_fetch_add_explicit(&allocation_count, 1, memory_order_relaxed);
        atomic_fetch_add_explicit(&allocation_bytes, (type & 4) ? arg3 : arg2, memory_order_relaxed);
    }
}
#endif

int yoga_benchmark_allocations_begin(void) {
#if defined(__APPLE__) && TARGET_OS_OSX
    logger_slot = (YogaMallocLogger *)dlsym(RTLD_DEFAULT, "malloc_logger");
    if (!logger_slot || __atomic_load_n(logger_slot, __ATOMIC_RELAXED)) return 0;
    atomic_store(&allocation_count, 0);
    atomic_store(&allocation_bytes, 0);
    __atomic_store_n(logger_slot, allocation_logger, __ATOMIC_RELAXED);
    void *probe = malloc(71);
    __asm__ volatile("" : : "r"(probe) : "memory");
    free(probe);
    if (!atomic_load(&allocation_count)) {
        __atomic_store_n(logger_slot, NULL, __ATOMIC_RELAXED);
        return 0;
    }
    atomic_store(&allocation_count, 0);
    atomic_store(&allocation_bytes, 0);
    allocation_logging_active = 1;
    return 1;
#else
    return 0;
#endif
}

YogaAllocationMetrics yoga_benchmark_allocations_end(void) {
    YogaAllocationMetrics result = {0};
#if defined(__APPLE__) && TARGET_OS_OSX
    if (allocation_logging_active) {
        __atomic_store_n(logger_slot, NULL, __ATOMIC_RELAXED);
        result.allocations = atomic_load(&allocation_count);
        result.allocated_bytes = atomic_load(&allocation_bytes);
        result.available = 1;
        allocation_logging_active = 0;
    }
#endif
    return result;
}

YogaBenchmarkMetrics yoga_benchmark_metrics(void) {
    YogaBenchmarkMetrics result = {0};
    struct timespec wall, cpu;
    clock_gettime(CLOCK_MONOTONIC, &wall);
    clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &cpu);
    result.wall_ns = (uint64_t)wall.tv_sec * 1000000000 + wall.tv_nsec;
    result.cpu_ns = (uint64_t)cpu.tv_sec * 1000000000 + cpu.tv_nsec;
#if defined(__APPLE__) && TARGET_OS_OSX
    struct rusage_info_v4 usage = {0};
    if (proc_pid_rusage(getpid(), RUSAGE_INFO_V4, (rusage_info_t *)&usage) == 0) {
        result.cycles = usage.ri_cycles;
        result.instructions = usage.ri_instructions;
        result.hardware_counters_available = usage.ri_cycles > 0;
    }
#endif
#ifdef __APPLE__
    malloc_statistics_t statistics = {0};
    malloc_zone_statistics(NULL, &statistics);
    result.heap_bytes = statistics.size_in_use;
#endif
    return result;
}
