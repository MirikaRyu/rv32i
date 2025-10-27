#include <cstddef>
#include <cstdint>
#include <format>
#include <ranges>
#include <stdexcept>
#include <unordered_map>
#include <vector>

#include "mock.hpp"

class ram_t
{
private:
    std::unordered_map<uint32_t, std::vector<uint8_t>> memory_;
    uint8_t init_value_;

    static constexpr auto PAGE_SIZE = 4uz * (1 << 10);

public:
    explicit ram_t(uint8_t init_val = 0) noexcept
        : memory_{}, init_value_{init_val}
    {
    }

public:
    void write(uint32_t addr, access_width width, uint32_t data)
    {
        if (width == NONE || width > BYTE)
            throw std::runtime_error{std::format("Invalid RAM access width: {}", static_cast<uint8_t>(width))};

        for (const auto offset : std::views::iota(0u, width_to_byte(width)))
        {
            const size_t page_num = addr / PAGE_SIZE;

            if (!memory_.contains(page_num))
                memory_.emplace(page_num, std::vector<uint8_t>(PAGE_SIZE, init_value_));
            memory_[page_num][addr % PAGE_SIZE] = static_cast<uint8_t>(data >> 8 * offset);

            ++addr;
        }
    }

    uint32_t read(uint32_t addr, access_width width) const
    {
        if (width == NONE || width > BYTE)
            throw std::runtime_error{std::format("Invalid RAM access width: {}", static_cast<uint8_t>(width))};

        uint32_t ret{};
        for (const auto offset : std::views::iota(0u, width_to_byte(width)))
        {
            const size_t page_num = addr / PAGE_SIZE;

            if (memory_.contains(page_num))
                ret |= memory_.at(page_num)[addr % PAGE_SIZE] << 8 * offset;
            else
                ret |= init_value_ << 8 * offset;

            ++addr;
        }

        return ret;
    }

    void set_init_value(uint8_t val) noexcept
    {
        init_value_ = val;
    }
};

static ram_t ram{};

extern "C" int ram_read(int addr, uint8_t width)
{
    return static_cast<int>(ram.read(static_cast<uint32_t>(addr), static_cast<access_width>(width)));
}

extern "C" void ram_write(int addr, uint8_t width, int data)
{
    ram.write(static_cast<uint32_t>(addr), static_cast<access_width>(width), static_cast<uint32_t>(data));
}

uint32_t ram_get_value(uint32_t addr)
{
    return ram.read(addr, WORD);
}

void ram_set_value(uint32_t addr, uint8_t data)
{
    ram.write(addr, BYTE, data);
}

void ram_set_value(uint32_t addr, uint16_t data)
{
    ram.write(addr, HALF, data);
}

void ram_set_value(uint32_t addr, uint32_t data)
{
    ram.write(addr, WORD, data);
}

void ram_set_default(uint8_t data) noexcept
{
    ram.set_init_value(data);
}