# dub package manager

Package and build manager for [D](http://dlang.org/) applications and libraries.

Packages come from the D package registry at <https://code.dlang.org>.

[![GitHub tag](https://img.shields.io/github/tag/dlang/dub.svg?maxAge=86400)](#) [![Coverage Status](https://coveralls.io/repos/dlang/dub/badge.svg)](https://coveralls.io/r/dlang/dub)
[![Buildkite](https://badge.buildkite.com/c54d71c42284a042b9d578e28e093dff35f20cc8528319b1b6.svg?branch=master)](https://buildkite.com/dlang/dub)

## Introduction

DUB emerged as a more general replacement for [vibe.d's](http://vibed.org/) package manager. It does not imply a dependency to vibe.d for packages and was extended to not only directly build projects, but also to generate project files (currently [VisualD](https://github.com/rainers/visuald)).
[Mono-D](http://mono-d.alexanderbothe.com/) also supports the use of dub.json (dub's package description) as the project file.

The project's philosophy is to keep things as simple as possible. All that is needed to make a project a dub package is to write a short [dub.json](http://code.dlang.org/publish) file and put the source code into a `source` subfolder. It *can* then be registered on the public [package registry](http://code.dlang.org) to be made available for everyone. Any dependencies specified in `dub.json` are automatically downloaded and made available to the project during the build process.

## Key features

 - Simple package and build description not getting in your way
 - Integrated with Git, avoiding maintenance tasks such as incrementing version numbers or uploading new project releases
 - Generates VisualD project/solution files, integrated into MonoD
 - Support for DMD, GDC and LDC (common DMD flags are translated automatically)
 - Supports development workflows by optionally using local directories as a package source

## Future direction

To make things as flexible as they need to be for certain projects, it is planned to gradually add more options to the [package file format](http://code.dlang.org/package-format) and eventually to add the possibility to specify an external build tool along with the path of it's output files. The idea is that DUB provides a convenient build management that suffices for 99% of projects, but is also usable as a bare package manager that doesn't get in your way if needed.

## Installation

This fork is built from source with Destiny (see "Destiny changes" above).
Package-manager installs (Chocolatey, Homebrew, distribution packages) give
upstream dub, which does not know the Destiny compiler.

## Using DUB as a library

DUB can also be used as a library to load or manipulate packages, or to resemble any functionality of the command line tool. The former task can be achieved by using the [Package class](https://github.com/dlang/dub/blob/master/source/dub/package_.d#L40). For examples on how to replicate the command line functionality, see [commandline.d](https://github.com/dlang/dub/blob/master/source/dub/commandline.d).

## Compiler required to build DUB

Destiny (with `-revert=safedefault`).

# Contributing

New contributers are always welcome, there's plenty to work on! For an easy start, take a look at issues marked `bootcamp`
The contributing guidelines are in [CONTRIBUTING.md](CONTRIBUTING.md)
