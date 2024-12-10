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

Dir :: enum {
	NONE,
	UP,
	DOWN,
	LEFT,
	RIGHT,
}
Dir_Vecs := [Dir][2]int {
	.NONE  = {0, 0},
	.UP    = {0, -1},
	.DOWN  = {0, 1},
	.LEFT  = {-1, 0},
	.RIGHT = {1, 0},
}

Pos :: [2]int

p1 :: proc(input: string) -> (res: int) {
	size := c.grid_size(input)
	for y in 0 ..< size.y {
		for x in 0 ..< size.x {
			if input[c.coord_to_idx({x, y}, size)] == '0' {
				score: int

				curr_pos := Pos{x, y}

				visited: [dynamic]Pos
				defer delete(visited)
				append(&visited, curr_pos)

				queue: [dynamic]Pos
				defer delete(queue)
				append(&queue, curr_pos)

				for len(queue) > 0 {
					v := pop_front(&queue)
					if input[c.coord_to_idx(v, size)] == '9' {
						score += 1
					}

					for dir in Dir_Vecs {
						if !c.coord_valid(dir + v, size) do continue
						curr_elevation := int(input[c.coord_to_idx(v, size)])
						next_elevation := int(input[c.coord_to_idx(dir + v, size)])
						if next_elevation - curr_elevation != 1 do continue
						_, found := slice.linear_search(visited[:], dir + v)
						if found do continue

						append(&visited, dir + v)
						append(&queue, dir + v)
					}
				}

				res += score
			}
		}
	}
	return
}

p2 :: proc(input: string) -> (res: int) {
	size := c.grid_size(input)
	for y in 0 ..< size.y {
		for x in 0 ..< size.x {
			if input[c.coord_to_idx({x, y}, size)] == '0' {
				score: int

				curr_pos := Pos{x, y}

				visited: [dynamic]Pos
				defer delete(visited)
				append(&visited, curr_pos)

				queue: [dynamic]Pos
				defer delete(queue)
				append(&queue, curr_pos)

				for len(queue) > 0 {
					v := pop_front(&queue)
					if input[c.coord_to_idx(v, size)] == '9' {
						score += 1
					}

					for dir in Dir_Vecs {
						if !c.coord_valid(dir + v, size) do continue
						curr_elevation := int(input[c.coord_to_idx(v, size)])
						next_elevation := int(input[c.coord_to_idx(dir + v, size)])
						if next_elevation - curr_elevation != 1 do continue

						append(&visited, dir + v)
						append(&queue, dir + v)
					}
				}
				res += score
			}

		}
	}
	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input)
	testing.expectf(t, res == 36, "expected %d, got %d", 36, res)
}

@(test)
p2_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p2(input)
	testing.expectf(t, res == 81, "expected %d, got %d", 81, res)
}
