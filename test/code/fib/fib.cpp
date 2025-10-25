#include <cstdint>

std::uint32_t fib(std::uint32_t i)
{
    if (i == 0 || i == 1 || i == 2)
        return 1;

    return fib(i - 1) + fib(i - 2);
}

constexpr std::uint32_t io_addr = 0x60000000;
constexpr std::uint32_t fib_count = 5;

int main(void)
{
    const auto num = static_cast<std::uint8_t>(fib(fib_count));

    *reinterpret_cast<std::uint32_t *>(io_addr) = num;
}