#include <cstdint>
#include <format>
#include <stdexcept>
#include <utility>
#include <vector>

#include "mock.hpp"

static std::vector<uint8_t> rom{};

extern "C" int rom_read(short addr, uint8_t width)
{
    const auto uaddr = static_cast<uint16_t>(addr);
    const auto mem_width = static_cast<access_width>(width);
    if (mem_width == NONE || mem_width > BYTE)
        throw std::runtime_error{std::format("Invalid ROM access width: {}", width)};

    uint32_t ret{};
    if (4 <= rom.size() && uaddr <= rom.size() - width_to_byte(mem_width))
        ret = (rom[uaddr + 3] << 24) + (rom[uaddr + 2] << 16) + (rom[uaddr + 1] << 8) + rom[uaddr];

    return static_cast<int>(ret & (0xffffffffu >> 8u * (4 - width_to_byte(mem_width))));
}

uint32_t rom_get_value(uint32_t addr)
{
    return static_cast<uint32_t>(rom_read(static_cast<short>(addr), static_cast<uint8_t>(WORD)));
}

void rom_set_current(std::vector<uint8_t> &&rom_in)
{
    if (rom_in.size() >= 4)
        rom = std::move(rom_in);
    else
        throw std::runtime_error{"Invalid size of input ROM"};
}