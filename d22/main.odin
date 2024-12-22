package main

import c "../common"
import sa "core:container/small_array"
import "core:fmt"
import "core:os/os2"
import "core:slice"
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

generation :: proc(secret: int) -> int {
	PRUNE_MASK :: 0xFFFFFF
	secret := secret
	secret = ((secret * 64) ~ secret) & PRUNE_MASK
	secret = ((secret / 32) ~ secret) & PRUNE_MASK
	secret = ((secret * 2048) ~ secret) & PRUNE_MASK
	return secret
}


p1 :: proc(input: string) -> (res: int) {
	input := input
	for line in c.split_iterator_fast(&input, '\n') {
		num := c.parse_int_fast(line)
		for _ in 0 ..< 2000 {
			num = generation(num)
		}
		res += num
	}
	return
}

seq_to_int :: proc(seq: [4]int) -> (res: int) {
	for e in seq do res = res * 19 + e + 9
	return
}

p2 :: proc(input: string) -> (res: int) {
	curr_seq := make([]bool, 19 * 19 * 19 * 19)
	all_seq := make([]int, 19 * 19 * 19 * 19)
	defer delete(curr_seq)
	defer delete(all_seq)

	input := input
	for line in c.split_iterator_fast(&input, '\n') {
		num := c.parse_int_fast(line)
		sequence: [4]int
		slice.zero(curr_seq)

		for i in 0 ..< 2000 {
			prev_price := num % 10
			num = generation(num)
			next_price := num % 10

			delta_price := next_price - prev_price
			sequence[0] = sequence[1]
			sequence[1] = sequence[2]
			sequence[2] = sequence[3]
			sequence[3] = delta_price

			v := seq_to_int(sequence)
			if i > 3 && !curr_seq[v] {
				curr_seq[v] = true
				all_seq[v] += next_price
			}
		}
	}

	for v in all_seq {
		res = max(res, v)
	}

	return
}

@(test)
generation_test :: proc(t: ^testing.T) {
	num := 123
	for _ in 0 ..< 10 {
		num = generation(num)
	}
	testing.expect_value(t, num, 5908254)
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input)
	testing.expect_value(t, res, 37327623)
}
