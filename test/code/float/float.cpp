#include <bit>
#include <cstdint>

float fast_rsqrt(float x) noexcept
{
    auto i = std::bit_cast<uint32_t>(x);
    i = 0x5f3759dfu - (i >> 1);
    auto y = std::bit_cast<float>(i);

    constexpr auto threehalfs = 1.5f;
    y = y * (threehalfs - 0.5f * x * y * y);
    y = y * (threehalfs - 0.5f * x * y * y);

    return y;
}

int main(void)
{
    const auto result = fast_rsqrt(114514.0721f);

    constexpr uint32_t io_addr = 0xc0000000;
    *reinterpret_cast<uint32_t *>(io_addr) = static_cast<uint32_t>(result * 1e12f);
}