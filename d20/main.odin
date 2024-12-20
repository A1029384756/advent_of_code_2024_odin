package main

import c "../common"
import "core:fmt"
import "core:math"
import "core:os/os2"
import "core:slice"
import "core:strconv"
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
			res = p1(input, 100)
		}

		for _ in 0 ..< NUM_ITERATIONS {
			start := time.now()
			res = p1(input, 100)
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
			res = p2(input, 100)
		}

		for _ in 0 ..< NUM_ITERATIONS {
			start := time.now()
			res = p2(input, 100)
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

bfs :: proc(
	grid: string,
	start, end, size: [2]int,
	path_pos: ^[dynamic][2]int,
	temp_allocator := context.temp_allocator,
) {
	defer free_all(temp_allocator)

	queue := make([dynamic][2]int, temp_allocator)
	append(&queue, start)
	visited := make([]bool, len(grid), temp_allocator)
	visited[c.coord_to_idx(start, size)] = true

	for len(queue) > 0 {
		pos := pop_front(&queue)
		append(path_pos, pos)
		if pos == end do return

		for dir in Dir_Vecs {
			n := pos + dir
			n_idx := c.coord_to_idx(n, size)
			if !c.coord_valid(n, size) || visited[n_idx] || grid[n_idx] == '#' do continue
			append(&queue, n)
			visited[n_idx] = true
		}
	}
}

p1 :: proc(input: string, threshhold: int) -> (res: int) {
	size := c.grid_size(input)
	start, end: [2]int
	for y in 0 ..< size.y {
		for x in 0 ..< size.x {
			idx := c.coord_to_idx({x, y}, size)
			if input[idx] == 'S' do start = {x, y}
			else if input[idx] == 'E' do end = {x, y}
		}
	}

	path_pos := make([dynamic][2]int)
	defer delete(path_pos)
	bfs(input, start, end, size, &path_pos)

	for fp_idx := 0; fp_idx < len(path_pos) - 1; fp_idx += 1 {
		for sp_idx := fp_idx + 1; sp_idx < len(path_pos); sp_idx += 1 {
			saved_by_skip := sp_idx - fp_idx
			fp := path_pos[fp_idx]
			sp := path_pos[sp_idx]

			if (fp.x == sp.x) || (fp.y == sp.y) {
				xdiff := abs(fp.x - sp.x)
				ydiff := abs(fp.y - sp.y)
				if xdiff + ydiff <= 2 {
					saved := saved_by_skip - (xdiff + ydiff)
					if saved >= threshhold do res += 1
				}
			}
		}
	}

	return
}

p2 :: proc(input: string, threshhold: int) -> (res: int) {
	size := c.grid_size(input)
	start, end: [2]int
	for y in 0 ..< size.y {
		for x in 0 ..< size.x {
			idx := c.coord_to_idx({x, y}, size)
			if input[idx] == 'S' do start = {x, y}
			else if input[idx] == 'E' do end = {x, y}
		}
	}

	path_pos := make([dynamic][2]int)
	defer delete(path_pos)
	bfs(input, start, end, size, &path_pos)

	for fp_idx := 0; fp_idx < len(path_pos) - 1; fp_idx += 1 {
		for sp_idx := fp_idx + 1; sp_idx < len(path_pos); sp_idx += 1 {
			saved_by_skip := sp_idx - fp_idx
			fp := path_pos[fp_idx]
			sp := path_pos[sp_idx]

			xdiff := abs(fp.x - sp.x)
			ydiff := abs(fp.y - sp.y)
			if (xdiff + ydiff) <= 20 {
				saved := saved_by_skip - (xdiff + ydiff)
				if saved >= threshhold do res += 1
			}
		}
	}

	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input, 38)
	testing.expectf(t, res == 3, "expected %d, got %d", 3, res)
}

@(test)
p2_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p2(input, 72)
	testing.expectf(t, res == 29, "expected %d, got %d", 29, res)
}
