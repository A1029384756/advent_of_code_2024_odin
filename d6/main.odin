package main

import c "../common"
import "core:fmt"
import "core:os/os2"
import "core:slice"
import "core:strings"
import "core:sync"
import "core:testing"
import "core:thread"
import "core:time"

@(optimization_mode = "none")
main :: proc() {
	input_bytes, err := os2.read_entire_file("./input/d6.txt", context.allocator)
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

Guard :: struct {
	pos: [2]int,
	dir: Dir,
}

guard_turn :: proc(guard: ^Guard) {
	switch guard.dir {
	case .UP:
		guard.dir = .RIGHT
	case .DOWN:
		guard.dir = .LEFT
	case .LEFT:
		guard.dir = .UP
	case .RIGHT:
		guard.dir = .DOWN
	case .NONE:
		panic("invalid dir")
	}
}

get_path :: proc(
	input: string,
	guard: Guard,
	size: [2]int,
	alloc := context.allocator,
) -> [dynamic][2]int {
	visited := make([]bool, len(input))
	defer delete(visited)

	path: [dynamic][2]int

	guard := guard
	guard_step: for {
		if !c.coord_valid(guard.pos + Dir_Vecs[guard.dir], size) {
			break guard_step
		}

		turn: for {
			if input[c.coord_to_idx(guard.pos + Dir_Vecs[guard.dir], size)] == '#' {
				guard_turn(&guard)
			} else {
				break turn
			}
		}

		guard.pos += Dir_Vecs[guard.dir]
		if !visited[c.coord_to_idx(guard.pos, size)] {
			visited[c.coord_to_idx(guard.pos, size)] = true
			append(&path, guard.pos)
		}
	}

	return path
}

p1 :: proc(input: string) -> (res: int) {
	visited := make([]bool, len(input))
	defer delete(visited)

	size := c.grid_size(input)

	guard := Guard {
		dir = .UP,
	}

	find_guard: for y in 0 ..< size.y {
		for x in 0 ..< size.x {
			if input[c.coord_to_idx({x, y}, size)] == '^' {
				guard.pos = {x, y}
				break find_guard
			}
		}
	}

	guard_step: for {
		guard_next_pos := guard.pos + Dir_Vecs[guard.dir]
		if guard_next_pos.x < 0 ||
		   guard_next_pos.x >= size.x ||
		   guard_next_pos.y < 0 ||
		   guard_next_pos.y >= size.y {
			break guard_step
		}

		turn: for {
			if input[c.coord_to_idx(guard.pos + Dir_Vecs[guard.dir], size)] == '#' {
				guard_turn(&guard)
			} else {
				break turn
			}
		}

		guard.pos += Dir_Vecs[guard.dir]
		if !visited[c.coord_to_idx(guard.pos, size)] {
			visited[c.coord_to_idx(guard.pos, size)] = true
			res += 1
		}
	}

	return
}


p2 :: proc(input: string) -> (res: int) {
	size := c.grid_size(input)

	guard := Guard {
		dir = .UP,
	}

	find_guard: for y in 0 ..< size.y {
		for x in 0 ..< size.x {
			if input[c.coord_to_idx({x, y}, size)] == '^' {
				guard.pos = {x, y}
				break find_guard
			}
		}
	}

	escape_path := get_path(input, guard, size)
	defer delete(escape_path)

	Thread_In :: struct {
		guard: Guard,
		input: string,
		size:  [2]int,
		pos:   [2]int,
		res:   ^int,
	}

	task_proc :: proc(task: thread.Task) {
		tasks := cast(^[dynamic]Thread_In)task.data
		tin := tasks[task.user_index]
		using tin

		visited := make([]Dir, len(input))
		defer delete(visited)

		guard_step: for {
			if !c.coord_valid(guard.pos + Dir_Vecs[guard.dir], size) {
				break guard_step
			}

			turn: for {
				if input[c.coord_to_idx(guard.pos + Dir_Vecs[guard.dir], size)] == '#' ||
				   (guard.pos + Dir_Vecs[guard.dir]) == pos {
					guard_turn(&guard)
				} else {
					break turn
				}
			}

			guard.pos += Dir_Vecs[guard.dir]

			prev_dir := visited[c.coord_to_idx(guard.pos, size)]
			if prev_dir != .NONE && prev_dir == guard.dir {
				sync.atomic_add(res, 1)
				break guard_step
			}

			visited[c.coord_to_idx(guard.pos, size)] = guard.dir
		}
	}

	p: thread.Pool
	thread.pool_init(&p, context.allocator, 8)
	defer thread.pool_destroy(&p)

	tasks := make([dynamic]Thread_In, 0, len(escape_path))
	defer delete(tasks)

	for pos in escape_path {
		if pos == guard.pos do continue
		append(&tasks, Thread_In{guard, input, size, pos, &res})
		thread.pool_add_task(&p, context.allocator, task_proc, &tasks, len(&tasks) - 1)
	}

	thread.pool_start(&p)
	thread.pool_finish(&p)

	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input)
	testing.expectf(t, res == 41, "expected %d, got %d", 41, res)
}

@(test)
p2_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p2(input)
	testing.expectf(t, res == 6, "expected %d, got %d", 6, res)
}
