includes("test/code")

-- Option: Select which app to run in tests
option("app")
    set_description("Select which program to build and run, default to mini")
    set_default("mini")
    set_showmenu(true)

-- Common build process
function common_build()
    set_default(false)

    -- Verilator settings
    set_toolchains("verilator")
    add_rules("verilator.binary")
    add_values("verilator.flags", "-Isrc")
    add_values("verilator.flags", "--trace")

    -- C++ settings
    set_optimize("faster")
    add_includedirs("$(builddir)")
    add_cxxflags("-std=c++26")

    on_run(function (target)
        -- Create VCD output directory
        local output_dir = path.absolute(path.join(get_config("builddir"), "vcd"))
        os.mkdir(output_dir)

        -- Go to target directory and run
        os.cd(target:targetdir())
        os.execv(
            target:targetfile(),
            {output_dir, get_config("app")..".bin"} -- test_core ignores the second parameter
        )
    end)
end

-- CPU Core test, Default target
target("test_core")
    common_build()
    set_default(true)

    add_deps("mini")
    add_files("src/**.v")
    add_files("test/mock/*.cpp", "test/test_core.cpp")

-- Decoder test
target("test_decode")
    common_build()

    add_deps("$(app)")
    add_files("src/decode.v")
    add_files("test/test_decode.cpp")

-- Application test
target("test_app")
    common_build()

    add_deps("$(app)")
    add_files("src/**.v")
    add_files("test/mock/*.cpp", "test/run.cpp")