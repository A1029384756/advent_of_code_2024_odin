package main

import c "../common"
import q "core:container/queue"
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

Pos :: [2]int

p1 :: proc(i: string) -> (res: int) {
	context.allocator = context.temp_allocator
	defer free_all(context.temp_allocator)

	size := c.grid_size(i)
	input := make([]u8, len(i) + size.x)
	for i in 0 ..< size.x {
		input[len(input) - i - 1] = '\n'
	}
	copy(input[:], i[:])

	trailheads: [dynamic][2]int
	for y in 0 ..< size.y {
		for x in 0 ..< size.x {
			if input[c.coord_to_idx({x, y}, size)] == '0' {
				append(&trailheads, [2]int{x, y})
			}
		}
	}

	visited := make([]bool, len(input))
	queue: q.Queue(Pos)
	q.init(&queue)

	for trailhead in trailheads {
		defer q.clear(&queue)
		defer slice.zero(visited)

		visited[c.coord_to_idx(trailhead, size)] = true
		q.push_back(&queue, trailhead)

		for q.len(queue) > 0 {
			v := q.pop_front(&queue)
			if input[c.coord_to_idx(v, size)] == '9' {
				res += 1
			}

			for dir in Dir_Vecs {
				next_idx := c.coord_to_idx(dir + v, size)

				if next_idx < 0 || input[next_idx] == '\n' do continue
				curr_elevation := int(input[c.coord_to_idx(v, size)])
				next_elevation := int(input[next_idx])
				if next_elevation - curr_elevation != 1 do continue
				if visited[next_idx] do continue

				visited[next_idx] = true
				q.push_back(&queue, dir + v)
			}
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

	trailheads: [dynamic][2]int
	for y in 0 ..< size.y {
		for x in 0 ..< size.x {
			if input[c.coord_to_idx({x, y}, size)] == '0' {
				append(&trailheads, [2]int{x, y})
			}
		}
	}

	visited := make([]bool, len(input))
	queue: q.Queue(Pos)
	q.init(&queue)

	for trailhead in trailheads {
		defer q.clear(&queue)
		defer slice.zero(visited)

		visited[c.coord_to_idx(trailhead, size)] = true
		q.push_back(&queue, trailhead)

		for q.len(queue) > 0 {
			v := q.pop_front(&queue)
			if input[c.coord_to_idx(v, size)] == '9' {
				res += 1
			}

			for dir in Dir_Vecs {
				next_idx := c.coord_to_idx(dir + v, size)

				if next_idx < 0 || input[next_idx] == '\n' do continue
				curr_elevation := int(input[c.coord_to_idx(v, size)])
				next_elevation := int(input[next_idx])
				if next_elevation - curr_elevation != 1 do continue

				visited[next_idx] = true
				q.push_back(&queue, dir + v)
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
