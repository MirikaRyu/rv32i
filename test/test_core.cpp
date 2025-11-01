#include <array>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <iterator>
#include <memory>
#include <print>
#include <ranges>
#include <string>
#include <string_view>
#include <vector>

#include <verilated.h>
#include <verilated_vcd_c.h>

#include "mock/mock.hpp"

#include "test_core.h"
#include "test_core___024root.h"

// Generated VCD file
constexpr std::string_view wave_file = "core_timing.vcd";

// Minimal test binary file
constexpr std::string_view mini_test = "mini.bin";

// Max iterations
constexpr size_t max_iter = 0xffff;

int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        std::println(std::cerr, "Usage: {} <output_dir>", argv[0]);
        std::exit(1);
    }
    else if (std::ifstream code{mini_test.data(), std::ios::in | std::ios::binary})
    {
        std::vector<uint8_t> code_data{std::istreambuf_iterator<char>{code}, std::istreambuf_iterator<char>{}};
        rom_set_current(std::move(code_data));
    }
    else
    {
        std::println(std::cerr, "Error opening minimal test binary file: {}", mini_test);
        std::exit(1);
    }

    auto pcontext = std::make_unique<VerilatedContext>();
    pcontext->commandArgs(argc, argv);

    Verilated::traceEverOn(true);
    auto pwaveCreater = std::make_unique<VerilatedVcdC>();

    auto pcore = std::make_unique<test_core>();
    pcore->trace(pwaveCreater.get(), 99);

    pwaveCreater->open((std::filesystem::path{argv[1]} / wave_file).c_str());

    pcore->clk = 1;
    pcore->rst = 1;
    pcore->eval();
    pcore->clk = 0;
    pcore->rst = 0;
    pcore->eval();

    bool success{};
    for (const auto i : std::views::iota(0u, max_iter))
    {
        pcore->clk = i % 2;

        pcore->eval();
        pcontext->timeInc(1);
        pwaveCreater->dump(pcontext->time());

        if (pcore->rootp->Core__DOT__instr_fetch__DOT__ir == 0x100073) // EBREAK: End of minimal test
        {
            success =
                (pcore->rootp->Core__DOT__reg_file__DOT__reg_x30 == 0xF00DCAFE); // Test success, defined in `mini.S`
            break;
        }
    }

    pwaveCreater->close();
    std::println(success ? std::cout : std::cerr,
                 "Minimal test {}, check '{}' for more infomation",
                 success ? "PASSED" : "**FAILED**",
                 wave_file);
    std::exit(success ? 0 : 1);
}