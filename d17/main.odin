package main

import c "../common"
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

	{
		context.allocator = context.temp_allocator
		defer free_all(context.temp_allocator)
		stdout: [dynamic]int
		start := time.now()
		p1(input, &stdout)
		time := time.since(start)

		fmt.println(stdout[:], time)
	}

	{
		context.allocator = context.temp_allocator
		defer free_all(context.temp_allocator)
		start := time.now()
		res := p2(input)
		time := time.since(start)

		fmt.println(res, time)
	}
}

Opcode :: enum int {
	adv, // division: A / combo -> A
	bxl, // XOR: B ^ literal -> B
	bst, // modulo: combo % 8 -> B
	jnz, // jump A != 0: instruction_pointer = literal
	bxc, // XOR: B ^ C -> B
	out, // output: combo -> stdout (csv)
	bdv, // division: A / combo -> B
	cdv, // division: A / combo -> C
}

combo_operand :: proc(a, b, c, operand: int) -> int {
	if operand == 4 do return a
	if operand == 5 do return b
	if operand == 6 do return c
	else do return operand
}

CPU :: struct {
	a, b, c: int,
	program: [dynamic]int,
}

cpu_init :: proc(cpu: ^CPU, input: string, allocator := context.allocator) {
	input := input
	idx := 0
	regs: for line in c.split_iterator_fast(&input, '\n') {
		switch idx {
		case 0:
			cpu.a = c.parse_int_fast(line[12:])
		case 1:
			cpu.b = c.parse_int_fast(line[12:])
		case 2:
			cpu.c = c.parse_int_fast(line[12:])
		case 3:
			break regs
		case:
			unreachable()
		}
		idx += 1
	}

	input = input[9:]
	cpu.program = make([dynamic]int, allocator)
	for i := 0; i < len(input); {
		inst := int(input[i] - '0')
		i += 2
		operand := int(input[i] - '0')
		i += 2
		append(&cpu.program, inst, operand)
	}
}

cpu_step :: proc(cpu: ^CPU, ip: ^int, stdout: ^[dynamic]int) {
	inst := cpu.program[ip^]
	operand := cpu.program[ip^ + 1]
	ip^ += 2
	switch cast(Opcode)inst {
	case .adv:
		cpu.a >>= uint(operand)
	case .bxl:
		cpu.b ~= operand
	case .bst:
		cpu.b = combo_operand(cpu.a, cpu.b, cpu.c, operand) % 8
	case .jnz:
		if cpu.a != 0 do ip^ = operand
	case .bxc:
		cpu.b ~= cpu.c
	case .out:
		append(stdout, combo_operand(cpu.a, cpu.b, cpu.c, operand) % 8)
	case .bdv:
		cpu.b = cpu.a >> uint(combo_operand(cpu.a, cpu.b, cpu.c, operand))
	case .cdv:
		cpu.c = cpu.a >> uint(combo_operand(cpu.a, cpu.b, cpu.c, operand))
	}
}

p1 :: proc(input: string, stdout: ^[dynamic]int) {
	cpu: CPU
	cpu_init(&cpu, input)

	for i := 0; i < len(cpu.program); {
		cpu_step(&cpu, &i, stdout)
	}
}

find :: proc(program, expected: []int, ans: int) -> int {
	if len(expected) == 0 do return ans
	for t in 0 ..< 8 {
		a := (ans << 3) | t
		b, c, adv: int
		output := -1

		for ip := 0; ip < len(program) - 2; {
			inst := program[ip]
			operand := program[ip + 1]
			ip += 2
			combo := combo_operand(a, b, c, operand)
			switch cast(Opcode)inst {
			case .adv:
				adv += 1
				if adv == 2 do panic("bad adv")
			case .bxl:
				b ~= operand
			case .bst:
				b = combo % 8
			case .jnz:
				panic("jnz")
			case .bxc:
				b ~= c
			case .out:
				output = combo % 8
			case .bdv:
				b = a >> uint(combo)
			case .cdv:
				c = a >> uint(combo)
			}
		}
		if output == expected[len(expected) - 1] {
			sub := find(program, expected[:len(expected) - 1], a)
			if sub < 0 do continue
			return sub
		}
	}

	return -1
}

p2 :: proc(input: string) -> (res: int) {
	cpu: CPU
	cpu_init(&cpu, input)
	res = find(cpu.program[:], cpu.program[:], 0)
	return
}

@(test)
p1_test :: proc(t: ^testing.T) {
	input := #load("./p1_sample.txt", string)
	context.allocator = context.temp_allocator
	defer free_all(context.temp_allocator)

	stdout: [dynamic]int
	p1(input, &stdout)
	expected := []int{4, 6, 3, 5, 6, 3, 5, 2, 1, 0}
	testing.expectf(
		t,
		slice.equal(stdout[:], expected),
		"expected %d, got %d",
		expected,
		stdout[:],
	)
}
