package main

import c "../common"
import pq "core:container/priority_queue"
import "core:fmt"
import "core:math"
import "core:math/linalg"
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
	NUM_ITERATIONS :: 1

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
	EAST,
	SOUTH,
	WEST,
	NORTH,
}
Dir_Vecs := [Dir][2]int {
	.NORTH = {0, -1},
	.SOUTH = {0, 1},
	.EAST  = {1, 0},
	.WEST  = {-1, 0},
}

turn_left :: proc(dir: Dir) -> Dir {
	switch dir {
	case .NORTH:
		return .WEST
	case .SOUTH:
		return .EAST
	case .EAST:
		return .NORTH
	case .WEST:
		return .SOUTH
	}
	unreachable()
}

turn_right :: proc(dir: Dir) -> Dir {
	switch dir {
	case .NORTH:
		return .EAST
	case .SOUTH:
		return .WEST
	case .EAST:
		return .SOUTH
	case .WEST:
		return .NORTH
	}
	unreachable()
}

p1 :: proc(input: string) -> (res: int) {
	Node :: struct {
		point: [2]int,
		dir:   Dir,
		score: int,
	}

	context.allocator = context.temp_allocator
	defer free_all(context.temp_allocator)

	start, end: [2]int
	size := c.grid_size(input)

	for y in 0 ..< size.y {
		for x in 0 ..< size.x {
			tile := input[c.coord_to_idx({x, y}, size)]
			if tile == 'S' do start = {x, y}
			if tile == 'E' do end = {x, y}
		}
	}

	q: pq.Priority_Queue(Node)
	pq.init(
		&q,
		proc(a, b: Node) -> bool {return a.score < b.score},
		proc(q: []Node, i, j: int) {slice.swap(q, i, j)},
	)
	pq.push(&q, Node{start, .EAST, 0})

	seen: map[struct {
		_: [2]int,
		_: Dir,
	}]int
	for pq.len(q) > 0 {
		node := pq.pop(&q)

		if node.point == end do return node.score
		elem, exists := seen[{node.point, node.dir}]
		if exists && elem < node.score do continue
		seen[{node.point, node.dir}] = node.score
		if input[c.coord_to_idx(node.point + Dir_Vecs[node.dir], size)] != '#' {
			pq.push(&q, Node{node.point + Dir_Vecs[node.dir], node.dir, node.score + 1})
		}
		pq.push(&q, Node{node.point, turn_left(node.dir), node.score + 1000})
		pq.push(&q, Node{node.point, turn_right(node.dir), node.score + 1000})
	}

	return
}

p2 :: proc(input: string) -> (res: int) {
	Node :: struct {
		point: [dynamic][2]int,
		dir:   Dir,
		score: int,
	}

	context.allocator = context.temp_allocator
	defer free_all(context.temp_allocator)

	start, end: [2]int
	size := c.grid_size(input)

	for y in 0 ..< size.y {
		for x in 0 ..< size.x {
			tile := input[c.coord_to_idx({x, y}, size)]
			if tile == 'S' do start = {x, y}
			if tile == 'E' do end = {x, y}
		}
	}

	q: pq.Priority_Queue(Node)
	pq.init(
		&q,
		proc(a, b: Node) -> bool {return a.score < b.score},
		proc(q: []Node, i, j: int) {slice.swap(q, i, j)},
	)
	pq.push(&q, Node{{start}, .EAST, 0})

	min := max(int)
	best: map[[2]int]struct {}
	seen: map[struct {
		_: [2]int,
		_: Dir,
	}]int
	for pq.len(q) > 0 {
		node := pq.pop(&q)

		if slice.last(node.point[:]) == end {
			if node.score <= min do min = node.score
			else do return len(best)
			for p in node.point {
				best[p] = {}
			}
		}

		elem, exists := seen[{slice.last(node.point[:]), node.dir}]
		if exists && elem < node.score do continue
		seen[{slice.last(node.point[:]), node.dir}] = node.score
		if input[c.coord_to_idx(slice.last(node.point[:]) + Dir_Vecs[node.dir], size)] != '#' {
			p := slice.clone_to_dynamic(node.point[:])
			append(&p, slice.last(p[:]) + Dir_Vecs[node.dir])
			pq.push(&q, Node{p, node.dir, node.score + 1})
		}
		pq.push(&q, Node{node.point, turn_left(node.dir), node.score + 1000})
		pq.push(&q, Node{node.point, turn_right(node.dir), node.score + 1000})
	}

	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input)
	testing.expectf(t, res == 11048, "expected %d, got %d", 11048, res)
}

@(test)
p2_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p2(input)
	testing.expectf(t, res == 64, "expected %d, got %d", 64, res)
}
