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
	disk: [dynamic]int
	defer delete(disk)

	is_free: bool
	block_id: int
	for char in input {
		curr_int := int(char - '0')
		for i in 0 ..< curr_int {
			append(&disk, is_free ? -1 : block_id)
		}
		block_id += is_free ? 0 : 1
		is_free = !is_free
	}

	i := 0
	j := len(disk) - 1
	for i < j {
		if disk[i] != -1 do i += 1
		if disk[j] == -1 do j -= 1
		if disk[i] == -1 && disk[j] != -1 do slice.swap(disk[:], i, j)
	}

	for data, idx in disk {
		if data < 0 do break
		res += data * idx
	}

	return
}

p2 :: proc(input: string) -> (res: int) {
	files: [dynamic]Block
	defer delete(files)
	free_list: [dynamic]Block
	defer delete(free_list)

	is_free: bool
	block_id, curr_ptr: int
	for char in input {
		curr_int := int(char - '0')
		append(is_free ? &free_list : &files, Block{block_id, curr_ptr, curr_int})
		curr_ptr += curr_int
		block_id += is_free ? 0 : 1
		is_free = !is_free
	}

	max_file_size := max(int)
	#reverse for &file in files {
		if file.size > max_file_size do continue

		moved: bool
		for &free_elem in free_list {
			if file.ptr < free_elem.ptr do continue
			if free_elem.size < file.size do continue

			file.ptr = free_elem.ptr
			free_elem.size -= file.size
			free_elem.ptr += file.size
			moved = true
			break
		}
		if !moved do max_file_size = file.size
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
