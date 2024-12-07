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
	input_bytes, err := os2.read_entire_file("./input/d7.txt", context.allocator)
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

count_digits :: proc "contextless" (val: int) -> int {
	res := 10
	for val >= res do res *= 10
	return res
}

test_operations :: proc "contextless" (ops: []int, expected: int, $part_2: bool) -> bool {
	if len(ops) == 1 do return expected == ops[0]
	else if len(ops) == 0 do return expected == 0

	last_op := ops[len(ops) - 1]
	next_ops := ops[:len(ops) - 1]

	when part_2 {if (expected - last_op) % count_digits(last_op) == 0 &&
		   test_operations(next_ops, (expected - last_op) / count_digits(last_op), part_2) {
			return true
		}
	}
	if expected % last_op == 0 && test_operations(next_ops, expected / last_op, part_2) do return true
	if expected - last_op >= 0 && test_operations(next_ops, expected - last_op, part_2) do return true
	return false
}

p1 :: proc(input: string) -> (res: int) {
	input := input
	lines: for line in c.split_iterator_fast(&input, '\n') {
		delim := c.find_fast(line, ':')
		lhs := c.parse_int_fast(line[:delim])

		ops: sa.Small_Array(64, int)
		ops_str := line[delim + 2:]
		for num in c.split_iterator_fast(&ops_str, ' ') {
			sa.append(&ops, c.parse_int_fast(num))
		}

		if test_operations(sa.slice(&ops), lhs, false) {
			res += lhs
		}
	}
	return
}

p2 :: proc(input: string) -> (res: int) {
	input := input
	lines: for line in c.split_iterator_fast(&input, '\n') {
		delim := c.find_fast(line, ':')
		lhs := c.parse_int_fast(line[:delim])

		ops: sa.Small_Array(64, int)
		ops_str := line[delim + 2:]
		for num in c.split_iterator_fast(&ops_str, ' ') {
			sa.append(&ops, c.parse_int_fast(num))
		}

		if test_operations(sa.slice(&ops), lhs, true) {
			res += lhs
		} else if test_operations(sa.slice(&ops), lhs, true) {
			res += lhs
		}
	}
	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input)
	testing.expectf(t, res == 3749, "expected %d, got %d", 3749, res)
}

@(test)
p2_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p2(input)
	testing.expectf(t, res == 11387, "expected %d, got %d", 11387, res)
}
