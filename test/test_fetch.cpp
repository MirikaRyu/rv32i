#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <print>
#include <ranges>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include <verilated.h>
#include <verilated_vcd_c.h>

#include "mock/mock.hpp"

#include "test_fetch.h"

// Generated VCD file
constexpr std::string_view wave_file = "fetcher_timing.vcd";

// Max iterations
constexpr size_t max_iter = 0xffffffff;

bool should_flush(uint32_t instr)
{
    // Flush if `instr` is a branch or jump instruction
    constexpr uint8_t b_j_opcode[] = {
        0b01100011, // BRANCH
        0b01101111, // JAL
        0b01100111, // JALR
    };

    return std::ranges::contains(b_j_opcode, instr & 0x7f); // Low 7 bits
}

bool should_stall(size_t clk)
{
    // If clk/10 matches any in `stall_cycles`, then a stall signal emits
    constexpr std::array stall_cycles = {3, 5, 8, 9, 11, 20};

    return std::ranges::contains(stall_cycles, clk / 10);
}

int main(int argc, char *argv[])
{
    if (argc < 3)
    {
        std::println(std::cerr, "Usage: {} <output_dir> <binary_filename>", argv[0]);
        std::exit(1);
    }
    else if (std::ifstream code{argv[2], std::ios::in | std::ios::binary})
    {
        std::vector<uint8_t> code_data{std::istreambuf_iterator<char>{code}, std::istreambuf_iterator<char>{}};
        rom_set_current(std::move(code_data));
    }
    else
    {
        std::println(std::cerr, "Error opening file: {}", argv[1]);
        std::exit(1);
    }

    auto pcontext = std::make_unique<VerilatedContext>();
    pcontext->commandArgs(argc, argv);

    Verilated::traceEverOn(true);
    auto pwaveCreater = std::make_unique<VerilatedVcdC>();

    auto pfetcher = std::make_unique<test_fetch>();
    pfetcher->trace(pwaveCreater.get(), 99);

    pwaveCreater->open((std::filesystem::path{argv[1]} / wave_file).c_str());

    for (const auto i : std::views::iota(0u, max_iter))
    {
        pfetcher->clk = i % 2;

        const auto instr = pfetcher->instr_Out;
        pfetcher->pcFlush_In = should_flush(instr);
        pfetcher->pcWrite_In =
            pfetcher->pc_Out + (should_flush(instr) ? 8 : 4); // Simply skip the next instruction if flush is needed

        pfetcher->execLockRead_In =
            pfetcher->execLockSet_Out || should_stall(i); // Stall randomly to simulate memory access

        pfetcher->eval();
        pcontext->timeInc(1);
        pwaveCreater->dump(pcontext->time());

        if (instr == 0 && i > 20) // Already fetch all instructions
            break;
    }

    pwaveCreater->close();
    std::println("Simulation complete, validate '{}'", wave_file);
}