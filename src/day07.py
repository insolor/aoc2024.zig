from collections.abc import Iterable
import itertools
from pathlib import Path

current_dir = Path(__file__).parent


data = []
with open(current_dir / "inputs" / "07.txt") as file:
    for line in file:
        line = line.strip()
        result, _, tail = line.partition(":")
        result = int(result)
        arguments = list(map(int, tail.split()))
        data.append((result, arguments))


def get_magnitude(value: int) -> int:
    result = 1
    while result <= value:
        result *= 10
    return result


def apply_operators(arguments: list[int], operators: Iterable[str]) -> int:
    result = arguments[0]

    for operator, argument in zip(operators, arguments[1:]):
        if operator == "+":
            result += argument
        elif operator == "*":
            result *= argument
        elif operator == "|":
            r1 = result * get_magnitude(argument) + argument
            r2 = int(str(result) + str(argument))
            assert r1 == r2, (result, argument, r1, r2)
            result = result * get_magnitude(argument) + argument

    return result


def solvable(row: tuple[int, list[int]], possible_operators: str) -> bool:
    op_iterator = itertools.product(possible_operators, repeat=len(row[1]) - 1)

    for operators in op_iterator:
        if apply_operators(row[1], operators) == row[0]:
            return True

    return False


def part1(data) -> None:
    total = 0
    for row in data:
        if solvable(row, "+*"):
            total += row[0]
    print("Part 1:", total)


def part2(data) -> None:
    total = 0
    for row in data:
        if solvable(row, "+*|"):
            total += row[0]
    print("Part 2:", total)


if __name__ == "__main__":
    part1(data)
    part2(data)
