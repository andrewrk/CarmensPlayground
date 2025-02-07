# Where in the world did Carmen's memory go?

This is an allocator playground!

![Carmen](https://raw.githubusercontent.com/ziglang/logo/refs/heads/master/carmen.svg)

Carmen the Allocgator

## Instructions

```
zig build -Doptimize=ReleaseFast
```

Builds and installs example programs (default install prefix is `zig-out/`).

## Example Runs

### symmetric

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

### asymmetric

```
Benchmark 1 (17 runs): zig-out/bin/asymmetric c
  measurement          mean ± σ            min … max           outliers         delta
  wall_time           308ms ± 11.3ms     293ms …  335ms          2 (12%)        0%
  peak_rss           1.50MB ±  174KB    1.12MB … 1.68MB          0 ( 0%)        0%
  cpu_cycles         2.13G  ± 52.7M     2.00G  … 2.20G           2 (12%)        0%
  instructions       1.62G  ±  456K     1.62G  … 1.62G           0 ( 0%)        0%
  cache_references   9.79M  ±  758K     8.88M  … 11.3M           0 ( 0%)        0%
  cache_misses       6.35M  ±  129K     6.04M  … 6.55M           0 ( 0%)        0%
  branch_misses       574K  ± 50.0K      449K  …  642K           2 (12%)        0%
Benchmark 2 (30 runs): zig-out/bin/asymmetric smp
  measurement          mean ± σ            min … max           outliers         delta
  wall_time           167ms ± 6.30ms     156ms …  191ms          1 ( 3%)        ⚡- 45.9% ±  1.7%
  peak_rss           33.6MB ±  294KB    33.1MB … 34.7MB          1 ( 3%)        💩+2139.0% ± 10.5%
  cpu_cycles          919M  ± 28.0M      859M  … 1.03G           4 (13%)        ⚡- 56.9% ±  1.1%
  instructions       1.49G  ±  768K     1.49G  … 1.49G           1 ( 3%)        ⚡-  8.0% ±  0.0%
  cache_references   5.28M  ±  947K     4.75M  … 9.76M           2 ( 7%)        ⚡- 46.1% ±  5.5%
  cache_misses       2.04M  ± 74.1K     1.84M  … 2.25M           3 (10%)        ⚡- 67.9% ±  0.9%
  branch_misses       257K  ± 14.5K      238K  …  299K           1 ( 3%)        ⚡- 55.3% ±  3.4%
```

## Roadmap

 1. Add more handy programs for playing with allocators.
 2. Add a robust testing system for fuzzing and allocator correctness testing.
 3. Look into importing or porting other existing open source allocator test suites.
