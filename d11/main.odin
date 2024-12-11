package main

import c "../common"
import sa "core:container/small_array"
import "core:fmt"
import "core:math"
import "core:os/os2"
import "core:slice"
import "core:testing"
import "core:time"

@(optimization_mode = "none")
main :: proc() {
	input_bytes, err := os2.read_entire_file(os2.args[1], context.allocator)
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

count_digits :: proc "contextless" (val: int) -> (res: int) {
	val := val
	for val > 0 {
		val /= 10
		res += 1
	}
	return
}

power :: proc "contextless" (val, exp: int) -> int {
	res := 1
	for _ in 0 ..< exp {
		res = res * val
	}
	return res
}

split_stone :: proc "contextless" (stone: int) -> (l, r: int) {
	n_digits := count_digits(stone)
	num := power(10, n_digits / 2)
	l = stone / num
	r = stone % num
	return
}

simulate_stone :: proc(cache: []int, stone, rem_iters, total_iters: int) -> (res: int) {
	if rem_iters == 0 do return 1

	if stone < len(cache) / total_iters {
		if cached := cache[stone * total_iters + rem_iters]; cached > 0 do return cached
	}

	if stone == 0 {
		res += simulate_stone(cache, 1, rem_iters - 1, total_iters)
	} else if count_digits(stone) % 2 == 0 {
		l, r := split_stone(stone)
		res +=
			simulate_stone(cache, l, rem_iters - 1, total_iters) +
			simulate_stone(cache, r, rem_iters - 1, total_iters)
	} else {
		res += simulate_stone(cache, stone * 2024, rem_iters - 1, total_iters)
	}

	if stone < len(cache) / total_iters {
		cache[stone * total_iters + rem_iters] = res
	}
	return
}

p1 :: proc(input: string) -> (res: int) {
	input := input

	stones: sa.Small_Array(64, int)
	for line in c.split_iterator_fast(&input, '\n') {
		line := line
		for stone in c.split_iterator_fast(&line, ' ') {
			sa.append(&stones, c.parse_int_fast(stone))
		}
	}

	cache := make([]int, 100_000)
	defer delete(cache)
	for stone in sa.slice(&stones) {
		res += simulate_stone(cache[:], stone, 25, 25)
	}

	return
}

p2 :: proc(input: string) -> (res: int) {
	input := input

	stones: sa.Small_Array(64, int)
	for line in c.split_iterator_fast(&input, '\n') {
		line := line
		for stone in c.split_iterator_fast(&line, ' ') {
			sa.append(&stones, c.parse_int_fast(stone))
		}
	}

	cache := make([]int, 100_000)
	defer delete(cache)
	for stone in sa.slice(&stones) {
		res += simulate_stone(cache[:], stone, 75, 75)
	}

	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input)
	testing.expectf(t, res == 55312, "expected %d, got %d", 55312, res)
}

@(test)
count_digits_test :: proc(t: ^testing.T) {
	testing.expectf(t, count_digits(16) == 2, "expected 2, got %d", count_digits(10))
	testing.expectf(t, count_digits(121) == 3, "expected 3, got %d", count_digits(110))
	testing.expectf(t, count_digits(1) == 1, "expected 1, got %d", count_digits(1))
	testing.expectf(t, count_digits(821427) == 6, "expected 6, got %d", count_digits(821427))
}

@(test)
power_test :: proc(t: ^testing.T) {
	testing.expectf(t, power(10, 2) == 100, "expected 100 got %d", power(10, 2))
	testing.expectf(t, power(2, 8) == 256, "expected 256 got %d", power(2, 8))
	testing.expectf(t, power(10, 5) == 1e5, "expected 1e5 got %d", power(10, 5))
}

@(test)
split_stone_test :: proc(t: ^testing.T) {
	{
		l, r := split_stone(10)
		testing.expect(t, l == 1)
		testing.expect(t, r == 0)
	}

	{
		l, r := split_stone(99)
		testing.expect(t, l == 9)
		testing.expect(t, r == 9)
	}
}
