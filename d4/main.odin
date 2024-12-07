package main

import c "../common"
import "core:fmt"
import "core:os/os2"
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

Dir :: enum {
	UP,
	DOWN,
	LEFT,
	RIGHT,
	UP_LEFT,
	UP_RIGHT,
	DOWN_LEFT,
	DOWN_RIGHT,
}
Dir_Vecs := [Dir][2]int {
	.UP         = {0, -1},
	.DOWN       = {0, 1},
	.LEFT       = {-1, 0},
	.RIGHT      = {1, 0},
	.UP_LEFT    = {-1, -1},
	.UP_RIGHT   = {1, -1},
	.DOWN_LEFT  = {-1, 1},
	.DOWN_RIGHT = {1, 1},
}
Dirs :: bit_set[Dir;u8]

find_word :: proc(pos, size: [2]int, word, grid: string, directions: Dirs) -> (dirs: Dirs) {
	if grid[c.coord_to_idx(pos, size)] != word[0] do return

	for dir in directions {
		k: int
		curr := pos + Dir_Vecs[dir]
		inner: for k = 1; k < len(word); k += 1 {
			if !c.coord_valid(curr, size) do break inner
			if grid[c.coord_to_idx(curr, size)] != word[k] do break inner
			curr += Dir_Vecs[dir]
		}

		if k == len(word) {
			dirs += {dir}
		}
	}
	return
}

p1 :: proc(input: string) -> (res: int) {
	size := c.grid_size(input)
	for y in 0 ..< size.y {
		for x in 0 ..< size.x {
			res += card(
				find_word(
					{x, y},
					size,
					"XMAS",
					input,
					{.UP, .DOWN, .LEFT, .RIGHT, .UP_LEFT, .UP_RIGHT, .DOWN_LEFT, .DOWN_RIGHT},
				),
			)
		}
	}
	return
}

p2 :: proc(input: string) -> (res: int) {
	size := c.grid_size(input)

	Mas :: struct {
		pos:  [2]int,
		dirs: Dirs,
	}
	mases := make(#soa[]Mas, len(input))
	defer delete(mases)

	for y in 0 ..< size.y {
		for x in 0 ..< size.x {
			dirs := find_word(
				{x, y},
				size,
				"MAS",
				input,
				{.UP_LEFT, .UP_RIGHT, .DOWN_LEFT, .DOWN_RIGHT},
			)
			if dirs != {} {
				mases[c.coord_to_idx({x, y}, size)] = {{x, y}, dirs}
			}
		}
	}

	for mas in mases {
		pos := mas.pos
		dirs := mas.dirs
		for dir in dirs {
			#partial switch dir {
			case .UP_LEFT:
				{
					elem := mases[c.coord_to_idx(pos + 2 * Dir_Vecs[.UP], size)]
					if .DOWN_LEFT in elem.dirs do res += 1
				}
				{
					elem := mases[c.coord_to_idx(pos + 2 * Dir_Vecs[.LEFT], size)]
					if .UP_RIGHT in elem.dirs do res += 1
				}
			case .UP_RIGHT:
				{
					elem := mases[c.coord_to_idx(pos + 2 * Dir_Vecs[.UP], size)]
					if .DOWN_RIGHT in elem.dirs do res += 1
				}
				{
					elem := mases[c.coord_to_idx(pos + 2 * Dir_Vecs[.RIGHT], size)]
					if .UP_LEFT in elem.dirs do res += 1
				}
			case .DOWN_LEFT:
				{
					elem := mases[c.coord_to_idx(pos + 2 * Dir_Vecs[.DOWN], size)]
					if .UP_LEFT in elem.dirs do res += 1
				}
				{
					elem := mases[c.coord_to_idx(pos + 2 * Dir_Vecs[.LEFT], size)]
					if .DOWN_RIGHT in elem.dirs do res += 1
				}
			case .DOWN_RIGHT:
				{
					elem := mases[c.coord_to_idx(pos + 2 * Dir_Vecs[.DOWN], size)]
					if .UP_RIGHT in elem.dirs do res += 1
				}
				{
					elem := mases[c.coord_to_idx(pos + 2 * Dir_Vecs[.RIGHT], size)]
					if .DOWN_LEFT in elem.dirs do res += 1
				}
			case:
				panic("unexepected case")
			}
		}
	}

	res /= 2

	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input)
	testing.expectf(t, res == 18, "expected %d, got %d", 18, res)
}

@(test)
p2_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p2(input)
	testing.expectf(t, res == 9, "expected %d, got %d", 9, res)
}
