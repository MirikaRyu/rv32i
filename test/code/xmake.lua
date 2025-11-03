-- Toolchain define
toolchain("rv32i-gcc")
    set_kind("standalone")

    set_toolset("cc", "riscv32-unknown-elf-gcc")
    set_toolset("cxx", "riscv32-unknown-elf-g++")
    set_toolset("as", "riscv32-unknown-elf-gcc")
    set_toolset("ld", "riscv32-unknown-elf-g++")
    set_toolset("ar", "riscv32-unknown-elf-ar")
    set_toolset("strip", "riscv32-unknown-elf-strip")
    set_toolset("nm", "riscv32-unknown-elf-nm")
    set_toolset("objcopy", "")

    on_check(function (toolchain)
        return import("lib.detect.find_tool")("riscv32-unknown-elf-gcc")
    end)
toolchain_end()
set_toolchains("rv32i-gcc")

-- Common compiler flags
set_languages("clatest", "cxxlatest")
set_warnings("allextra", "pedantic", "error")
set_symbols("debug")

-- Environment related
add_cxflags(
    "-march=rv32i", "-mabi=ilp32",
    "--specs=nosys.specs", "--specs=nano.specs",
    "-nostartfiles", "-ffreestanding",
    "-ffunction-sections", "-fdata-sections",
    {force = true}
)
add_cxxflags(
    "-fno-rtti", "-fno-threadsafe-statics",
    {force = true}
)
add_ldflags(
    "-T".."$(projectdir)/test/code/link.ld",
    "-Wl,--print-memory-usage,--gc-sections,--no-warn-rwx-segments",
    {force = true}
)

-- Common build process
set_default(false)
set_kind("binary")
add_files("entry.S")

after_build(function (target)
    -- Generate binary file
    local bin_file = path.join(target:targetdir(), path.basename(target:targetfile()) .. ".bin")
    os.vrunv("riscv32-unknown-elf-objcopy", {"-O", "binary", target:targetfile(), bin_file})

    -- Generate hex text file for IP ROM
    local hex_file = path.join(target:targetdir(), path.basename(target:targetfile()) .. ".dat")
    local converter = path.join("tools", "convert.py")
    os.vrunv("python", {converter, "-i", bin_file}, {stdout = hex_file})
end)

-- Bytecode targets
target("mini")
    add_files("mini/mini.S")

target("io")
    add_files("io/io.S")

target("fib")
    add_files("fib/fib.cpp")

target("float")
    add_files("float/float.cpp")

target("exception")
    add_files("exception/exception.cpp")