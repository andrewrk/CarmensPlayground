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
Benchmark 1 (10 runs): zig-out/bin/symmetric c
  measurement          mean ± σ            min … max           outliers         delta
  wall_time           501ms ± 32.3ms     455ms …  540ms          0 ( 0%)        0%
  peak_rss           1.28GB ±  689KB    1.28GB … 1.28GB          0 ( 0%)        0%
  cpu_cycles         6.23G  ± 56.9M     6.14G  … 6.36G           1 (10%)        0%
  instructions       21.9G  ±  235K     21.9G  … 21.9G           0 ( 0%)        0%
  cache_references   56.6M  ± 2.77M     53.5M  … 60.7M           0 ( 0%)        0%
  cache_misses        915K  ±  104K      743K  … 1.07M           0 ( 0%)        0%
  branch_misses      3.37M  ± 29.7K     3.32M  … 3.41M           0 ( 0%)        0%
Benchmark 2 (40 runs): zig-out/bin/symmetric smp
  measurement          mean ± σ            min … max           outliers         delta
  wall_time           126ms ± 2.94ms     118ms …  131ms          2 ( 5%)        ⚡- 74.9% ±  2.0%
  peak_rss            373MB ± 7.15MB     356MB …  388MB          1 ( 3%)        ⚡- 70.8% ±  0.4%
  cpu_cycles         6.45G  ±  182M     5.91G  … 6.80G           2 ( 5%)        💩+  3.5% ±  1.9%
  instructions       14.9G  ± 1.81M     14.9G  … 14.9G           1 ( 3%)        ⚡- 31.8% ±  0.0%
  cache_references   60.2M  ± 2.23M     54.5M  … 67.3M           2 ( 5%)        💩+  6.4% ±  3.0%
  cache_misses       13.9M  ±  738K     11.8M  … 15.3M           1 ( 3%)        💩+1423.8% ± 52.0%
  branch_misses      1.70M  ± 44.0K     1.58M  … 1.78M           0 ( 0%)        ⚡- 49.6% ±  0.9%
```

### asymmetric

```
andy@bark ~/d/CarmensPlayground (main)> poop 'zig-out/bin/asymmetric c' 'zig-out/bin/asymmetric smp'
Benchmark 1 (3 runs): zig-out/bin/asymmetric c
  measurement          mean ± σ            min … max           outliers         delta
  wall_time          3.30s  ± 51.1ms    3.25s  … 3.35s           0 ( 0%)        0%
  peak_rss           1.75MB ±  154KB    1.65MB … 1.93MB          0 ( 0%)        0%
  cpu_cycles         23.1G  ±  106M     22.9G  … 23.1G           0 ( 0%)        0%
  instructions       16.2G  ± 1.38M     16.2G  … 16.2G           0 ( 0%)        0%
  cache_references    115M  ± 2.35M      113M  …  118M           0 ( 0%)        0%
  cache_misses       68.1M  ±  286K     67.8M  … 68.4M           0 ( 0%)        0%
  branch_misses      6.97M  ± 40.9K     6.95M  … 7.02M           0 ( 0%)        0%
Benchmark 2 (3 runs): zig-out/bin/asymmetric smp
  measurement          mean ± σ            min … max           outliers         delta
  wall_time          1.93s  ± 60.8ms    1.86s  … 1.99s           0 ( 0%)        ⚡- 41.6% ±  3.9%
  peak_rss           49.5MB ± 5.43MB    43.4MB … 53.6MB          0 ( 0%)        💩+2734.2% ± 498.3%
  cpu_cycles         9.97G  ± 52.3M     9.92G  … 10.0G           0 ( 0%)        ⚡- 56.8% ±  0.8%
  instructions       14.8G  ± 7.71M     14.8G  … 14.8G           0 ( 0%)        ⚡-  8.8% ±  0.1%
  cache_references   55.6M  ± 2.02M     53.9M  … 57.9M           0 ( 0%)        ⚡- 51.7% ±  4.3%
  cache_misses       22.8M  ±  348K     22.5M  … 23.2M           0 ( 0%)        ⚡- 66.4% ±  1.1%
  branch_misses      2.74M  ± 99.4K     2.64M  … 2.83M           0 ( 0%)        ⚡- 60.7% ±  2.5%
```

## Roadmap

 1. Add more handy programs for playing with allocators.
 2. Add a robust testing system for fuzzing and allocator correctness testing.
 3. Look into importing or porting other existing open source allocator test suites.
