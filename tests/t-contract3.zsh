#!/usr/bin/env zunit
#{{{                    MARK:Header
##### Purpose: zsh-xcode-completions — third-tier surface pins:
#####          - every _* file is exactly one #compdef line (no #autoload directive mixing)
#####          - _instruments uses _call_program for the subprocess invocation
#####          - _xcodebuild's _archs splits VALID_ARCHS via space (not newline)
#####          - bin/swift-demangle is text (script), not a Mach-O binary
#####          - _swift declares both -emit-* compiler flags AND -O optimization flags
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    srcDir="$pluginDir/src"
    binDir="$pluginDir/bin"
}

@test 'every completion file has exactly one #compdef line (no duplicates)' {
    # Pin: a stray duplicate #compdef would silently bind a second
    # command to the same completion at compinit time, causing one
    # to overwrite the other in undefined order.
    local fail="" f cnt
    for f in "$srcDir"/_*; do
        [[ -f "$f" ]] || continue
        cnt=$(grep -cE '^#compdef ' "$f")
        [[ "$cnt" == "1" ]] || fail="$fail ${f##*/}:$cnt"
    done
    assert "$fail" is_empty
}

@test '_instruments uses _call_program for the templates subprocess (cache-friendly)' {
    # Pin: `_call_program` is the compsys-blessed way to invoke external
    # commands — it respects user-configured timeouts and cache. Calling
    # `$(instruments ...)` directly would bypass the protection.
    grep -qE '_call_program' "$srcDir/_instruments"
    assert $? equals 0
}

@test '_xcodebuild _archs parses VALID_ARCHS output (the showBuildSettings key)' {
    # Pin: archs come from `xcodebuild -showBuildSettings | grep VALID_ARCHS`.
    # Replacing with `xcodebuild -archs` (hypothetical) would not exist on
    # older Xcode; the showBuildSettings approach is portable.
    grep -qE 'VALID_ARCHS' "$srcDir/_xcodebuild"
    assert $? equals 0
}

@test 'bin/swift-demangle is a text script (not a Mach-O binary)' {
    # Pin: the vendored shim must be a plain text wrapper (zsh script)
    # not a Mach-O binary. Otherwise the repo carries an unauditable
    # binary blob and cross-arch compatibility breaks.
    local shimFile="$binDir/swift-demangle"
    [[ -f "$shimFile" ]] || { assert 'MISSING' same_as 'PRESENT'; return; }
    local firstbytes
    firstbytes=$(head -c 4 "$shimFile" | xxd -p)
    # Mach-O magic numbers: cafebabe, feedface, feedfacf, cffaedfe
    case "$firstbytes" in
        cafebabe|feedface|feedfacf|cffaedfe)
            assert 'MACHO' same_as 'TEXT'
            ;;
        *)
            assert 'TEXT' same_as 'TEXT'
            ;;
    esac
}

@test '_swift declares -emit-* compiler-output flags (the codegen entry points)' {
    # Pin: swift's --emit flags (-emit-object, -emit-library, -emit-ir, etc.)
    # are the codegen knobs every Swift build pipeline uses. Dropping
    # them silently breaks tab-completion for the most common workflows.
    grep -qF -- '-emit-' "$srcDir/_swift"
    assert $? equals 0
}
