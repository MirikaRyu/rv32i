#include <cstdint>
#include <stdexcept>
#include <utility>
#include <vector>

#include "mock.hpp"

static std::vector<uint8_t> rom{};

void rom_set_initial(std::vector<uint8_t> &&rom_in)
{
    if (rom_in.size() >= 4 && rom_in.size() % 4 == 0)
        rom = std::move(rom_in);
    else
        throw std::runtime_error{"Invalid size or alignment of input ROM"};
}

extern "C" int rom_access(short addr) noexcept
{
    const auto uaddr = static_cast<uint16_t>(addr);

    uint32_t ret{};
    if (4 <= rom.size() && uaddr <= rom.size() - 4)
        ret = (rom[uaddr + 3] << 24) + (rom[uaddr + 2] << 16) + (rom[uaddr + 1] << 8) + rom[uaddr];

    return static_cast<int>(ret);
}