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

	WARMUP_ITERATIONS :: 100
	NUM_ITERATIONS :: 1000

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

option_to_dir_vec :: #force_inline proc(option: u8) -> [2]int {
	switch option {
	case '^':
		return Dir_Vecs[.UP]
	case 'v':
		return Dir_Vecs[.DOWN]
	case '<':
		return Dir_Vecs[.LEFT]
	case '>':
		return Dir_Vecs[.RIGHT]
	case:
		unreachable()
	}
}

p1 :: proc(input: string) -> (res: int) {
	input := strings.clone(input)
	defer delete(input)
	grid_end := strings.index(input, "\n\n")
	grid_str := input[:grid_end]
	size := c.grid_size(grid_str)

	pos: [2]int
	{
		y: int
		grid_str := grid_str
		for line in strings.split_lines_iterator(&grid_str) {
			for tile, x in line {
				if tile == '@' {
					pos = {x, y}
				}
			}
			y += 1
		}
	}

	options := input[grid_end + 2:]
	for option in options {
		if option == '\n' do continue
		dir_vec := option_to_dir_vec(u8(option))

		count: int
		curr := pos
		for {
			curr += dir_vec
			count += 1
			if grid_str[c.coord_to_idx(curr, size)] != 'O' do break
		}
		if grid_str[c.coord_to_idx(curr, size)] == '#' do continue

		slice.swap(
			transmute([]u8)grid_str,
			c.coord_to_idx(curr, size),
			c.coord_to_idx(pos + dir_vec, size),
		)
		pos += dir_vec
	}

	for y in 0 ..< size.y {
		for x in 0 ..< size.x {
			if grid_str[c.coord_to_idx({x, y}, size)] == 'O' {
				res += 100 * y + x
			}
		}
	}

	return
}

pos_idx :: #force_inline proc(pos, size: [2]int) -> int {
	return pos.y * size.x + pos.x
}

move_horizontal :: proc(pos, curr, dir_vec: [2]int, grid: []u8, size: [2]int) -> [2]int {
	next := curr
	next_char := grid[pos_idx(next, size)]
	for {
		next += 2 * dir_vec
		if grid[pos_idx(next, size)] != next_char do break
	}
	if grid[pos_idx(next, size)] == '#' do return pos

	for curr != next {
		slice.swap(grid, pos_idx(next, size), pos_idx(next - dir_vec, size))
		next -= dir_vec
	}
	return curr
}

check_vertical :: proc(pos, dir_vec: [2]int, grid: []u8, size: [2]int) -> bool {
	lhs, rhs: [2]int
	switch grid[pos_idx(pos, size)] {
	case '#':
		return false
	case '.':
		return true
	case '[':
		lhs = pos + {0, dir_vec.y}
		rhs = pos + {1, dir_vec.y}
	case ']':
		lhs = pos + {-1, dir_vec.y}
		rhs = pos + {0, dir_vec.y}
	case:
		unreachable()
	}

	return check_vertical(lhs, dir_vec, grid, size) && check_vertical(rhs, dir_vec, grid, size)
}

shift_vertical :: proc(curr, dir_vec: [2]int, grid: []u8, size: [2]int) {
	lhs_curr, lhs_next, rhs_curr, rhs_next: [2]int
	switch grid[pos_idx(curr, size)] {
	case '.':
		return
	case '[':
		lhs_curr = curr
		lhs_next = curr + {0, dir_vec.y}
		rhs_curr = curr + {1, 0}
		rhs_next = curr + {1, dir_vec.y}
	case ']':
		lhs_curr = curr + {-1, 0}
		lhs_next = curr + {-1, dir_vec.y}
		rhs_curr = curr
		rhs_next = curr + {0, dir_vec.y}
	case:
		unreachable()
	}

	shift_vertical(lhs_next, dir_vec, grid, size)
	shift_vertical(rhs_next, dir_vec, grid, size)

	slice.swap(grid, pos_idx(lhs_next, size), pos_idx(lhs_curr, size))
	slice.swap(grid, pos_idx(rhs_next, size), pos_idx(rhs_curr, size))
}

move_vertical :: proc(pos, curr, dir_vec: [2]int, grid: []u8, size: [2]int) -> [2]int {
	if !check_vertical(curr, dir_vec, grid, size) do return pos
	shift_vertical(curr, dir_vec, grid, size)
	return curr
}

p2 :: proc(input: string) -> (res: int) {
	grid_end := strings.index(input, "\n\n")
	grid_str := input[:grid_end]
	size := c.grid_size(grid_str)
	size.x *= 2

	grid := make([]u8, size.x * size.y)
	defer delete(grid)

	pos: [2]int
	{
		y: int
		for line in strings.split_lines_iterator(&grid_str) {
			for tile, x in line {
				if tile == '@' {
					pos = {2 * x, y}
					grid[pos_idx({2 * x, y}, size)] = '.'
					grid[pos_idx({2 * x + 1, y}, size)] = '.'
				} else if tile == 'O' {
					grid[pos_idx({2 * x, y}, size)] = '['
					grid[pos_idx({2 * x + 1, y}, size)] = ']'
				} else {
					grid[pos_idx({2 * x, y}, size)] = u8(tile)
					grid[pos_idx({2 * x + 1, y}, size)] = u8(tile)
				}
			}
			y += 1
		}
	}

	options := input[grid_end + 2:]
	for option in options {
		if option == '\n' do continue
		dir_vec := option_to_dir_vec(u8(option))

		curr := pos + dir_vec
		curr_idx := pos_idx(curr, size)
		if grid[curr_idx] == '.' {
			pos = curr
		} else if grid[curr_idx] == '[' || grid[curr_idx] == ']' {
			if dir_vec.y == 0 {
				pos = move_horizontal(pos, curr, dir_vec, grid, size)
			} else {
				pos = move_vertical(pos, curr, dir_vec, grid, size)
			}
		}
	}

	for y in 0 ..< size.y {
		for x in 0 ..< size.x {
			if grid[pos_idx({x, y}, size)] == '[' {
				res += 100 * y + x
			}
		}
	}

	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input)
	testing.expectf(t, res == 10092, "expected %d, got %d", 10092, res)
}

@(test)
p2_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p2(input)
	testing.expectf(t, res == 9021, "expected %d, got %d", 9021, res)
}
