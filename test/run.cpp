#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <filesystem>
#include <format>
#include <fstream>
#include <iostream>
#include <memory>
#include <print>
#include <ranges>
#include <string_view>
#include <utility>
#include <vector>

#include <verilated.h>
#include <verilated_vcd_c.h>

#include "mock/mock.hpp"

#include "test_app.h"
#include "test_app___024root.h"

// Max iterations
constexpr size_t max_iter = 0xfffff;

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
        std::println(std::cerr, "Error opening file: {}", argv[2]);
        std::exit(1);
    }

    auto pcontext = std::make_unique<VerilatedContext>();
    pcontext->commandArgs(argc, argv);

    Verilated::traceEverOn(true);
    auto pwaveCreater = std::make_unique<VerilatedVcdC>();

    auto pcpu = std::make_unique<test_app>();
    pcpu->trace(pwaveCreater.get(), 99);

    const auto wave_file = std::format("timing_{}.vcd", std::filesystem::path{argv[2]}.stem().string());
    pwaveCreater->open((std::filesystem::path{argv[1]} / wave_file).c_str());

    pcpu->clk = 1;
    pcpu->rst = 1;
    pcpu->eval();
    pcpu->clk = 0;
    pcpu->rst = 0;
    pcpu->eval();

    for (const auto i : std::views::iota(0u, max_iter))
    {
        pcpu->clk = i % 2;

        pcpu->eval();
        pcontext->timeInc(1);
        pwaveCreater->dump(pcontext->time());

        if (pcpu->rootp->Core__DOT__instr_fetch__DOT__ir == 0x100073) // EBREAK
            break;
    }

    pwaveCreater->close();
    std::println("Simulation complete, check '{}' for more infomation", wave_file);
}