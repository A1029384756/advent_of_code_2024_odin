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

Block :: struct {
	id:   int,
	ptr:  int,
	size: int,
}

p1 :: proc(input: string) -> (res: int) {
	blocks: [dynamic]Block
	defer delete(blocks)
	free_list: [dynamic]Block
	defer delete(free_list)

	free_space: bool
	block_id, curr_ptr: int
	for idx in 0 ..< len(input) {
		curr_int := c.parse_int_fast(input[idx:idx + 1])
		if curr_int > 0 {
			if !free_space {
				for i in 0 ..< curr_int {
					append(&blocks, Block{block_id, curr_ptr + i, 1})
				}
				block_id += 1
			} else {
				append(&free_list, Block{0, curr_ptr, curr_int})
			}
		}
		free_space = !free_space
		curr_ptr += curr_int
	}

	#reverse for &block, idx in blocks {
		if len(free_list) == 0 do continue
		if free_list[0].ptr > block.ptr do break

		block.ptr = free_list[0].ptr
		if free_list[0].size == 1 {
			pop_front(&free_list)
		} else {
			free_list[0].size -= 1
			free_list[0].ptr += 1
		}
	}

	for block, idx in blocks {
		res += block.id * block.ptr
	}

	return
}

p2 :: proc(input: string) -> (res: int) {
	files: [dynamic]Block
	defer delete(files)
	free_list: [dynamic]Block
	defer delete(free_list)

	free_space: bool
	block_id, curr_ptr: int
	for idx in 0 ..< len(input) {
		curr_int := c.parse_int_fast(input[idx:idx + 1])
		if curr_int > 0 {
			if !free_space {
				append(&files, Block{block_id, curr_ptr, curr_int})
				block_id += 1
			} else {
				append(&free_list, Block{0, curr_ptr, curr_int})
			}
		}
		free_space = !free_space
		curr_ptr += curr_int
	}

	#reverse for &file, idx in files {
		context.user_ptr = &files
		context.user_index = idx
		first_free := slice.linear_search_proc(free_list[:], proc(free_space: Block) -> bool {
			curr_file := (cast(^[dynamic]Block)context.user_ptr)[context.user_index]
			return free_space.size >= curr_file.size && free_space.ptr < curr_file.ptr
		}) or_continue

		file.ptr = free_list[first_free].ptr
		if free_list[first_free].size == file.size {
			ordered_remove(&free_list, first_free)
		} else {
			free_list[first_free].size -= file.size
			free_list[first_free].ptr += file.size
		}
	}

	for file in files {
		for i in 0 ..< file.size {
			res += (file.ptr + i) * file.id
		}
	}

	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input)
	testing.expectf(t, res == 1928, "expected %d, got %d", 1928, res)
}

@(test)
p2_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p2(input)
	testing.expectf(t, res == 2858, "expected %d, got %d", 2858, res)
}