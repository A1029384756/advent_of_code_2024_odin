package main

import "core:fmt"
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
		res: string

		for _ in 0 ..< WARMUP_ITERATIONS {
			res = p2(input)
			delete(res)
		}

		for iter in 0 ..< NUM_ITERATIONS {
			start := time.now()
			res = p2(input)
			time := time.since(start)
			min_t = min(time, min_t)
			max_t = max(time, max_t)
			total_t += time
			if iter < NUM_ITERATIONS - 1 do delete(res)
		}

		fmt.println(res, min_t, max_t, total_t / NUM_ITERATIONS)
		delete(res)
	}
}

GRAPH_SIZE :: 26 * 26

connection_to_idx :: proc(input: string) -> (res: int) {
	for char in input do res = res * 26 + int(char - 'a')
	return
}

idx_to_connection :: proc(idx: int) -> [2]u8 {
	return {u8(idx / 26 + int('a')), u8(idx % 26 + int('a'))}
}

p1 :: proc(input: string) -> (res: int) {
	keys: map[int]struct {}
	graph := make([][GRAPH_SIZE]bool, GRAPH_SIZE)
	defer delete(graph)

	input := input
	for line in strings.split_lines_iterator(&input) {
		idx := strings.index(line, "-")
		lhs := connection_to_idx(line[:idx])
		rhs := connection_to_idx(line[idx + 1:])

		graph[lhs][rhs] = true
		graph[rhs][lhs] = true
		keys[lhs] = {}
		keys[rhs] = {}
	}

	computers, _ := slice.map_keys(keys)
	defer delete(computers)
	delete(keys)

	for i_ in 0 ..< len(computers) {
		for j_ in i_ ..< len(computers) {
			i := computers[i_]
			j := computers[j_]
			if !graph[i][j] do continue

			for k_ in j_ ..< len(computers) {
				k := computers[k_]
				if graph[j][k] && graph[i][k] {
					I := idx_to_connection(i)
					J := idx_to_connection(j)
					K := idx_to_connection(k)
					if I[0] == 't' || J[0] == 't' || K[0] == 't' do res += 1
				}
			}
		}
	}

	return
}

p2 :: proc(input: string, allocator := context.allocator) -> (res: string) {
	keys: map[int]struct {}
	graph := make([][GRAPH_SIZE]bool, GRAPH_SIZE)
	defer delete(graph)

	input := input
	for line in strings.split_lines_iterator(&input) {
		idx := strings.index(line, "-")
		lhs := connection_to_idx(line[:idx])
		rhs := connection_to_idx(line[idx + 1:])

		graph[lhs][rhs] = true
		graph[rhs][lhs] = true
		keys[lhs] = {}
		keys[rhs] = {}
	}

	computers, _ := slice.map_keys(keys)
	defer delete(computers)
	delete(keys)

	connected_count := make([]int, GRAPH_SIZE)
	defer delete(connected_count)
	for i_ in 0 ..< len(computers) {
		for j_ in i_ ..< len(computers) {
			i := computers[i_]
			j := computers[j_]
			if !graph[i][j] do continue

			for k_ in j_ ..< len(computers) {
				k := computers[k_]
				if graph[j][k] && graph[i][k] {
					connected_count[i] += 1
					connected_count[j] += 1
					connected_count[k] += 1
				}
			}
		}
	}

	max_connections, _ := slice.max(connected_count)
	seq: [dynamic]int
	defer delete(seq)
	for computer in computers {
		if connected_count[computer] == max_connections {
			append(&seq, computer)
		}
	}
	slice.sort(seq[:])

	sb: strings.Builder
	strings.builder_init(&sb)
	for computer, idx in seq {
		computer_name := idx_to_connection(computer)
		strings.write_string(&sb, string(computer_name[:]))
		if idx != len(seq) - 1 do strings.write_string(&sb, ",")
	}
	res = strings.to_string(sb)

	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input)
	testing.expect_value(t, res, 7)
}
