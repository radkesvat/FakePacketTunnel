import std/[strformat, macros, strutils, ospaths]

const Release = true


const libs_dir = "libs"
const output_dir = "dist"
const src_dir = "src"
const nimble_path = libs_dir&"/nimble"

const backend = "c"

template require(package: untyped) =
    block:
        when compiles(typeof(package)):
            let str {.inject.}:string = package
            exec &"nimble -l install --nimbleDir:{nimble_path} {str} -y"
        else:
            let ast {.inject.} = astToStr(package)
            exec &"nimble -l install --nimbleDir:{nimble_path} {ast} -y"


task build_libpcap, "bulid libpcap":
    echo "[Notice] this requires: Visual Studio 2015 or later , Chocolatey , CMake, Winflexbison, Git."
    echo "I have already downloaded and set these things up in /libs folder but some tools are executeables and"
    echo "are required to be installed on your system before the build happens. more info at: "
    echo "(https://github.com/the-tcpdump-group/libpcap/blob/libpcap-1.10.4/doc/README.Win32.md)"
    # cmake "-DPacket_ROOT={path-to-sdk}" {path-to-libpcap-source}
    # echo staticExec "pkill RTT"
    exec "cmake --version"
    withDir "libs/libpcap/":
        exec """cmake "-DPacket_ROOT=${projectDir}\..\npcap-sdk" ."""
        exec """msbuild pcap.sln /m """




        

template outFile(name: string):string =  output_dir / name & (when defined(windows): ".exe" else: "")

template sharedBuildSwitches()=
    switch("nimblePath", nimble_path&"/pkgs2")
 # switch("mm", "orc") not for chronos
    switch("mm", "refc")
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

task build_server, "builds server":
    const output_file = outFile("RTT")
    setCommand("c", src_dir&"/main.nim")

    sharedBuildSwitches()




task build, "builds all":

    # echo staticExec "pkill RTT"
    # echo staticExec "taskkill /IM RTT.exe /F"

    exec "nim build_server"
    # withDir(output_dir):
        # exec "chmod +x RTT"
        # echo staticExec "./RTT >> output.log 2>&1"

