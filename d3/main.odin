package d3

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


Parser :: struct {
	disabled:    bool,
	comma_found: bool,
	lhs, rhs:    int,
}

INST :: "mul("
ENABLE :: "do()"
DISABLE :: "don't()"

parse_mul :: proc(parser: ^Parser, input: string, i: ^int, total: ^int) {
	inst: for {
		char := input[i^]
		if char >= '0' && char <= '9' {
			if !parser.comma_found {
				parser.lhs = parser.lhs * 10 + int(char - '0')
			} else {
				parser.rhs = parser.rhs * 10 + int(char - '0')
			}
			i^ += 1
		} else if char == ',' && parser.lhs != 0 {
			parser.comma_found = true
			i^ += 1
		} else if char == ')' && parser.rhs != 0 {
			total^ += parser.lhs * parser.rhs
			parser^ = Parser{}
			i^ += 1
			break inst
		} else {
			parser^ = Parser{}
			break inst
		}
	}
}

p1 :: proc(input: string) -> (total: int) {
	parser: Parser
	for i := 0; i < len(input); {
		if c.scry(input[i:], INST) {
			i += len(INST)
			parse_mul(&parser, input, &i, &total)
		} else {
			i += 1
		}
	}

	return
}

p2 :: proc(input: string) -> (total: int) {
	parser: Parser
	for i := 0; i < len(input); {
		if c.scry(input[i:], ENABLE) {
			i += len(ENABLE)
			parser.disabled = false
		}
		if c.scry(input[i:], DISABLE) {
			i += len(DISABLE)
			parser.disabled = true
		}

		if parser.disabled {
			i += 1
			continue
		}

		if c.scry(input[i:], INST) {
			i += len(INST)
			parse_mul(&parser, input, &i, &total)
		} else {
			i += 1
		}
	}

	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./sample.txt", string)
	res := p1(input)
	testing.expectf(t, res == 161, "got %d", res)
}

@(test)
p2_test :: proc(t: ^testing.T) {
	input := #load("./sample2.txt", string)
	res := p2(input)
	testing.expectf(t, res == 48, "got %d", res)
}
