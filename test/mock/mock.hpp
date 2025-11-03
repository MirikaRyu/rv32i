#ifndef MOCK_HPP_
#define MOCK_HPP_

#include <cstdint>
#include <vector>

/* Memory access width, see `constants.v` */
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

/* Set RAM state */
uint32_t ram_get_value(uint32_t addr);
void ram_set_value(uint32_t addr, uint8_t data);
void ram_set_value(uint32_t addr, uint16_t data);
void ram_set_value(uint32_t addr, uint32_t data);
void ram_set_default(uint8_t data = 0) noexcept;

/* Set ROM state */
uint32_t rom_get_value(uint32_t addr);
void rom_set_current(std::vector<uint8_t> &&rom_in);

/* Set IO state word*/
uint32_t io_get_state(void) noexcept;
void io_set_state(uint32_t new_state) noexcept;

#endif