package main

import c "../common"
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

parse_line :: proc(input: string) -> (res: [2]int) {
	num_start_idx, num_end_idx: int
	num_start_idx = c.find_fast(input, 'X')
	num_start_idx += 2
	for num_end_idx = num_start_idx; num_end_idx < len(input); num_end_idx += 1 {
		if input[num_end_idx] < '0' || input[num_end_idx] > '9' do break
	}
	res.x = c.parse_int_fast(input[num_start_idx:num_end_idx])

	num_start_idx = c.find_fast(input, 'Y')
	num_start_idx += 2
	for num_end_idx = num_start_idx; num_end_idx < len(input); num_end_idx += 1 {
		if input[num_end_idx] < '0' || input[num_end_idx] > '9' do break
	}
	res.y = c.parse_int_fast(input[num_start_idx:num_end_idx])
	return
}

calc_presses :: proc(da, db, target: [2]int) -> (na, nb: int, valid: bool) {
	nb = (target.y * da.x - target.x * da.y) / (db.y * da.x - db.x * da.y)
	na = (target.x - nb * db.x) / da.x
	valid = (da * na + db * nb == target)
	return
}

p1 :: proc(input: string) -> (res: int) {
	input := input

	da, db, target: [2]int
	line_idx: int
	for line in c.split_iterator_fast(&input, '\n') {
		if len(line) == 0 {
			da, db, target = {}, {}, {}
			line_idx = 0
			continue
		}

		nums := parse_line(line)
		switch line_idx {
		case 0:
			da = nums
			line_idx = 1
		case 1:
			db = nums
			line_idx = 2
		case 2:
			target = nums
			na, nb, valid := calc_presses(da, db, target)
			if valid {
				res += 3 * na + nb
			}
		case:
			unreachable()
		}
	}
	return
}

p2 :: proc(input: string) -> (res: int) {
	input := input

	da, db, target: [2]int
	line_idx: int
	for line in c.split_iterator_fast(&input, '\n') {
		if len(line) == 0 {
			da, db, target = {}, {}, {}
			line_idx = 0
			continue
		}

		nums := parse_line(line)
		switch line_idx {
		case 0:
			da = nums
			line_idx = 1
		case 1:
			db = nums
			line_idx = 2
		case 2:
			target = nums
			na, nb, valid := calc_presses(da, db, target + {10000000000000, 10000000000000})
			if valid {
				res += 3 * na + nb
			}
		case:
			unreachable()
		}
	}
	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input)
	testing.expectf(t, res == 480, "expected %d, got %d", 480, res)
}
