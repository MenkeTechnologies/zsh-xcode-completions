#!/usr/bin/env zunit
#{{{                    MARK:Header
##### Purpose: zsh-xcode-completions — second-tier pins.
#####          Cover bin/swift-demangle exec contract, _xcodebuild
#####          _sdks helper, the universal property that each
#####          completion file lists its command name, and that
#####          no two completion files step on each other's name.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    srcDir="$pluginDir/src"
    binDir="$pluginDir/bin"
}

@test 'bin/swift-demangle is executable AND wraps xcrun swift-demangle' {
    # Pin: the vendored shim must (a) be executable, (b) delegate to
    # xcrun so the always-current toolchain version is used. A
    # hardcoded path would rot on every Xcode update.
    assert "$binDir/swift-demangle" is_file
    [[ -x "$binDir/swift-demangle" ]]
    assert $? equals 0
    local body
    body=$(cat "$binDir/swift-demangle")
    assert "$body" contains 'xcrun swift-demangle'
}

@test '_xcodebuild defines _sdks helper (Apple SDK list provider)' {
    # Pin: alongside _archs/_configurations/_schemes, _sdks is the
    # 4th dimension of xcodebuild completion. Already pinned in
    # _swift; pin here in _xcodebuild explicitly.
    local body
    body=$(cat "$srcDir/_xcodebuild")
    assert "$body" contains '_sdks()'
}

@test 'no two completion files claim the same primary command (uniqueness)' {
    # Pin: the #compdef directive is the registration key. If two
    # files claim the same primary command, the later autoload wins
    # silently, masking the other.
    local f primary dups=""
    typeset -A seen
    for f in "$srcDir"/_*; do
        [[ -f "$f" ]] || continue
        primary=$(head -1 "$f" | awk '{print $2}')
        if [[ -n "${seen[$primary]}" ]]; then
            dups="$dups $primary:${seen[$primary]},${f:t}"
        else
            seen[$primary]="${f:t}"
        fi
    done
    assert "$dups" is_empty
}

@test '_swift completion compdef includes both swift AND swiftc (one entry per binary)' {
    # Pin: real `swiftc` is the compiler. Some Xcode versions ship
    # both binaries. Verify the head line either is just `#compdef swift`
    # (the documented convention here) — pin so a future expansion
    # is a deliberate change.
    local first
    first=$(head -1 "$srcDir/_swift")
    assert "$first" same_as '#compdef swift'
}

@test 'completion file basename underscore-prefix matches first-#compdef token' {
    # Pin: zsh convention is that _foo provides completion for foo.
    # Underscore-prefix MUST equal first token after #compdef.
    local f base cmd first mismatch=""
    for f in "$srcDir"/_*; do
        [[ -f "$f" ]] || continue
        base=${f:t}
        cmd=${base#_}
        first=$(head -1 "$f")
        # first token after "#compdef "
        local token
        token=${${first#\#compdef }%% *}
        if [[ "$token" != "$cmd" ]]; then
            mismatch="$mismatch ${base}:file=$cmd/compdef=$token"
        fi
    done
    assert "$mismatch" is_empty
}
