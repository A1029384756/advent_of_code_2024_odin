package main

import c "../common"
import "core:fmt"
import "core:math"
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
			res = p1(input, 1024, {71, 71})
		}

		for _ in 0 ..< NUM_ITERATIONS {
			start := time.now()
			res = p1(input, 1024, {71, 71})
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
		res: [2]int

		for _ in 0 ..< WARMUP_ITERATIONS {
			res = p2(input, {71, 71})
		}

		for _ in 0 ..< NUM_ITERATIONS {
			start := time.now()
			res = p2(input, {71, 71})
			time := time.since(start)
			min_t = min(time, min_t)
			max_t = max(time, max_t)
			total_t += time
		}

		fmt.println(res, min_t, max_t, total_t / NUM_ITERATIONS)
	}
}

Dir :: enum {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}
Dir_Vecs := [Dir][2]int {
	.UP    = {0, -1},
	.DOWN  = {0, 1},
	.LEFT  = {-1, 0},
	.RIGHT = {1, 0},
}

pos_to_idx :: proc(pos, size: [2]int) -> int {
	return pos.y * size.x + pos.x
}

bfs :: proc(grid: []bool, start, end, size: [2]int) -> (res: int) {
	context.allocator = context.temp_allocator
	defer free_all(context.temp_allocator)

	queue: [dynamic][2]int = {0}
	visited := make([]bool, len(grid))
	visited[0] = true

	for len(queue) > 0 {
		q_size := len(queue)
		for _ in 0 ..< q_size {
			pos := pop_front_safe(&queue) or_else 0
			if pos == end do return

			for dir in Dir_Vecs {
				n := pos + dir
				n_idx := pos_to_idx(n, size)
				if !c.coord_valid(n, size) || visited[n_idx] || grid[n_idx] do continue
				append(&queue, n)
				visited[n_idx] = true
			}
		}
		res += 1
	}
	return -1
}

p1 :: proc(input: string, n_simulate: int, size: [2]int) -> (res: int) {
	input := input
	grid := make([]bool, size.x * size.y)
	defer delete(grid)

	idx := 0
	for line in c.split_iterator_fast(&input, '\n') {
		if idx >= n_simulate do break
		comma_pos := c.find_fast(line, ',')
		grid[pos_to_idx({c.parse_int_fast(line[:comma_pos]), c.parse_int_fast(line[comma_pos + 1:])}, size)] =
			true
		idx += 1
	}

	res = bfs(grid, 0, size - 1, size)
	return
}

p2 :: proc(input: string, size: [2]int) -> (res: [2]int) {
	input := input
	grid := make([]bool, size.x * size.y)
	defer delete(grid)

	for line in c.split_iterator_fast(&input, '\n') {
		comma_pos := c.find_fast(line, ',')
		corrupted_pos := [2]int {
			c.parse_int_fast(line[:comma_pos]),
			c.parse_int_fast(line[comma_pos + 1:]),
		}

		grid[pos_to_idx(corrupted_pos, size)] = true

		shortest := bfs(grid, 0, size - 1, size)
		if shortest == -1 do return corrupted_pos
	}

	return -1
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input, 12, {7, 7})
	testing.expectf(t, res == 22, "expected %d, got %d", 22, res)
}

@(test)
p2_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p2(input, {7, 7})
	testing.expectf(t, res == {6, 1}, "expected %d, got %d", [2]int{6, 1}, res)
}
