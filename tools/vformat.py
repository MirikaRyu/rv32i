#! /usr/bin/env python

import argparse
import subprocess

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="A script forwarding the format request to clang-format"
    )
    parser.add_argument(
        "-p",
        "--parser",
        type=str,
        default="clang-format",
        help="Path to the clang-format executable",
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-f", "--file", type=str, help="Input file")
    group.add_argument("-i", "--input", type=str, help="Input file")

    result = parser.parse_args()

    subprocess.Popen(
        [
            result.parser.strip(),
            "--style=Microsoft",
            "-i",
            result.file if result.file else result.input,
        ]
    )
