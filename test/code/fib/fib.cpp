#include <cstdint>

uint32_t fib(uint32_t i)
{
    if (i == 0 || i == 1 || i == 2)
        return 1;

    return fib(i - 1) + fib(i - 2);
}

constexpr uint32_t io_addr = 0xc0000000;
constexpr uint32_t fib_count = 10;

int main(void)
{
    *reinterpret_cast<uint32_t *>(io_addr) = fib(fib_count);
}