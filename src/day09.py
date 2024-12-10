from dataclasses import dataclass
from pathlib import Path

current_dir = Path(__file__).parent

data = (current_dir / "inputs" / "09.txt").read_text().strip()
disk_map = list(map(int, data))


@dataclass
class Block:
    index: int
    size: int
    id: int | None = None


def get_layout(disk_map: list[int]) -> tuple[list[Block], list[Block]]:
    empty_blocks = []
    non_empty_blocks = []
    
    index = 0
    block_id = 0
    is_empty = False
    for item in disk_map:
        if is_empty:
            empty_blocks.append(Block(index=index, size=item))
        else:
            non_empty_blocks.append(Block(index=index, size=item, id=block_id))
            block_id += 1

        index += item
        is_empty = not is_empty

    return non_empty_blocks, empty_blocks


def print_layout(non_empty_blocks: list[Block]):
    prev_index = 0
    for block in non_empty_blocks:
        for _ in range(block.index - prev_index):
            print(".", end="")
        
        prev_index = block.index + block.size
        
        for _ in range(block.size):
            print(block.id, end="")

    print()


def part2():
    non_empty_blocks, empty_blocks = list(get_layout(disk_map))
    # print_layout(non_empty_blocks)

    for block in reversed(non_empty_blocks):
        for empty in empty_blocks:
            if block.size <= empty.size:
                block.index = empty.index
                empty.size -= block.size
                empty.index += block.size
                break

        # print_layout(sorted(non_empty_blocks, key=lambda b: b.index))
    
    non_empty_blocks.sort(key=lambda b: b.index)
    
    checksum = 0
    for block in non_empty_blocks:
        for i in range(block.size):
            checksum += (block.index + i) * block.id

    print(checksum)


if __name__ == "__main__":
    part2()
