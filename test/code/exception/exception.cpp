#include <cstddef>
#include <cstdint>
#include <exception>
#include <limits>
#include <utility>

/* ABI Stuff ================================================================== */

/* Mock `struct object` from unwind-dw2-fde.h */
struct object
{
    uint8_t buffer[64];
};
static object eh_obj{};
static uint8_t buffer[256]{};

extern "C"
{
    /* From unwind-dw2-fde.c in libgcc */
    void __register_frame_info(const void *, object *);

    /* From libc */
    void *_sbrk(size_t sz) noexcept // The C++ abstract machine requires heap :(
    {
        extern uint8_t end;
        static uint8_t *brk = &end;

        return std::exchange(brk, brk + sz);
    }

    /* From libsupc++ */
    void *__cxa_allocate_exception(size_t) noexcept
    {
        // The `__cxa_init_primary_exception` builds the object before returned address, make it happy
        constexpr auto offset = 128uz;
        return buffer + offset;
    }

    void __cxa_free_exception(void *) noexcept
    {
    }
}

namespace __cxxabiv1
{
    std::terminate_handler __terminate_handler = +[]
    {
        while (true)
            asm volatile("nop");
    };
}

/* ============================================================================ */

/* Test exception handling ==================================================== */

void print_u32(uint32_t out) noexcept
{
    constexpr uint32_t io_addr = 0xc0000000;
    *reinterpret_cast<std::uint32_t *>(io_addr) = out;
}

struct exception_base
{
    [[nodiscard]] virtual uint32_t get(void) const noexcept
    {
        return std::numeric_limits<uint32_t>::max();
    }

    virtual ~exception_base() = default;
};

struct exception_derived : exception_base
{
    [[nodiscard]] uint32_t get(void) const noexcept override
    {
        return 0x114514;
    }
};

void foo(void)
{
    throw exception_derived{};
}

void baz(void)
{
    struct dummy
    {
        ~dummy() noexcept
        {
            print_u32(0x0721);
        }
    };
    dummy dummy; // It should be destructed before `bar` catch the exception

    foo();
}

void bar(void)
try
{
    baz();
}
catch (const exception_base &e)
{
    print_u32(e.get());
}

int main(void)
{
    /* Init .data and .bss */
    extern uint32_t lm_data_start, vm_data_start, vm_data_end, bss_start, bss_end;
    for (auto count = 0; count < &vm_data_end - &vm_data_start; ++count)
        (&vm_data_start)[count] = (&lm_data_start)[count];
    for (auto addr = &bss_start; addr != &bss_end; ++addr)
        *addr = 0;

    /* Register FDE info for exception handling */
    extern uint8_t eh_frame_start;
    __register_frame_info(&eh_frame_start, &eh_obj);

    bar();
}