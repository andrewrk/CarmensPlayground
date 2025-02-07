# Where in the world did Carmen's memory go?

This is an allocator playground!

![Carmen](https://raw.githubusercontent.com/ziglang/logo/refs/heads/master/carmen.svg)

Carmen the Allocgator

## Instructions

```
zig build -Doptimize=ReleaseFast
```

Builds and installs example programs (default install prefix is `zig-out/`).

Example:

```
andy@bark ~/d/CarmensPlayground (main)> poop 'zig-out/bin/symmetric c' 'zig-out/bin/symmetric smp'
Benchmark 1 (11 runs): zig-out/bin/symmetric c
  measurement          mean ± σ            min … max           outliers         delta
  wall_time           494ms ± 22.9ms     465ms …  539ms          0 ( 0%)        0%
  peak_rss           1.28GB ±  365KB    1.28GB … 1.28GB          0 ( 0%)        0%
  cpu_cycles         6.24G  ± 65.4M     6.13G  … 6.31G           0 ( 0%)        0%
  instructions       21.9G  ±  264K     21.9G  … 21.9G           0 ( 0%)        0%
  cache_references   55.3M  ± 2.21M     53.2M  … 60.0M           0 ( 0%)        0%
  cache_misses        872K  ± 76.8K      816K  … 1.08M           1 ( 9%)        0%
  branch_misses      3.34M  ± 32.8K     3.29M  … 3.41M           0 ( 0%)        0%
Benchmark 2 (12 runs): zig-out/bin/symmetric smp
  measurement          mean ± σ            min … max           outliers         delta
  wall_time           421ms ± 11.7ms     408ms …  443ms          0 ( 0%)        ⚡- 14.9% ±  3.1%
  peak_rss            640MB ±  301KB     640MB …  641MB          1 ( 8%)        ⚡- 49.9% ±  0.0%
  cpu_cycles         4.02G  ± 15.8M     4.00G  … 4.05G           0 ( 0%)        ⚡- 35.5% ±  0.6%
  instructions       15.5G  ±  201K     15.5G  … 15.5G           2 (17%)        ⚡- 29.3% ±  0.0%
  cache_references   44.9M  ±  603K     44.2M  … 46.2M           0 ( 0%)        ⚡- 18.8% ±  2.5%
  cache_misses       1.54M  ± 97.9K     1.40M  … 1.73M           1 ( 8%)        💩+ 76.5% ±  8.8%
  branch_misses      1.76M  ± 19.4K     1.74M  … 1.81M           1 ( 8%)        ⚡- 47.4% ±  0.7%
```

## Roadmap

 1. Add more handy programs for playing with allocators.
 2. Add a robust testing system for fuzzing and allocator correctness testing.
 3. Look into importing or porting other existing open source allocator test suites.
