#! /usr/bin/env python

import binascii
import argparse

if __name__ == "__main__":
    # Parse Args
    parser = argparse.ArgumentParser(
        description="A script converting binary file into multiline hex text file"
    )
    parser.add_argument(
        "-w",
        "--width",
        type=int,
        default="4",
        help="How many bytes per line",
    )
    parser.add_argument(
        "-i",
        "--input",
        type=str,
        required=True,
        help="Input file",
    )
    result = parser.parse_args()

    # Convert
    with open(result.input.strip(), "rb") as bin:
        bin_data = bin.read()

    hex_data = binascii.hexlify(bin_data)
    text = hex_data.decode()

    width = result.width * 2
    for i in range(0, len(text), width):
        print(text[i : i + width])
