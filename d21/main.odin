package main

import c "../common"
import sa "core:container/small_array"
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

// ME -> ROBOT C -> ROBOT B -> ROBOT A

/*
ROBOT A
+---+---+---+
| 7 | 8 | 9 |
+---+---+---+
| 4 | 5 | 6 |
+---+---+---+
| 1 | 2 | 3 |
+---+---+---+
    | 0 | A |
    +---+---+
*/

/*
ME, ROBOT B, ROBOT C
    +---+---+
    | ^ | A |
+---+---+---+
| < | v | > |
+---+---+---+
*/

Dirpad := "X^A<v>"
Numpad := "789456123X0A"

Visit :: struct {
	pos:     [2]int,
	presses: string,
}

Cache_Line :: struct {
	curr, dest: [2]int,
	nrobots:    int,
}

robot_cheapest :: proc(
	presses: string,
	nrobots: int,
	cache: ^map[Cache_Line]int,
	allocator := context.temp_allocator,
) -> (
	res: int,
) {
	if nrobots == 1 do return len(presses)


	curr := [2]int{2, 0}
	for press in presses {
		for y in 0 ..< 2 {
			for x in 0 ..< 3 {
				if rune(Dirpad[y * 3 + x]) == press {
					res += dirpad_cheapest(curr, {x, y}, nrobots, cache, allocator)
					curr = {x, y}
				}
			}
		}
	}
	return
}

dirpad_cheapest :: proc(
	curr, dest: [2]int,
	nrobots: int,
	cache: ^map[Cache_Line]int,
	allocator := context.temp_allocator,
) -> int {
	val, exists := cache[Cache_Line{curr, dest, nrobots}]
	if exists do return val

	res := max(int)
	queue := make([dynamic]Visit, allocator)
	append(&queue, Visit{curr, ""})
	for len(queue) > 0 {
		visit := pop_front(&queue)
		if visit.pos == dest {
			rec := robot_cheapest(
				strings.concatenate({visit.presses, "A"}, allocator),
				nrobots - 1,
				cache,
				allocator,
			)
			res = min(res, rec)
			continue
		}

		if visit.pos == {0, 0} do continue
		if visit.pos.x < dest.x {
			append(
				&queue,
				Visit{visit.pos + {1, 0}, strings.concatenate({visit.presses, ">"}, allocator)},
			)
		} else if visit.pos.x > dest.x {
			append(
				&queue,
				Visit{visit.pos + {-1, 0}, strings.concatenate({visit.presses, "<"}, allocator)},
			)
		}

		if visit.pos.y < dest.y {
			append(
				&queue,
				Visit{visit.pos + {0, 1}, strings.concatenate({visit.presses, "v"}, allocator)},
			)
		} else if visit.pos.y > dest.y {
			append(
				&queue,
				Visit{visit.pos + {0, -1}, strings.concatenate({visit.presses, "^"}, allocator)},
			)
		}
	}

	cache[Cache_Line{curr, dest, nrobots}] = res
	return res
}

path_cheapest :: proc(
	curr, dest: [2]int,
	nrobots: int,
	cache: ^map[Cache_Line]int,
	allocator := context.temp_allocator,
) -> int {
	res := max(int)
	queue := make([dynamic]Visit, allocator)
	append(&queue, Visit{curr, ""})
	for len(queue) > 0 {
		visit := pop_front(&queue)
		if visit.pos == dest {
			rec := robot_cheapest(
				strings.concatenate({visit.presses, "A"}, allocator),
				nrobots,
				cache,
				allocator,
			)
			res = min(res, rec)
			continue
		}

		if visit.pos == {0, 3} do continue
		if visit.pos.x < dest.x {
			append(
				&queue,
				Visit{visit.pos + {1, 0}, strings.concatenate({visit.presses, ">"}, allocator)},
			)
		} else if visit.pos.x > dest.x {
			append(
				&queue,
				Visit{visit.pos + {-1, 0}, strings.concatenate({visit.presses, "<"}, allocator)},
			)
		}

		if visit.pos.y < dest.y {
			append(
				&queue,
				Visit{visit.pos + {0, 1}, strings.concatenate({visit.presses, "v"}, allocator)},
			)
		} else if visit.pos.y > dest.y {
			append(
				&queue,
				Visit{visit.pos + {0, -1}, strings.concatenate({visit.presses, "^"}, allocator)},
			)
		}
	}

	return res
}

p1 :: proc(input: string) -> (res: int) {
	input := input
	cache: map[Cache_Line]int
	defer delete(cache)

	path: [dynamic]u8
	defer delete(path)
	for line in c.split_iterator_fast(&input, '\n') {
		curr := [2]int{2, 3}
		num_steps, numeric_portion: int
		for char in line {
			if char >= '0' && char <= '9' do numeric_portion = numeric_portion * 10 + int(char - '0')
			for y in 0 ..< 4 {
				for x in 0 ..< 3 {
					if char == rune(Numpad[y * 3 + x]) {
						num_steps += path_cheapest(curr, {x, y}, 3, &cache)
						curr = {x, y}
						free_all(context.temp_allocator)
					}
				}
			}
		}
		res += num_steps * numeric_portion
	}
	return
}

p2 :: proc(input: string) -> (res: int) {
	input := input
	cache: map[Cache_Line]int
	defer delete(cache)

	path: [dynamic]u8
	defer delete(path)
	for line in c.split_iterator_fast(&input, '\n') {
		curr := [2]int{2, 3}
		num_steps, numeric_portion: int
		for char in line {
			if char >= '0' && char <= '9' do numeric_portion = numeric_portion * 10 + int(char - '0')
			for y in 0 ..< 4 {
				for x in 0 ..< 3 {
					if char == rune(Numpad[y * 3 + x]) {
						num_steps += path_cheapest(curr, {x, y}, 26, &cache)
						curr = {x, y}
						free_all(context.temp_allocator)
					}
				}
			}
		}
		res += num_steps * numeric_portion
	}
	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input)
	testing.expectf(t, res == 126384, "expected %d, got %d", 126384, res)
}
