# DES

DES is the package manager and build tool for [Destiny](https://github.com/Destiny-Org/destiny).
The command is `des`.

- Packages come from [Destiny-Org/packages](https://github.com/Destiny-Org/packages):
  packages that have been ported to Destiny and tested with it. DES does not
  fetch from code.dlang.org; D packages need changes to build with Destiny.
- A package is described in `dub.json` or `dub.sdl` (the same format as
  dub, so existing package files work).
- DES builds with the Destiny compiler (`destiny`).

## Using DES

```
des init myapp          # new project
cd myapp
des add vibe-d          # add a dependency from Destiny-Org/packages
des build               # build
des run                 # build and run
des test                # build and run the unittests
```

`des --help` lists every command; `des <command> --help` explains one.

To use a package from a local folder instead, register it with
`des add-path <folder>` or `des add-local <folder>`.

## Building DES

DES is built with Destiny:

```
GITVER=v1.40.0-destiny destiny -revert=safedefault -run build.d -revert=safedefault -O
./bin/des --version     # DES version 1.40.0-destiny
```

(`-revert=safedefault` because DES's code is written for D's `@system`
default.)

## Installing

Download `des-<version>-linux-x86_64.tar.gz` from this repository's
releases and put `des` on your `PATH`, or build it as above. Only Linux
x86_64 is supported, like Destiny itself.

## Using DES as a library

The `dub` package in this repository is also a library for loading and
building packages; serve-destiny uses it. The source is in `source/dub/`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT; see [LICENSE](LICENSE).
