## -*- automake -*-
## FILE: Makefile.am
## $Id$
## ---
## tclreadline -- gnu readline for tcl
## https://github.com/flightaware/tclreadline/
## Copyright (c) 1998 - 2014, Johannes Zellner <johannes@zellner.org>
## This software is copyright under the BSD license.
## ---

## AUTOMAKE_OPTIONS = foreign

lib_LTLIBRARIES = libtclreadline.la

libtclreadline_la_SOURCES = config.h src/tclreadline.c tclreadline.h
include_HEADERS = tclreadline.h

AM_CPPFLAGS = -I$(builddir) -I$(srcdir)/src -I$(TCL_INCLUDE_DIR) -I$(READLINE_INCLUDE_DIR)

if !USE_TCL_STUBS
    libtclreadline_la_CFLAGS = -Wall
else
    libtclreadline_la_CFLAGS = -Wall -DUSE_TCL_STUBS
endif
if !USE_TCL_STUBS
    libtclreadline_la_LIBADD = $(TCL_LIB_SPEC)
else
    libtclreadline_la_LIBADD = $(TCL_STUB_LIB_SPEC)
endif
libtclreadline_la_LDFLAGS = -release $(MAJOR).$(MINOR).$(PATCHLEVEL)

tclrldir = @TCLRL_DIR@
tclrl_SCRIPTS = pkgIndex.tcl src/tclreadlineCompleter.tcl tclreadlineInit.tcl tclreadlineSetup.tcl
INSTALL_SCRIPT = ${INSTALL_DATA}

EXTRA_DIST =                 \
    Cargo.toml               \
    build.rs                 \
    src/bin/tclshrl.rs       \
    src/bin/wishrl.rs        \
    src/common.rs            \
    src/tests.tcl

if STATIC_TCLSHRL
rust_tclshrl = tclshrl
endif

if STATIC_WISHRL
rust_wishrl = wishrl
endif

bin_PROGRAMS = $(rust_tclshrl) $(rust_wishrl)
tclshrl_SOURCES =
wishrl_SOURCES =
CLEANFILES = tclshrl wishrl

cargo_target_dir = $(abs_builddir)/target
cargo_env = \
    TCLREADLINE_LIB_DIR="$(abs_builddir)/.libs" \
    TCLRL_LIBDIR="$(TCLRL_LIBDIR)" \
    TCLRL_LIBRARY="$(TCLRL_DIR)" \
    TCL_LIB_SPEC="$(TCL_LIB_SPEC)" \
    TK_LIB_SPEC="$(TK_LIB_SPEC)"

tclshrl$(EXEEXT): libtclreadline.la Cargo.toml build.rs src/bin/tclshrl.rs src/common.rs
	CARGO_TARGET_DIR="$(cargo_target_dir)/tclshrl" $(cargo_env) $(CARGO) build --release --manifest-path $(srcdir)/Cargo.toml --bin tclshrl
	cp "$(cargo_target_dir)/tclshrl/release/tclshrl$(EXEEXT)" "$@"

wishrl$(EXEEXT): libtclreadline.la Cargo.toml build.rs src/bin/wishrl.rs src/common.rs
	CARGO_TARGET_DIR="$(cargo_target_dir)/wishrl" $(cargo_env) $(CARGO) build --release --manifest-path $(srcdir)/Cargo.toml --bin wishrl
	cp "$(cargo_target_dir)/wishrl/release/wishrl$(EXEEXT)" "$@"

man_MANS = tclreadline.n
