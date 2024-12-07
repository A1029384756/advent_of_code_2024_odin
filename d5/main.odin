package main

import c "../common"
import sa "core:container/small_array"
import "core:fmt"
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

p1 :: proc(input: string) -> (res: int) {
	n: [100][100]bool

	i: int
	for {
		if input[i] == '\n' {
			i += 1
			break
		}
		lhs := c.parse_int_fast(input[i:i + 2])
		rhs := c.parse_int_fast(input[i + 3:i + 5])
		n[lhs][rhs] = true
		i += 6
	}

	updates := input[i:]
	for line in c.split_iterator_fast(&updates, '\n') {
		line := line
		pages: sa.Small_Array(100, int)
		for page_str in c.split_iterator_fast(&line, ',') {
			page := c.parse_int_fast(page_str)
			sa.append(&pages, page)
		}

		invalid: bool
		check_pages: for page, idx in sa.slice(&pages) {
			for prev_page in pages.data[:idx] {
				if n[page][prev_page] {
					invalid = true
					break check_pages
				}
			}
		}

		if !invalid {
			res += pages.data[pages.len / 2]
		}
	}

	return
}

p2 :: proc(input: string) -> (res: int) {
	n: [100][100]bool
	context.user_ptr = &n

	i: int
	for {
		if input[i] == '\n' {
			i += 1
			break
		}
		lhs := c.parse_int_fast(input[i:i + 2])
		rhs := c.parse_int_fast(input[i + 3:i + 5])
		n[lhs][rhs] = true
		i += 6
	}

	updates := input[i:]
	for line in c.split_iterator_fast(&updates, '\n') {
		line := line
		pages: sa.Small_Array(100, int)
		for page_str in c.split_iterator_fast(&line, ',') {
			page := c.parse_int_fast(page_str)
			sa.append(&pages, page)
		}

		invalid: bool
		check_pages: for page, idx in sa.slice(&pages) {
			for prev_page in pages.data[:idx] {
				if n[page][prev_page] {
					invalid = true
					break check_pages
				}
			}
		}

		if invalid {
			slice.sort_by(sa.slice(&pages), proc(i, j: int) -> bool {
				n := cast(^[100][100]bool)context.user_ptr
				return n[i][j]
			})
			res += pages.data[pages.len / 2]
		}
	}

	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input)
	testing.expectf(t, res == 143, "expected %d, got %d", 143, res)
}

@(test)
p2_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p2(input)
	testing.expectf(t, res == 123, "expected %d, got %d", 123, res)
}
