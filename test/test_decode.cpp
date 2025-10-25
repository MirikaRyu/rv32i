#include <array>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <print>
#include <ranges>
#include <string>
#include <string_view>
#include <vector>

#include <verilated.h>
#include <verilated_vcd_c.h>

#include "test_decode.h"

// Generated VCD file
constexpr std::string_view wave_file = "decoder_timing.vcd";

// Mocking register file
constexpr std::array<uint32_t, 32> regs = {
    0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15,
    16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
};

int main(int argc, char *argv[])
{
    if (argc < 3)
    {
        std::println(std::cerr, "Usage: {} <output_dir> <binary_filename>", argv[0]);
        std::exit(1);
    }

    std::vector<uint8_t> instruction{};
    if (std::ifstream code{argv[2], std::ios::in | std::ios::binary})
    {
        instruction = std::vector<uint8_t>{std::istreambuf_iterator<char>{code}, std::istreambuf_iterator<char>{}};
        if (instruction.size() % 4 != 0 || instruction.size() < 4)
        {
            std::println(std::cerr, "Loaded instruction size is too small or misaligned");
            std::exit(1);
        }
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

    auto pdecoder = std::make_unique<test_decode>();
    pdecoder->trace(pwaveCreater.get(), 99);

    pwaveCreater->open((std::filesystem::path{argv[1]} / wave_file).c_str());

    for (const auto &instr : instruction | std::views::chunk(4))
    {
        pdecoder->instr_In = (instr[3] << 24) + (instr[2] << 16) + (instr[1] << 8) + instr[0];
        pdecoder->eval(); // Make sure rs1/rs2 address is generated from the instruction

        pdecoder->rs1_In = pdecoder->rs1Enable_Out ? regs[pdecoder->rs1Addr_Out] : 0;
        pdecoder->rs2_In = pdecoder->rs2Enable_Out ? regs[pdecoder->rs2Addr_Out] : 0;

        pdecoder->eval();
        pcontext->timeInc(1);
        pwaveCreater->dump(pcontext->time());
    }

    pwaveCreater->close();
    std::println("Simulation complete, validate '{}'", wave_file);
}