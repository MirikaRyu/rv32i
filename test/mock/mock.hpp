#ifndef MOCK_HPP_
#define MOCK_HPP_

#include <cstdint>
#include <vector>

enum access_width
{
    NONE,
    WORD,
    HALF,
    BYTE,
};

inline uint8_t width_to_byte(access_width width) noexcept
{
    return (width == WORD) ? 4 : (4 - static_cast<uint8_t>(width));
}

// Set the state of RAM
uint32_t ram_get_value(uint32_t addr);
void ram_set_value(uint32_t addr, uint8_t data);
void ram_set_value(uint32_t addr, uint16_t data);
void ram_set_value(uint32_t addr, uint32_t data);
void ram_set_default(uint8_t data = 0) noexcept;

// Pass a ROM to mock, its size must larger than 4 bytes
uint32_t rom_get_value(uint32_t addr);
void rom_set_current(std::vector<uint8_t> &&rom_in);

// Set the state word of IO
uint32_t io_get_state(void) noexcept;
void io_set_state(uint32_t new_state) noexcept;

#endif