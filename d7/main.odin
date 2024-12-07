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

	WARMUP_ITERATIONS :: 5
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

test_operation_ltr :: proc(nums: []int, ops: bit_set[0 ..< 64], expected: int) -> bool {
	res: int
	for idx in 0 ..< len(nums) {
		if idx == 0 {
			res = nums[idx]
			continue
		}

		if idx - 1 in ops {
			res *= nums[idx]
		} else {
			res += nums[idx]
		}
	}

	return res == expected
}

p1 :: proc(input: string) -> (res: int) {
	input := input
	lines: for line in c.split_iterator_fast(&input, '\n') {
		delim := c.find_fast(line, ':')
		lhs := c.parse_int_fast(line[:delim])

		nums: sa.Small_Array(64, int)
		nums_str := line[delim + 2:]
		for num in c.split_iterator_fast(&nums_str, ' ') {
			sa.append(&nums, c.parse_int_fast(num))
		}

		ops: bit_set[0 ..< 64]
		permutations: for i in 0 ..< 1 << uint(sa.len(nums) - 1) {
			ops = transmute(bit_set[0 ..< 64])(transmute(int)ops + 1)
			if test_operation_ltr(sa.slice(&nums), ops, lhs) {
				res += lhs
				break permutations
			}
		}
	}
	return
}

Operation :: enum {
	Add,
	Mult,
	Concat,
}

concat :: proc(a, b: int) -> int {
	return a * power(10, math.count_digits_of_base(b, 10)) + b
}

test_operations_all :: proc(nums: []int, ops: []Operation, expected: int) -> bool {
	res: int
	for idx in 0 ..< len(nums) {
		if idx == 0 {
			res = nums[idx]
			continue
		}

		switch ops[idx - 1] {
		case .Add:
			res += nums[idx]
		case .Mult:
			res *= nums[idx]
		case .Concat:
			res = concat(res, nums[idx])
		}
	}

	return res == expected
}

power :: proc(base, exponent: $T) -> T {
	result: T = 1
	for _ in 0 ..< exponent {
		result *= base
	}
	return result
}

p2 :: proc(input: string) -> (res: int) {
	input := input
	lines: for line in c.split_iterator_fast(&input, '\n') {
		delim := c.find_fast(line, ':')
		lhs := c.parse_int_fast(line[:delim])

		nums: sa.Small_Array(64, int)
		nums_str := line[delim + 2:]
		for num in c.split_iterator_fast(&nums_str, ' ') {
			sa.append(&nums, c.parse_int_fast(num))
		}

		ops: sa.Small_Array(64, Operation)
		sa.resize(&ops, sa.len(nums) - 1)

		permutations: for i in 0 ..< power(3, sa.len(ops)) {
			value := i
			for &elem in sa.slice(&ops) {
				elem = cast(Operation)(value % 3)
				value /= 3
			}

			if test_operations_all(sa.slice(&nums), sa.slice(&ops), lhs) {
				res += lhs
				break permutations
			}
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

@(test)
concat_test :: proc(t: ^testing.T) {
	testing.expect(t, concat(15, 6) == 156)
	testing.expect(t, concat(12, 345) == 12345)
}
