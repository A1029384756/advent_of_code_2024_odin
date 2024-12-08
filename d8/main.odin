package main

import c "../common"
import sa "core:container/small_array"
import "core:fmt"
import "core:math"
import "core:os/os2"
import "core:testing"
import "core:time"

@(optimization_mode = "none")
main :: proc() {
	input_bytes, err := os2.read_entire_file(os2.args[1], context.allocator)
	assert(err == nil)
	defer delete(input_bytes)

	input := string(input_bytes)

	WARMUP_ITERATIONS :: 1000
	NUM_ITERATIONS :: 10_000

	{
		max_t, total_t: time.Duration
		min_t := max(time.Duration)
		res: int

		for _ in 0 ..< WARMUP_ITERATIONS {
			res = p1(input)
		}

		for _ in 0 ..< NUM_ITERATIONS {
			start := time.now()
			res = p1(input)
			time := time.since(start)
			min_t = min(time, min_t)
			max_t = max(time, max_t)
			total_t += time
		}

		fmt.println(res, min_t, max_t, total_t / NUM_ITERATIONS)
	}

	{
		max_t, total_t: time.Duration
		min_t := max(time.Duration)
		res: int

		for _ in 0 ..< WARMUP_ITERATIONS {
			res = p2(input)
		}

		for _ in 0 ..< NUM_ITERATIONS {
			start := time.now()
			res = p2(input)
			time := time.since(start)
			min_t = min(time, min_t)
			max_t = max(time, max_t)
			total_t += time
		}

		fmt.println(res, min_t, max_t, total_t / NUM_ITERATIONS)
	}
}

p1 :: proc(input: string) -> (res: int) {
	context.allocator = context.temp_allocator
	defer free_all(context.temp_allocator)
	antennas: [max(u8)][dynamic][2]int

	size := c.grid_size(input)
	for y in 0 ..< size.y {
		for x in 0 ..< size.x {
			cell := input[c.coord_to_idx({x, y}, size)]
			if cell == '.' do continue
			append(&antennas[cell], [2]int{x, y})
		}
	}

	locs := make([]bool, len(input))
	for frequency in antennas {
		if len(frequency) == 0 do continue

		for antenna_a, idx in frequency {
			for antenna_b in frequency[idx + 1:] {
				delta := antenna_b - antenna_a
				antinode_a := antenna_a - delta
				antinode_b := antenna_b + delta

				if c.coord_valid(antinode_a, size) {
					if !locs[c.coord_to_idx(antinode_a, size)] {
						locs[c.coord_to_idx(antinode_a, size)] = true
						res += 1
					}
				}

				if c.coord_valid(antinode_b, size) {
					if !locs[c.coord_to_idx(antinode_b, size)] {
						locs[c.coord_to_idx(antinode_b, size)] = true
						res += 1
					}
				}
			}
		}
	}

	return
}

p2 :: proc(input: string) -> (res: int) {
	context.allocator = context.temp_allocator
	defer free_all(context.temp_allocator)
	antennas: [max(u8)][dynamic][2]int

	size := c.grid_size(input)
	for y in 0 ..< size.y {
		for x in 0 ..< size.x {
			cell := input[c.coord_to_idx({x, y}, size)]
			if cell == '.' do continue
			append(&antennas[cell], [2]int{x, y})
		}
	}

	locs := make([]bool, len(input))
	for frequency in antennas {
		if len(frequency) == 0 do continue

		for antenna_a, idx in frequency {
			for antenna_b in frequency[idx + 1:] {
				delta := antenna_b - antenna_a
				for i := 0;; i += 1 {
					antinode_a := antenna_a - delta * i
					if c.coord_valid(antinode_a, size) {
						if !locs[c.coord_to_idx(antinode_a, size)] {
							locs[c.coord_to_idx(antinode_a, size)] = true
							res += 1
						}
					} else {
						break
					}
				}

				for i := 0;; i += 1 {
					antinode_b := antenna_b + delta * i
					if c.coord_valid(antinode_b, size) {
						if !locs[c.coord_to_idx(antinode_b, size)] {
							locs[c.coord_to_idx(antinode_b, size)] = true
							res += 1
						}
					} else {
						break
					}
				}

			}
		}
	}

	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input)
	testing.expectf(t, res == 14, "expected %d, got %d", 14, res)
}

@(test)
p2_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p2(input)
	testing.expectf(t, res == 34, "expected %d, got %d", 34, res)
}
