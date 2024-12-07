package d1

import c "../common"
import "core:fmt"
import "core:os/os2"
import "core:slice"
import "core:testing"
import "core:time"

@(optimization_mode = "none")
main :: proc() {
	input_bytes, err := os2.read_entire_file("./input/d1.txt", context.allocator)
	assert(err == nil)
	defer delete(input_bytes)

	input := string(input_bytes)

	WARMUP_ITERATIONS :: 10
	NUM_ITERATIONS :: 100

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

p1 :: proc(input: string) -> int {
	input := input

	side_1, side_2: [dynamic]int
	defer {
		delete(side_1)
		delete(side_2)
	}

	for line in c.split_iterator_fast(&input, '\n') {
		delim: int
		for {
			if line[delim] == ' ' do break
			delim += 1
		}

		l := c.parse_int_fast(line[:delim])
		r := c.parse_int_fast(line[delim + 3:])
		append(&side_1, l)
		append(&side_2, r)
	}

	slice.sort(side_1[:])
	slice.sort(side_2[:])

	dist: int
	for i := 0; i < len(side_1); i += 1 {
		dist += abs(side_2[i] - side_1[i])
	}
	return dist
}

p2 :: proc(input: string) -> int {
	input := input

	side_1, side_2: [dynamic]int
	defer {
		delete(side_1)
		delete(side_2)
	}

	for line in c.split_iterator_fast(&input, '\n') {
		delim: int
		for {
			if line[delim] == ' ' do break
			delim += 1
		}
		l := c.parse_int_fast(line[:delim])
		r := c.parse_int_fast(line[delim + 3:])
		append(&side_1, l)
		append(&side_2, r)
	}

	slice.sort(side_1[:])
	slice.sort(side_2[:])

	score: int
	for i := 0; i < len(side_1); i += 1 {
		count := slice.count(side_2[:], side_1[i])
		score += count * side_1[i]
	}
	return score
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./sample.txt", string)
	dist := p1(input)
	testing.expect(t, dist == 11)
}

@(test)
p2_test :: proc(t: ^testing.T) {
	input := #load("./sample.txt", string)
	score := p2(input)
	testing.expect(t, score == 31)
}
