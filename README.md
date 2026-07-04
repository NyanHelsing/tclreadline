![Linux CI](https://github.com/flightaware/tclreadline/workflows/Linux%20CI/badge.svg)
![Mac CI](https://github.com/flightaware/tclreadline/workflows/Mac%20CI/badge.svg)

# tclreadline -- gnu readline for tcl

Copyright (c) 1998 - 2014, Johannes Zellner <johannes@zellner.org>
This software is copyright under the BSD license.



tclreadline


Introduction
===============

This directory contains the sources and documentation for tclreadline,
which builds a connection between tcl and the gnu readline.

Documentation
================

The tclreadline.n nroff man page in this release contains the reference
manual entries for tclreadline.  If you only want to use tclreadline as
a tool for interactive script development,  you don't have to read this
manual page at all.  Simply change your .tclshrc according to the section
later in this file.

Compiling and installing tclreadline
=======================================

This release will probably only build under UNIX (Linux).

Before trying to compile tclreadline you should do the following things:

1. Make sure you have tcl 8.0 or higher. 
   tclreadline relies on a proper tcl installation:
   It uses the tclConfig.sh file, which should reside somewhere
   in /usr/local/lib/ or /usr/local/lib/tcl8.0/...

2. Make sure you have gnu readline 2.2 or higher.
   tclreadline uses the gnu readline callback handler, which
   wasn't implemented in early releases.

3. Follow the instructions in README.{your-OS}, if there isn't one,
   adapt the README.Linux instructions.

4. Build the shared library and tclshrl with Cargo:

        cargo build --release

5. Install the shared library, Tcl package scripts, header, man page, and
   tclshrl with the Tcl installer:

        tools/install.tcl --prefix /usr/local

   If tclConfig.sh is not in a standard library directory, pass it explicitly:

        tools/install.tcl --tcl-config /path/to/tclConfig.sh

   To also build and install wishrl, provide Tk and enable the wish target:

        tools/install.tcl --with-wish --tk-config /path/to/tkConfig.sh


Using tclreadline for interactive tcl scripting.
================================================

copy the sample.tclshrc to $HOME/.tclshrc. If you use another interpreter
like wish, you should copy the file sample.tclshrc to $HOME/.wishrc
(or whatever the manual page of your interpreter says.) If you have
installed tclreadline properly, you are just ready to start:
start your favorite interpreter. The tclreadlineSetup.tcl script
does the rest.
