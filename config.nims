import std/[strformat, macros, strutils, ospaths]


const output_name = "FPT"

const libs_dir = "libs"
const output_dir = "dist"
const src_dir = "src"
const tests_dir = "tests" #sources located inside src
const build_cache = hostOS/hostCPU
const nimble_path = libs_dir&"/nimble"

const backend = "c"
const compiler = "gcc" #gcc, switch_gcc, llvm_gcc, clang, bcc, vcc, tcc, env, icl, icc, clang_cl

template outFile(dir, name: string): string = dir / name & (when defined(windows): ".exe" else: "")

template require(package: untyped) =
    block:
        when compiles(typeof(package)):
            let str {.inject.}: string = package
            exec &"nimble -l install --nimbleDir:{nimble_path} {str} -y"
        else:
            let ast {.inject.} = astToStr(package)
            exec &"nimble -l install --nimbleDir:{nimble_path} {ast} -y"

task build_libpcap, "bulid libpcap x64 static":
    when defined(windows):
        echo "[Notice] this requires: Visual Studio 2015 or later,GNU Make+gcc , Chocolatey , CMake, Winflexbison, Git."
        echo "I have already downloaded and set these things up in /libs folder but some tools are executeables and"
        echo "are required to be installed on your system before the build happens. more info at: "
        echo "(https://github.com/the-tcpdump-group/libpcap/blob/libpcap-1.10.4/doc/README.Win32.md)"

        exec "gcc --version"
        exec "cmake --version"
        exec "make --version"

        withDir "libs/libpcap/":
            exec """cmake "-DPacket_ROOT=..\npcap-sdk" -G "MinGW Makefiles" -D CMAKE_C_COMPILER=gcc -D CMAKE_CXX_COMPILER=g++ ."""
            exec """make clean"""
            exec """make"""
            cpFile("libpcap.a", ".."/"libpcap.a")

            # exec """msbuild pcap.sln /m /property:Configuration=Release"""

    else:
        echo "[Notice] this requires: build tools (gcc+make),autoconf, CMake, Git."
        echo "I have already downloaded and set these things up in /libs folder but some tools are executeables and"
        echo "are required to be installed on your system before the build happens. more info at: "
        echo "https://github.com/the-tcpdump-group/libpcap/blob/master/INSTALL.md"

        #check for tools that must be installed
        exec "cmake --version"
        exec "autoconf --version"
        exec "flex --version"
        exec "bison --version"
        exec "gcc --version"
        exec "make --version"

        withDir "libs/libpcap/":
            ### autogen way
            exec "./autogen.sh"
            exec "./configure"
            exec """make clean"""
            exec "make"
            cpFile("libpcap.a", ".."/"libpcap.a")

            ### cmake way
            # exec "mkdir bulid"
            # withDir "bulid":
            #     exec """cmake "-DPacket_ROOT=${projectDir}\..\npcap-sdk" -G "Unix Makefiles" -D CMAKE_C_COMPILER=gcc -D CMAKE_CXX_COMPILER=g++ .."""
            # exec "make"

task build_libnet, "builds libnet(1.2) x64 static":
    when defined(windows):
        echo "[Notice] you need to do extra steps to be able to build, you have to generate and run configure script before make"
        # Mysis Mingw64
        # pacman -Syu --noconfirm
        # pacman -S --noconfirm git wget tar gzip autoconf automake make libtool patch unzip xz bison flex pkg-config
        # pacman -S --noconfirm mingw-w64-x86_64-gcc
        # ./autogen.sh
        # CFLAGS="-I../win32/wpdpack/Include/" LDFLAGS="-L../win32/wpdpack/Lib/x64/ -Lwin32/wpdpack/Lib/x64/" ./configure --prefix=/mingw64 --disable-shared
        exec "gcc --version"
        exec "make --version"

        withDir "libs/libnet/":
            if not fileExists("Makefile"):
                echo "[Error] you did not generate the MakeFile, read the docs for a how-to guide."
                echo "unfortunately these steps required software installation and i couldnt script them."

            exec """make clean"""
            exec """make"""
            cpFile("src"/".libs"/"libnet.a", ".."/"libnet.a")
    else:
        echo "[Notice] you need full gcc toolchain to be installed such as: "
        echo "gcc git wget tar gzip autoconf automake make libtool patch unzip xz bison flex pkg-config"

        exec "gcc --version"
        exec "make --version"
        exec "automake --version"
        exec "libtool --version"
        withDir "libs/libnet/":
            exec "./autogen.sh"
            exec "./configure --disable-shared"
            exec """make clean"""
            exec "make"

task install, "install nim deps":
    require zippy
    require checksums
    require stew
    require results
    require bearssl
    require httputils
    require unittest2
    require &"""--passL:-L"{getCurrentDir() / libs_dir }/" futhark"""

    # exec """cmd /c "echo | set /p dummyName=Hello World" && exit"""
    # exec """cmd /c "echo | set /p dummyName=Hello World" && exit"""
    echo "Attempt to download submodules"
    exec "git submodule update --recursive"
    echo "Finished prepairing required tools. \n"

    echo "[Notice] In order build this project , you have to build libnet and libpcap"
    echo "run: nim build_libpcap"
    echo "then: nim build_libnet"
    echo "then: nim build\n"

template sharedBuildSwitches(){.dirty.} =
    switch("nimblePath", nimble_path&"/pkgs2")
    # switch("mm", "orc") not for chronos
    switch("mm", "refc")
    switch("cc", compiler)
    switch("threads", "off")
    # switch("exceptions", "setjmp")
    switch("warning", "HoleEnumConv:off")
    switch("warning", "BareExcept:off")
    # switch("d", "useMalloc")
    switch("d", "asyncBackend:chronos")

    switch("path", src_dir)
    switch("path", libs_dir)
    switch("path", libs_dir&"/chronos/")
    switch("passC", "-I "&libs_dir&"/hwinfo/include/")

    switch("nimcache", "build"/build_cache)
    # switch("define", "ssl")
    # switch("passC", "-I "&libs_dir&"/hwinfo/include/")


 
    when Release:
        switch("opt", "speed")
        switch("debugger", "off")
        switch("d", "release")

        switch("passL", " -s")
        switch("debuginfo", "off")
        switch("passC", "-DNDEBUG")
        switch("passC", "-flto")
        switch("passL", "-flto")

        switch("obj_checks", "off")
        switch("field_checks", "off")
        switch("range_checks", "off")
        switch("bound_checks", "off")
        switch("overflow_checks", "off")
        switch("floatChecks", "off")
        switch("nanChecks", "off")
        switch("infChecks", "off")
        # switch("assertions","off")
        switch("stacktrace", "off")
        switch("linetrace", "off")
        switch("debugger", "off")
        switch("line_dir", "off")
        # switch("passL", " -static")
        # switch("passL", " -static-libgcc")
        # switch("passL", " -static-libstdc++")
    else:
        switch("d", "debug")

    switch("outdir", output_dir)
    switch("out", output_file)
    switch("backend", backend)

task test, "test a single file":
    const Release = false 

    if paramCount() < 2:
        echo "pass the test file as a parameter like: nim test test.nim"; return

    let file = paramStr(2)
    if not fileExists(src_dir / tests_dir / file):
        echo &"file {src_dir / tests_dir / file} dose not exists"; return

    let build_cache = "Tests" / file[0 .. file.rfind('.')] / build_cache
    const output_dir = output_dir / tests_dir
    let output_file = outFile(output_dir, file)

    setCommand("c", src_dir / tests_dir / file)
    sharedBuildSwitches()
    switch("r", "")
    switch("threads", "on")
    switch("d", "nimUnittestColor=on")

task tests, "run all tests":
    for f in listFiles(src_dir / tests_dir):
        if not (f.len > 4 and f[^4..^1] == ".nim"): continue
        let fn = f[f.rfind(DirSep)+1 .. f.high]
        echo "Compile and Test => " & fn[0 .. fn.rfind(".")-1]
        try:
            exec "nim test " & fn
        except :
            echo "Test failed, continue other tests? [Enter]"
            discard readLineFromStdin()

task build_fpt_release, "builds fpt release":
    const Release = true
    let build_cache = "Release" / build_cache
    const output_dir = output_dir / "release"
    const output_file = outFile(output_dir, output_name)
    setCommand("c", src_dir&"/main.nim")
    sharedBuildSwitches()

task build_fpt_debug, "builds fpt debug":
    const Release = false 
    let build_cache = "Debug" / build_cache
    const output_dir = output_dir / "debug"
    const output_file = outFile(output_dir, output_name)
    setCommand("c", src_dir&"/main.nim")
    sharedBuildSwitches()


#only a shortcut
task build, "builds only fpt (debug)":
    # echo staticExec "pkill FPT"
    # echo staticExec "taskkill /IM FPT.exe /F"
    exec "nim build_fpt_debug"
    # withDir(output_dir):`
        # exec "chmod +x FPT"
        # echo staticExec "./FPT >> output.log 2>&1"

