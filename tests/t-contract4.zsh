#!/usr/bin/env zunit
#{{{                    MARK:Header
##### Purpose: zsh-xcode-completions — fourth-tier contracts.
#####          Pins for dynamic-discovery helpers in _xcodebuild and
#####          _xcrun: every -arch/-sdk/-scheme/-toolchain candidate
#####          source defers to live `xcodebuild`/`xcrun` invocations
#####          (so xcode-select switches propagate without restart),
#####          stderr is swallowed on probe calls, and _xcrun toolchain
#####          discovery enumerates ALL installed Xcode.app instances.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    xbFile="$pluginDir/src/_xcodebuild"
    xrFile="$pluginDir/src/_xcrun"
}

@test '_xcodebuild dynamic-discovery helpers all swallow stderr' {
    # Pin: _archs, _configurations, _schemes, _targets each shell out to
    # xcodebuild. When xcode-select points at an inactive path or no
    # project is in CWD, those calls error on stderr. The `2>/dev/null`
    # keeps the user's prompt clean on every tab. Pin the count.
    local count
    count=$(grep -cE 'xcodebuild [^|]*2>/dev/null' "$xbFile")
    # _archs + _configurations + _schemes + _targets => 4 swallow sites
    [[ "$count" -ge 4 ]]
    assert $? equals 0
}

@test '_xcrun executable discovery via dirname xcrun -f swift (xcode-select-aware)' {
    # Pin: `executables=($(ls $(dirname $(xcrun -f swift))))`. The
    # `xcrun -f swift` resolves to the currently-selected toolchain
    # via xcode-select. Hardcoding `/usr/bin` or a path under
    # /Applications/Xcode.app would freeze the discovery to whatever
    # was active at compile time. Pin the dynamic form.
    grep -qF '$(ls $(dirname $(xcrun -f swift)))' "$xrFile"
    assert $? equals 0
}

@test '_xcrun toolchain discovery globs ALL /Applications/Xcode*.app instances' {
    # Pin: `toolchains=(/Applications/Xcode*.app/Contents/Developer/Toolchains/*.xctoolchain)`.
    # The `Xcode*` glob covers Xcode-beta.app, Xcode_15.app, etc.
    # Hardcoding `/Applications/Xcode.app` would miss side-by-side
    # installs that many devs run.
    grep -qF '/Applications/Xcode*.app/Contents/Developer/Toolchains/' "$xrFile"
    assert $? equals 0
}

@test '_xcrun --sdk/--toolchain options route to their state callback' {
    # Pin: `--sdk[...]:SDKs:->sdks` and `--toolchain[...]:Toolchains:->toolchains`
    # both use the `->state` form so _arguments dispatches into the
    # case block. Inlining a static list would freeze the candidates
    # at plugin-install time.
    grep -qE "'--sdk\[.*\]:.*:->sdks'" "$xrFile"
    local sdk=$?
    grep -qE "'--toolchain\[.*\]:.*:->toolchains'" "$xrFile"
    local tc=$?
    assert $(( sdk + tc )) equals 0
}

@test '_xcodebuild SDK probe uses xcodebuild -showsdks (not xcrun)' {
    # Pin: the SDK list is derived from xcodebuild, not from
    # `xcrun --show-sdk-path` which would only return the active SDK.
    # Pin the canonical -showsdks invocation.
    grep -qE 'xcodebuild -showsdks' "$xbFile"
    assert $? equals 0
}
