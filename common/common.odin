package common

parse_int_fast :: proc(input: string) -> (res: int) {
	for i in 0 ..< len(input) {
		res = res * 10 + (int(input[i]) - '0')
	}
	return
}

split_iterator_fast :: proc(input: ^string, sep: u8) -> (res: string, ok: bool) {
	i: int
	for i = 0; i < len(input); i += 1 {
		if input[i] == sep {
			ok = true
			break
		}
	}

	if ok {
		res = input[:i]
		input^ = input[i + 1:]
	} else {
		res = input[:]
		ok = res != ""
		input^ = input[len(input):]
	}

	return
}

find_fast :: proc(input: string, char: u8) -> int {
	for i in 0 ..< len(input) {
		if input[i] == char do return i
	}
	return -1
}

coord_to_idx :: #force_inline proc(pos, grid_size: [2]int) -> int {
	return grid_size.x * pos.y + pos.x + pos.y
}

coord_valid :: #force_inline proc(pos, size: [2]int) -> bool {
	return pos.x >= 0 && pos.y >= 0 && pos.x < size.x && pos.y < size.y
}

grid_size :: proc(input: string) -> (size: [2]int) {
	for i in 0 ..< len(input) {
		if input[i] == '\n' do break
		size.x += 1
	}
	tmp := len(input) / size.x
	size.y = tmp - (tmp % size.x)
	return
}

scry :: proc(input: string, cmp: string) -> bool {
	assert(len(cmp) <= 8)
	SWAR :: #config(SWAR, true)
	when SWAR {
		shamt := 8 * uint(size_of(uint) - len(cmp))
		cmp := (transmute(^uint)raw_data(cmp))^
		cmp = (cmp << shamt) >> shamt
		input := (transmute(^uint)raw_data(input))^
		input = (input << shamt) >> shamt

		return cmp == input
	} else {
		return len(input) >= len(cmp) && input[:len(cmp)] == cmp
	}
}
