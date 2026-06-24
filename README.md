```
 ███████╗███████╗██╗  ██╗
 ╚══███╔╝██╔════╝██║  ██║
   ███╔╝ ███████╗███████║
  ███╔╝  ╚════██║██╔══██║
 ███████╗███████║██║  ██║
 ╚══════╝╚══════╝╚═╝  ╚═╝
       [ x c o d e ]
```

[![CI](https://github.com/MenkeTechnologies/zsh-xcode-completions/actions/workflows/ci.yml/badge.svg)](https://github.com/MenkeTechnologies/zsh-xcode-completions/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![zsh](https://img.shields.io/badge/zsh-plugin-cyan.svg)](https://github.com/MenkeTechnologies/zpwr)

### `[ZSH COMPLETIONS FOR THE XCODE COMMAND-LINE TOOLS]`

> *"`xcodebuild`, `xcrun`, `genstrings`, `nm`, `plutil`, `swift` — all completed."*

Zsh completions for some of the Xcode command line tools. Currently:

- `dyldinfo`
- [`genstrings`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/genstrings.1.html)
- `instruments`
- [`nm`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/nm.1.html)
- [`plutil`](https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man1/plutil.1.html)
- `strings`
- `swift`
- `swift-demangle`
- [`xcode-select`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/xcode-select.1.html)
- [`xcodebuild`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/xcodebuild.1.html)
- [`xcrun`](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/xcrun.1.html) — see [Shims](#shims) for more info

### [`strykelang`](https://github.com/MenkeTechnologies/strykelang) &middot; [`zshrs`](https://github.com/MenkeTechnologies/zshrs) · [`MenkeTechnologiesMeta`](https://github.com/MenkeTechnologies/MenkeTechnologiesMeta) · [`zsh-more-completions`](https://github.com/MenkeTechnologies/zsh-more-completions) · [`zsh-cargo-completion`](https://github.com/MenkeTechnologies/zsh-cargo-completion) · [`zpwr`](https://github.com/MenkeTechnologies/zpwr)

### [`Read the Docs`](https://menketechnologies.github.io/zsh-xcode-completions/) &middot; [`Engineering Report`](https://menketechnologies.github.io/zsh-xcode-completions/report.html)

---

## Table of Contents

- [\[0x00\] Installation](#0x00-installation)
- [\[0x01\] TODO:](#0x01-todo)

---

## [0x00] Installation

```sh
brew install keith/formulae/zsh-xcode-completions
```

## [0x01] TODO:

- lipo
- otool
- pkgutil
- pmset

### Shims

Unfortunately, because of how `xcrun` happens to work, creating
completions that also handle the nested completions for programs run
through `xcrun` (such as `swift-demangle`) has proven to be difficult.
To get around this, I have created [shims](bin) for programs that could
use completions. I've also added a homebrew option (`--without-shims`)
if you would like to exclude these from being installed. One
disadvantage to this approach is you cannot pass arguments to the
`xcrun` command while calling a shim.

### Resources

<https://github.com/zsh-users/zsh-completions/blob/master/zsh-completions-howto.org>
