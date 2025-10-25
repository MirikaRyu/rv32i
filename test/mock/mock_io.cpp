#include <cstdint>
#include <iostream>
#include <print>

static uint32_t io_state{};

void io_set_state(uint32_t new_state) noexcept
{
    if (new_state != io_state)
    {
        io_state = new_state;
        std::println("IO State changed externally: {:032b}", io_state);
    }
}

extern "C" int get_io_state(void) noexcept
{
    return static_cast<int>(io_state);
}

extern "C" void set_io_state(int mask, int value) noexcept
{
    const auto old_state = io_state;

    const auto io_state_keep = static_cast<uint32_t>(io_state & ~mask);
    const auto value_new = static_cast<uint32_t>(value & mask);
    io_state = io_state_keep | value_new;

    if (io_state != old_state)
        std::println("New IO State: {:032b}", io_state);
}