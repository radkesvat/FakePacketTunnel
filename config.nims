import std/[strformat, macros, strutils, ospaths]

const Release = true


const libs_dir = "libs"
const output_dir = "dist"
const src_dir = "src"
const nimble_path = libs_dir&"/nimble"

const backend = "c"


const compiler = "gcc" #gcc, switch_gcc, llvm_gcc, clang, bcc, vcc, tcc, env, icl, icc, clang_cl

template outFile(name: string):string =  output_dir / name & (when defined(windows): ".exe" else: "")


template require(package: untyped) =
    block:
        when compiles(typeof(package)):
            let str {.inject.}:string = package
            exec &"nimble -l install --nimbleDir:{nimble_path} {str} -y"
        else:
            let ast {.inject.} = astToStr(package)
            exec &"nimble -l install --nimbleDir:{nimble_path} {ast} -y"

template sharedBuildSwitches()=
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

    switch("nimcache", "build"/hostOS/hostCPU)
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
        
    switch("outdir", output_dir)
    switch("out", output_file)
    switch("backend", backend)


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
            exec """make"""
            cpFile("libpcap.a",".."/"libpcap.a")

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
            exec "make"
            cpFile("libpcap.a",".."/"libpcap.a")
            
            ### cmake way
            # exec "mkdir bulid"
            # withDir "bulid":
            #     exec """cmake "-DPacket_ROOT=${projectDir}\..\npcap-sdk" -G "Unix Makefiles" -D CMAKE_C_COMPILER=gcc -D CMAKE_CXX_COMPILER=g++ .."""
            # exec "make"
    

task build_libnet, "builds libnet(1.2) x64 static":
    when defined(windows):
        echo "[Notice] all the painful build steps are already done, you only need make and a gcc"
        
        # pacman -Syu --noconfirm
        # pacman -S --noconfirm git wget tar gzip autoconf automake make libtool patch unzip xz bison flex pkg-config
        # pacman -S --noconfirm mingw-w64-x86_64-gcc
        # CFLAGS="-I../win32/wpdpack/Include/" LDFLAGS="-L$(pwd)/win32/wpdpack/Lib/x64/" ./configure --prefix=/mingw64 --disable-shared

        exec "gcc --version" 
        exec "make --version"
        
        withDir "libs/libnet/":
            exec """make clean"""
            exec """make"""
            cpFile("src"/".libs"/"libnet.a",".."/"libnet.a")
    else:
        echo "[Notice] you need full gcc toolchain to be installed such as: "
        echo "gcc git wget tar gzip autoconf automake make libtool patch unzip xz bison flex pkg-config"

        exec "gcc --version" 
        exec "make --version"
        exec "automake --version"
        exec "libtool --version"
        withDir "libs/libnet/":
            exec "./configure --disable-shared"
            exec "make"


task install, "install nim deps":
    require zippy
    require checksums
    require stew
    require bearssl
    require httputils
    require unittest2
    require &"""--passL:-L"{getCurrentDir() / libs_dir }/" futhark"""
    #lib pcap
    # exec """cmd /c "echo | set /p dummyName=Hello World" && exit"""
    # exec """cmd /c "echo | set /p dummyName=Hello World" && exit"""
    # if "y" == readLineFromStdin():
    #     echo "yes"





task test, "run tests":
    const output_file = outFile("test")
    setCommand("c", src_dir / "test" / "test.nim")
    sharedBuildSwitches()
    switch("r", "")

task build_fpt, "builds fpt":
    const output_file = outFile("RTT")
    setCommand("c", src_dir&"/main.nim")

    sharedBuildSwitches()




task build, "builds all":

    # echo staticExec "pkill RTT"
    # echo staticExec "taskkill /IM RTT.exe /F"

    exec "nim build_fpt"
    # withDir(output_dir):
        # exec "chmod +x RTT"
        # echo staticExec "./RTT >> output.log 2>&1"

