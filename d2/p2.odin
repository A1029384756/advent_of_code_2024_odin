package d2

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

report_safe :: proc(l: []int, skip: int) -> bool {
	prev := l[skip == 0 ? 1 : 0]
	is_inc, is_dec: bool

	for i in (skip == 0 ? 2 : 1) ..< len(l) {
		if i == skip do continue

		curr := l[i]
		delta := curr - prev

		if delta > 0 do is_inc = true
		if delta < 0 do is_dec = true

		if delta == 0 || abs(delta) > 3 || (is_inc && is_dec) do return false
		prev = curr
	}
	return true
}

p1 :: proc(input: string) -> int {
	input := input
	safe: int
	for line in c.split_iterator_fast(&input, '\n') {
		prev, idx: int
		increasing, unsafe: bool

		line := line
		for num in c.split_iterator_fast(&line, ' ') {
			val := c.parse_int_fast(num)

			if idx > 0 {
				delta := val - prev
				if abs(delta) < 1 || abs(delta) > 3 {
					unsafe = true
					break
				}

				if idx == 1 {
					increasing = delta > 0
				} else {
					if increasing != (delta > 0) {
						unsafe = true
						break
					}
				}
			}
			prev = val

			idx += 1
		}

		if unsafe do continue

		safe += 1
	}
	return safe
}

p2 :: proc(input: string) -> (safe: int) {
	prev_line_idx: int
	for idx in 0 ..< len(input) {
		if input[idx] == '\n' {
			line := string(input[prev_line_idx:idx])
			prev_line_idx = idx + 1
			report: sa.Small_Array(16, int)

			val: int
			for idx in 0 ..< len(line) {
				if line[idx] == ' ' {
					sa.append(&report, val)
					val = 0
				} else {
					val = (val * 10) + (int(line[idx]) - '0')
				}
			}
			sa.append(&report, val)

			if report_safe(sa.slice(&report), -1) {
				safe += 1
			} else {
				dampener: for i in 0 ..< report.len {
					if report_safe(sa.slice(&report), i) {
						safe += 1
						break dampener
					}
				}
			}
		}
	}

	return safe
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./sample.txt", string)
	res := p1(input)
	testing.expectf(t, res == 2, "got: %d", res)
}

@(test)
p2_test :: proc(t: ^testing.T) {
	input := #load("./sample.txt", string)
	res := p2(input)
	testing.expectf(t, res == 4, "got: %d", res)
}
