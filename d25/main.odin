package main

import c "../common"
import "core:fmt"
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
	NUM_ITERATIONS :: 10

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
		res: string

		for _ in 0 ..< WARMUP_ITERATIONS {
			res = p2(input)
			delete(res)
		}

		for iter in 0 ..< NUM_ITERATIONS {
			start := time.now()
			res = p2(input)
			time := time.since(start)
			min_t = min(time, min_t)
			max_t = max(time, max_t)
			total_t += time
			if iter < NUM_ITERATIONS - 1 do delete(res)
		}

		fmt.println(res, min_t, max_t, total_t / NUM_ITERATIONS)
		delete(res)
	}
}

p1 :: proc(input: string) -> (res: int) {
	keys: [dynamic][5]int
	locks: [dynamic][5]int
	defer delete(keys)
	defer delete(locks)

	input := input
	for elem in strings.split_iterator(&input, "\n\n") {
		profile: [5]int
		type := elem[0]
		col: for x in 0 ..< 5 {
			for y in 1 ..< 7 {
				if elem[c.coord_to_idx({x, y}, {5, 6})] != type {
					profile[x] = y - 1
					continue col
				}
			}
		}
		if type == '#' do append(&locks, profile)
		else if type == '.' do append(&keys, profile)
	}

	for lock in locks {
		change_key: for key in keys {
			for i in 0 ..< 5 {
				if lock[i] > key[i] do continue change_key
			}
			res += 1
		}
	}

	return
}

p2 :: proc(input: string) -> (res: string) {
	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input)
	testing.expect_value(t, res, 3)
}
