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
	NUM_ITERATIONS :: 1

	{
		max_t, total_t: time.Duration
		min_t := max(time.Duration)
		res: int

		for _ in 0 ..< WARMUP_ITERATIONS {
			res = p1(input, {101, 103})
		}

		for _ in 0 ..< NUM_ITERATIONS {
			start := time.now()
			res = p1(input, {101, 103})
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
			res = p2(input, {101, 103})
		}

		for _ in 0 ..< NUM_ITERATIONS {
			start := time.now()
			res = p2(input, {101, 103})
			time := time.since(start)
			min_t = min(time, min_t)
			max_t = max(time, max_t)
			total_t += time
		}

		fmt.println(res, min_t, max_t, total_t / NUM_ITERATIONS)
	}
}

Robot :: struct {
	pos, vel: [2]int,
}

robot_parse :: proc(input: string) -> (res: Robot) {
	input := input
	is_vel: bool
	for part in strings.split_iterator(&input, " ") {
		part := part
		part = part[2:]

		vec: [2]int
		vec_idx: int
		for num in strings.split_iterator(&part, ",") {
			valid: bool
			vec[vec_idx], valid = strconv.parse_int(num)
			assert(valid)
			vec_idx += 1
		}

		if !is_vel {
			res.pos = vec
		} else {
			res.vel = vec
		}
		is_vel = true
	}
	return
}

robot_move :: proc(robot: ^Robot, size: [2]int) {
	robot.pos += robot.vel
	if robot.pos.x >= size.x {
		robot.pos.x %= size.x
	} else if robot.pos.x < 0 {
		robot.pos.x = size.x + robot.pos.x
	}

	if robot.pos.y >= size.y {
		robot.pos.y %= size.y
	} else if robot.pos.y < 0 {
		robot.pos.y = size.y + robot.pos.y
	}
}

p1 :: proc(input: string, size: [2]int) -> int {
	input := input

	robots: [dynamic]Robot
	defer delete(robots)

	for line in strings.split_lines_iterator(&input) {
		robot := robot_parse(line)
		append(&robots, robot)
	}

	for _ in 0 ..< 100 {
		for &robot in robots {
			robot_move(&robot, size)
		}
	}

	top_left, top_right, bottom_left, bottom_right: int
	middle := size / 2
	for robot in robots {
		if robot.pos.x < middle.x && robot.pos.y < middle.y do top_left += 1
		if robot.pos.x > middle.x && robot.pos.y < middle.y do top_right += 1
		if robot.pos.x < middle.x && robot.pos.y > middle.y do bottom_left += 1
		if robot.pos.x > middle.x && robot.pos.y > middle.y do bottom_right += 1
	}

	return top_left * top_right * bottom_left * bottom_right
}

builder_print_grid :: proc(builder: ^strings.Builder, density: []int, size: [2]int) {
	fmt.sbprintln(builder)
	for elem, idx in density {
		if idx % size.x == 0 {
			fmt.sbprintln(builder)
		}
		fmt.sbprint(builder, elem > 0 ? "*" : " ")
	}
	fmt.sbprintln(builder)
}

p2 :: proc(input: string, size: [2]int) -> (res: int) {
	input := input

	robots: [dynamic]Robot
	defer delete(robots)

	for line in strings.split_lines_iterator(&input) {
		robot := robot_parse(line)
		append(&robots, robot)
	}

	density := make([]int, size.x * size.y)
	defer delete(density)
	for {
		slice.zero(density)
		for &robot in robots {
			robot_move(&robot, size)
			density[size.x * robot.pos.y + robot.pos.x] += 1
		}

		cur_run, max_run: int
		for i := 0; i < len(density) - 1; i += 1 {
			if density[i] > 0 && density[i + 1] > 0 {
				cur_run += 1
			} else {
				max_run = max(max_run, cur_run)
				cur_run = 0
			}
		}

		if max_run > 5 {
			break
		}

		res += 1
	}
	res += 1

	return
}

@(test)
movement_test :: proc(t: ^testing.T) {
	size := [2]int{11, 7}
	r := Robot{{2, 4}, {2, -3}}
	for _ in 0 ..< 5 {
		robot_move(&r, size)
	}

	testing.expectf(t, r.pos == {1, 3}, "expected %v, got %v", [2]int{1, 3}, r.pos)
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input, {11, 7})
	testing.expectf(t, res == 12, "expected %d, got %d", 12, res)
}
