#include <cstdint>
#include <iostream>
#include <print>

#include "mock.hpp"

static uint32_t io_state{};

extern "C" int io_read(int addr, uint8_t width) noexcept
{
    return static_cast<int>((io_state >> 8u * (addr & 0b11)) &
                            (0xffffffffu >> 8u * (4 - width_to_byte(static_cast<access_width>(width)))));
}

extern "C" void io_write(int addr, uint8_t width, int data) noexcept
{
    const auto old_state = io_state;

    const auto mask = static_cast<uint32_t>((0xffffffffu >> 8u * (4 - width_to_byte(static_cast<access_width>(width))))
                                            << 8u * (addr & 0b11));
    const auto io_state_keep = static_cast<uint32_t>(io_state & ~mask);
    const auto value_new = static_cast<uint32_t>(data & mask);
    io_state = io_state_keep | value_new;

    if (io_state != old_state)
        std::println("New IO State: {:032b}", io_state);
}

uint32_t io_get_state(void) noexcept
{
    return io_state;
}

void io_set_state(uint32_t new_state) noexcept
{
    if (new_state != io_state)
    {
        io_state = new_state;
        std::println("IO State changed externally: {:032b}", io_state);
    }
}