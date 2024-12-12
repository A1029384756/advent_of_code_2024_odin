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


p1 :: proc(i: string) -> (res: int) {
	context.allocator = context.temp_allocator
	defer free_all(context.temp_allocator)

	size := c.grid_size(i)
	input := make([]u8, len(i) + size.x)
	for i in 0 ..< size.x {
		input[len(input) - i - 1] = '\n'
	}
	copy(input[:], i[:])

	marked := make([]bool, len(input))
	visited := make([]bool, len(input))
	queue: [dynamic][2]int
	for y in 0 ..< size.y {
		for x in 0 ..< size.x {
			curr_idx := c.coord_to_idx({x, y}, size)
			curr_patch := input[curr_idx]
			if marked[curr_idx] do continue

			area, perimeter: int

			clear(&queue)
			append(&queue, [2]int{x, y})

			slice.zero(visited)
			visited[curr_idx] = true

			for len(queue) > 0 {
				pos := pop_front(&queue)
				marked[c.coord_to_idx(pos, size)] = true
				area += 1

				for dir in Dir_Vecs {
					next_idx := c.coord_to_idx(dir + pos, size)

					if !c.coord_valid(dir + pos, size) || input[next_idx] != curr_patch {
						perimeter += 1
						continue
					}
					if visited[next_idx] do continue

					visited[next_idx] = true
					append(&queue, dir + pos)
				}
			}

			res += area * perimeter
		}
	}

	return
}

p2 :: proc(i: string) -> (res: int) {
	context.allocator = context.temp_allocator
	defer free_all(context.temp_allocator)

	size := c.grid_size(i)
	input := make([]u8, len(i) + size.x)
	for i in 0 ..< size.x {
		input[len(input) - i - 1] = '\n'
	}
	copy(input[:], i[:])

	marked := make([]bool, len(input))
	visited := make([]bool, len(input))
	queue: [dynamic][2]int
	for y in 0 ..< size.y {
		for x in 0 ..< size.x {
			curr_idx := c.coord_to_idx({x, y}, size)
			curr_patch := input[curr_idx]
			if marked[curr_idx] do continue

			area, corners: int

			clear(&queue)
			append(&queue, [2]int{x, y})

			slice.zero(visited)
			visited[curr_idx] = true

			for len(queue) > 0 {
				pos := pop_front(&queue)
				curr_idx := c.coord_to_idx(pos, size)
				marked[curr_idx] = true

				// outer corners
				{
					check_sets := [][2][2]int {
						{Dir_Vecs[.UP], Dir_Vecs[.LEFT]},
						{Dir_Vecs[.UP], Dir_Vecs[.RIGHT]},
						{Dir_Vecs[.DOWN], Dir_Vecs[.LEFT]},
						{Dir_Vecs[.DOWN], Dir_Vecs[.RIGHT]},
					}

					for set in check_sets {
						a := set[0] + pos
						b := set[1] + pos

						a_no_match :=
							!c.coord_valid(a, size) || input[c.coord_to_idx(a, size)] != curr_patch
						b_no_match :=
							!c.coord_valid(b, size) || input[c.coord_to_idx(b, size)] != curr_patch

						if a_no_match && b_no_match do corners += 1
					}
				}

				// inner corners
				{
					check_sets := [][2][2]int {
						{Dir_Vecs[.UP], Dir_Vecs[.LEFT]},
						{Dir_Vecs[.UP], Dir_Vecs[.RIGHT]},
						{Dir_Vecs[.DOWN], Dir_Vecs[.LEFT]},
						{Dir_Vecs[.DOWN], Dir_Vecs[.RIGHT]},
					}

					for set in check_sets {
						a := set[0] + pos
						b := set[1] + pos
						d := set[0] + set[1] + pos

						a_match :=
							c.coord_valid(a, size) && input[c.coord_to_idx(a, size)] == curr_patch
						b_match :=
							c.coord_valid(b, size) && input[c.coord_to_idx(b, size)] == curr_patch
						d_no_match :=
							!c.coord_valid(d, size) || input[c.coord_to_idx(d, size)] != curr_patch

						if a_match && b_match && d_no_match do corners += 1
					}
				}

				area += 1

				for dir in Dir_Vecs {
					next_idx := c.coord_to_idx(dir + pos, size)
					if !c.coord_valid(dir + pos, size) ||
					   visited[next_idx] ||
					   input[next_idx] != curr_patch {
						continue
					}

					visited[next_idx] = true
					append(&queue, dir + pos)
				}
			}

			res += area * corners
		}
	}

	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input)
	testing.expectf(t, res == 1930, "expected %d, got %d", 1930, res)
}

@(test)
p2_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p2(input)
	testing.expectf(t, res == 1206, "expected %d, got %d", 1206, res)
}
