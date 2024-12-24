package main

import "core:fmt"
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

Op :: enum {
	XOR,
	OR,
	AND,
}

Wire :: struct {
	state:    int,
	op:       Op,
	lhs, rhs: string,
}

solve_wire :: proc(name: string, wires: map[string]Wire) -> (res: int) {
	wire := &wires[name]
	if strings.starts_with(name, "x") || strings.starts_with(name, "y") do return wire.state

	switch wire.op {
	case .AND:
		res = solve_wire(wire.lhs, wires) & solve_wire(wire.rhs, wires)
	case .OR:
		res = solve_wire(wire.lhs, wires) | solve_wire(wire.rhs, wires)
	case .XOR:
		res = solve_wire(wire.lhs, wires) ~ solve_wire(wire.rhs, wires)
	}

	return
}

p1 :: proc(input: string) -> (res: int) {
	context.allocator = context.temp_allocator
	defer free_all(context.temp_allocator)
	input := input

	wires: map[string]Wire
	section: bool
	for line in strings.split_lines_iterator(&input) {
		if line == "" {
			section = true
			continue
		}

		if !section {
			delim := strings.index(line, ":")
			wires[line[:delim]] = {
				state = int(line[len(line) - 1] - '0'),
			}
		} else {
			line_split := strings.split(line, " ")

			lhs := line_split[0]
			op_str := line_split[1]
			rhs := line_split[2]
			out := line_split[4]

			op: Op
			switch op_str {
			case "XOR":
				op = .XOR
			case "OR":
				op = .OR
			case "AND":
				op = .AND
			case:
				panic("invalid case")
			}

			wires[out] = {2, op, lhs, rhs}
		}
	}

	Z :: struct {
		name:  string,
		value: int,
	}

	zs: [dynamic]Z
	for name, &wire in wires {
		if strings.starts_with(name, "z") {
			wire.state = solve_wire(name, wires)
			append(&zs, Z{name, wire.state})
		}
	}
	slice.sort_by(zs[:], proc(i, j: Z) -> bool {return i.name > j.name})
	for elem in zs {
		res = (res << 1) | elem.value
	}

	return
}

detect_bad_gate :: proc(
	name: string,
	wires: map[string]Wire,
	bad_gates: ^[dynamic]string,
	max_bit: int,
) {
	wire := &wires[name]
	if strings.starts_with(name, "x") || strings.starts_with(name, "y") {
	}

	switch wire.op {
	case .AND:
		detect_bad_gate(wire.lhs, wires, bad_gates, max_bit)
		detect_bad_gate(wire.rhs, wires, bad_gates, max_bit)
	case .OR:
		detect_bad_gate(wire.lhs, wires, bad_gates, max_bit)
		detect_bad_gate(wire.rhs, wires, bad_gates, max_bit)
	case .XOR:
		detect_bad_gate(wire.lhs, wires, bad_gates, max_bit)
		detect_bad_gate(wire.rhs, wires, bad_gates, max_bit)
	}

	return
}

p2 :: proc(input: string) -> (res: string) {
	defer free_all(context.temp_allocator)
	input := input

	max_z: int
	wires := make(map[string]Wire, context.temp_allocator)
	section: bool
	for line in strings.split_lines_iterator(&input) {
		if line == "" {
			section = true
			continue
		}

		if !section {
			delim := strings.index(line, ":")
			wires[line[:delim]] = {
				state = int(line[len(line) - 1] - '0'),
			}
		} else {
			line_split := strings.split(line, " ", context.temp_allocator)

			lhs := line_split[0]
			op_str := line_split[1]
			rhs := line_split[2]
			out := line_split[4]

			op: Op
			switch op_str {
			case "XOR":
				op = .XOR
			case "OR":
				op = .OR
			case "AND":
				op = .AND
			case:
				panic("invalid case")
			}

			if out[0] == 'z' do max_z = max(max_z, strconv.atoi(out[1:]))
			wires[out] = {2, op, lhs, rhs}
		}
	}

	Z :: struct {
		name:  string,
		value: int,
	}

	max_bit_name := fmt.tprintf("z%02d", max_z)
	bad_gates: map[string]struct {}
	for name, &wire in wires {
		if len(name) == 0 do continue
		if name[0] == 'z' && wire.op != .XOR && name != max_bit_name {
			bad_gates[name] = {}
		}
		if wire.op == .XOR &&
		   !slice.contains([]u8{'x', 'y', 'z'}, name[0]) &&
		   !slice.contains([]u8{'x', 'y', 'z'}, wire.lhs[0]) &&
		   !slice.contains([]u8{'x', 'y', 'z'}, wire.rhs[0]) {
			bad_gates[name] = {}
		}
		if wire.op == .AND && !slice.contains([]string{wire.lhs, wire.lhs}, "x00") {
			for subname, &subwire in wires {
				if len(name) == 0 do continue
				if (name == subwire.lhs || name == subwire.rhs) && subwire.op != .OR {
					bad_gates[name] = {}
				}
			}
		}
		if wire.op == .XOR {
			for subname, &subwire in wires {
				if len(name) == 0 do continue
				if (name == subwire.lhs || name == subwire.rhs) && subwire.op == .OR {
					bad_gates[name] = {}
				}
			}
		}
	}

	gates, _ := slice.map_keys(bad_gates)
	slice.sort(gates)

	sb: strings.Builder
	strings.builder_init(&sb)
	for gate, idx in gates {
		strings.write_string(&sb, gate)
		if idx != len(gates) - 1 do strings.write_string(&sb, ",")
	}
	res = strings.to_string(sb)

	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	res := p1(input)
	testing.expect_value(t, res, 2024)
}
