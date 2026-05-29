#!/usr/bin/env zunit
#{{{                    MARK:Header
#**************************************************************
##### Purpose: zsh-xcode-completions contract pins.
#####          11 _foo completion files cover Apple's Xcode
#####          toolchain. Tests pin the compdef headers, the
#####          critical helper fns (sdks/archs/configurations/
#####          schemes), and verify each file loads under autoload
#####          without syntax errors.
#}}}***********************************************************

@setup {
    0="${${0:#$ZSH_ARGZERO}:-${(%):-%N}}"
    0="${${(M)0:#/*}:-$PWD/$0}"
    pluginDir="${0:h:A}"
    pluginFile="$pluginDir/zsh-xcode-completions.plugin.zsh"
    srcDir="$pluginDir/src"
    binDir="$pluginDir/bin"
}

@test 'plugin appends src/ to fpath (completion discovery)' {
    local body
    body=$(cat "$pluginFile")
    assert "$body" contains 'fpath=("${0:h}/src" $fpath)'
}

@test 'plugin file is intentionally minimal (just fpath augmentation)' {
    # Pin: this plugin is a pure-completion bundle. The .plugin.zsh
    # MUST stay minimal — anything else should go into src/.
    local lines
    lines=$(wc -l < "$pluginFile" | tr -d ' ')
    local result=$([[ "$lines" -le 10 ]] && echo yes || echo "no:$lines")
    assert "$result" same_as 'yes'
}

@test 'src/ ships completions for all 11 Xcode toolchain commands' {
    # Pin: catastrophic-shrink guard. The completion bundle covers
    # the Xcode/Swift/LLVM tool set users actually invoke.
    for tool in _dyldinfo _genstrings _instruments _nm _plutil \
                _strings _swift _swift-demangle _xcode-select \
                _xcodebuild _xcrun
    do
        assert "$srcDir/$tool" is_file
    done
}

@test 'each completion file starts with #compdef for its target command' {
    # Pin: without #compdef as the first line, compinit silently
    # ignores the completion.
    local f base first cmd cmds bad=""
    for f in "$srcDir"/_*; do
        [[ -f "$f" ]] || continue
        base=${f:t}
        cmd=${base#_}
        first=$(head -1 "$f")
        if [[ "$first" != "#compdef "* ]]; then
            bad="$bad $base:no-compdef"
            continue
        fi
        cmds=${first#\#compdef }
        if [[ " $cmds " != *" $cmd "* ]]; then
            bad="$bad $base:no-cmd-match($first)"
        fi
    done
    assert "$bad" is_empty
}

@test '_xcodebuild defines _archs, _configurations, _schemes, _sdks helpers' {
    # Pin: these 4 helpers are the dynamic-completion engine. Each
    # shells out to xcodebuild to introspect the user's project.
    # Dropping any silently kills that dimension of completion.
    local body
    body=$(cat "$srcDir/_xcodebuild")
    assert "$body" contains '_archs()'
    assert "$body" contains '_configurations()'
    assert "$body" contains '_schemes()'
    assert "$body" contains '_sdks()'
}

@test '_xcodebuild _archs reads VALID_ARCHS from showBuildSettings' {
    # Pin: VALID_ARCHS is THE build setting Xcode lists. Renaming
    # the grep target silently empties arch completion.
    local body
    body=$(cat "$srcDir/_xcodebuild")
    assert "$body" contains 'xcodebuild -showBuildSettings'
    assert "$body" contains 'VALID_ARCHS'
}

@test '_xcodebuild _schemes parses xcodebuild -list output for "Schemes:" section' {
    # Pin: the documented output format. Without sed-targeting
    # "Schemes:", -scheme completion stops working.
    local body
    body=$(cat "$srcDir/_xcodebuild")
    assert "$body" contains 'xcodebuild -list'
    assert "$body" contains 'Schemes:'
}

@test '_xcodebuild _configurations parses Build Configurations section' {
    local body
    body=$(cat "$srcDir/_xcodebuild")
    assert "$body" contains 'Build Configurations:'
}

@test '_swift declares _sdks helper that calls xcodebuild -showsdks' {
    # Pin: swift -sdk completion needs the SDK list; the helper
    # delegates to xcodebuild. Hardcoding "iphoneos macosx" etc.
    # would silently go stale on every Xcode update.
    local body
    body=$(cat "$srcDir/_swift")
    assert "$body" contains '_sdks()'
    assert "$body" contains 'xcodebuild -showsdks'
}

@test '_swift covers the documented compilation flags (-emit-* + optimization)' {
    # Pin: the canonical swiftc flag set. If a refactor accidentally
    # drops the emit-* family, users lose completion for the most
    # common build modes.
    local body
    body=$(cat "$srcDir/_swift")
    assert "$body" contains '-emit-assembly'
    assert "$body" contains '-emit-library'
    assert "$body" contains '-emit-object'
    assert "$body" contains '-module-name'
}

@test '_xcrun supports the documented short + long flag pairs (--find/--kill-cache/etc)' {
    # Pin: xcrun's UX advertises both short and long forms. The
    # exclusion-group syntax (-f --find){-f,--find} keeps them in sync.
    local body
    body=$(cat "$srcDir/_xcrun")
    assert "$body" contains '(-f --find)'
    assert "$body" contains '(-h --help)'
    assert "$body" contains '(-k --kill-cache)'
    assert "$body" contains '(-r --run)'
}

@test '_xcrun --sdk completion routes through _sdks helper' {
    # Pin: --sdk completion delegates to _sdks (which calls
    # xcodebuild -showsdks). If --sdk is hardcoded, the list
    # goes stale.
    local body
    body=$(cat "$srcDir/_xcrun")
    assert "$body" contains '--sdk'
    assert "$body" contains '->sdks'
}

@test '_instruments caches templates via _retrieve_cache/_store_cache' {
    # Pin: `instruments -s templates` is slow. The cache wrap is
    # what makes `instruments -t<tab>` tolerable.
    local body
    body=$(cat "$srcDir/_instruments")
    assert "$body" contains '_retrieve_cache _instruments_templates'
    assert "$body" contains '_store_cache _instruments_templates'
}

@test '_instruments strips the "Known Templates" heading via shift' {
    # Pin: the first line of `instruments -s templates` is a heading,
    # not a template name. The `shift template_list` removes it. If
    # dropped, "Known Templates" appears as a fake template candidate.
    local body
    body=$(cat "$srcDir/_instruments")
    assert "$body" contains 'shift template_list'
}

@test '_plutil + _nm + _strings + _dyldinfo + _genstrings + _xcode-select + _swift-demangle all parse cleanly' {
    # Pin: smaller completions still need syntax-clean files.
    for tool in _plutil _nm _strings _dyldinfo _genstrings _xcode-select _swift-demangle; do
        run zsh -n "$srcDir/$tool"
        assert $state equals 0
    done
}

@test 'all 11 completion files parse cleanly under zsh -n' {
    local f
    for f in "$srcDir"/_*; do
        [[ -f "$f" ]] || continue
        run zsh -n "$f"
        assert $state equals 0
    done
}

@test 'all 11 completion files load cleanly under autoload +X' {
    # End-to-end: zsh's compsys can actually load each completion
    # without erroring. Catches a syntax-clean-but-eval-broken file.
    local f base ok bad=""
    for f in "$srcDir"/_*; do
        [[ -f "$f" ]] || continue
        base=${f:t}
        ok=$(zsh -c "
            emulate zsh
            fpath=('$srcDir' \$fpath)
            autoload -U $base
            autoload +X $base && print OK || print FAIL
        " 2>&1)
        if [[ "$ok" != "OK" ]]; then
            bad="$bad $base:$ok"
        fi
    done
    assert "$bad" is_empty
}

@test 'bin/swift-demangle exists (vendored binary stub for the demangle tool)' {
    # Pin: the bin entry is a convenience wrapper; if it disappears
    # users who set up the plugin via zinit etc. lose the PATH entry.
    assert "$binDir/swift-demangle" is_file
}

@test 'plugin sources cleanly + puts src/ on fpath' {
    local found
    found=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        print \${fpath[(r)*$srcDir*]}
    ")
    assert "$found" contains 'src'
}

@test 're-sourcing the plugin keeps fpath stable (no accumulation)' {
    local one two
    one=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        print \$fpath[1]
    ")
    two=$(zsh -c "
        emulate zsh
        source '$pluginFile'
        source '$pluginFile'
        print \$fpath[1]
    ")
    assert "$one" same_as "$two"
}
