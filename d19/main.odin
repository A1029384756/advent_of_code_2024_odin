package main

import c "../common"
import sa "core:container/small_array"
import "core:fmt"
import "core:math"
import "core:os/os2"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:time"

@(optimization_mode = "none")
main :: proc() {
	input_bytes, err := os2.read_entire_file(os2.args[1], context.allocator)
	assert(err == nil)
	defer delete(input_bytes)

	input := string(input_bytes)

	WARMUP_ITERATIONS :: 1
	NUM_ITERATIONS :: 1

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

find_match :: proc(towel: string, colors: []string, cache: ^map[string]int) -> int {
	if len(towel) == 0 do return 1

	c_towel, exists := cache[towel]
	if exists do return c_towel

	sum := 0
	for color in colors {
		if c.scry(towel, color) {
			sum += find_match(towel[len(color):], colors, cache)
		}
	}
	cache[towel] = sum
	return sum
}

p1 :: proc(input: string) -> (res: int) {
	input := input

	colors: [dynamic]string
	defer delete(colors)
	for line in strings.split_lines_iterator(&input) {
		line := line
		for color in strings.split_iterator(&line, ", ") {
			append(&colors, color)
		}
		break
	}

	for blankline in strings.split_lines_iterator(&input) do break

	cache: map[string]int
	defer delete(cache)
	for combo in strings.split_lines_iterator(&input) {
		res += find_match(combo, colors[:], &cache) > 0 ? 1 : 0
	}
	return
}

p2 :: proc(input: string) -> (res: int) {
	input := input

	colors: [dynamic]string
	defer delete(colors)
	for line in strings.split_lines_iterator(&input) {
		line := line
		for color in strings.split_iterator(&line, ", ") {
			append(&colors, color)
		}
		break
	}

	for blankline in strings.split_lines_iterator(&input) do break

	cache: map[string]int
	defer delete(cache)
	for combo in strings.split_lines_iterator(&input) {
		res += find_match(combo, colors[:], &cache)
	}
	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input)
	testing.expectf(t, res == 6, "expected %d, got %d", 6, res)
}

@(test)
p2_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p2(input)
	testing.expectf(t, res == 16, "expected %d, got %d", 16, res)
}
