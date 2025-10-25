#ifndef MOCK_HPP_
#define MOCK_HPP_

#include <cstdint>
#include <vector>

// Pass a ROM contains instructions, its size must larger than and aligned to 4 bytes
void rom_set_initial(std::vector<uint8_t> &&rom_in);

// Set the state word of IO
void io_set_state(uint32_t new_state) noexcept;

// Set the state of RAM
void ram_set_initial(uint8_t data = 0) noexcept;
void ram_set_value(uint32_t addr, uint8_t data);
void ram_set_value(uint32_t addr, uint16_t data);
void ram_set_value(uint32_t addr, uint32_t data);

#endif