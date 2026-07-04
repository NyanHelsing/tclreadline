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

libtclreadline_la_SOURCES = config.h src/tclreadline_shim.c tclreadline.h
include_HEADERS = tclreadline.h

AM_CPPFLAGS = -I$(builddir) -I$(srcdir)/src -I$(TCL_INCLUDE_DIR) -I$(READLINE_INCLUDE_DIR)

if !USE_TCL_STUBS
    libtclreadline_la_CFLAGS = -Wall
else
    libtclreadline_la_CFLAGS = -Wall -DUSE_TCL_STUBS
endif
if !USE_TCL_STUBS
    libtclreadline_la_LIBADD = $(rust_core_lib) $(TCL_LIB_SPEC)
else
    libtclreadline_la_LIBADD = $(rust_core_lib) $(TCL_STUB_LIB_SPEC)
endif
libtclreadline_la_DEPENDENCIES = $(rust_core_lib)
libtclreadline_la_LDFLAGS = -release $(MAJOR).$(MINOR).$(PATCHLEVEL)

tclrldir = @TCLRL_DIR@
tclrl_SCRIPTS = pkgIndex.tcl src/tclreadlineCompleter.tcl tclreadlineInit.tcl tclreadlineSetup.tcl
INSTALL_SCRIPT = ${INSTALL_DATA}

EXTRA_DIST =                 \
    Cargo.toml               \
    build.rs                 \
    src/bin/tclshrl.rs       \
    src/bin/wishrl.rs        \
    src/command.rs           \
    src/completion.rs        \
    src/common.rs            \
    src/events.rs            \
    src/ffi.rs               \
    src/init.rs              \
    src/lib.rs               \
    src/state.rs             \
    src/strings.rs           \
    src/tclreadline_shim.c   \
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
    CONFIG_H="$(abs_builddir)/config.h" \
    TCLREADLINE_LIB_DIR="$(abs_builddir)/.libs" \
    TCLRL_LIBDIR="$(TCLRL_LIBDIR)" \
    TCLRL_LIBRARY="$(TCLRL_DIR)" \
    TCL_LIB_SPEC="$(TCL_LIB_SPEC)" \
    TK_LIB_SPEC="$(TK_LIB_SPEC)" \
    READLINE_LIB_SPEC="$(LIBS)"

if USE_TCL_STUBS
rust_tcl_stubs_env = TCLREADLINE_USE_TCL_STUBS=1
endif

rust_core_target_dir = $(cargo_target_dir)/core
rust_core_lib = $(rust_core_target_dir)/release/libtclreadline_core.a

$(rust_core_lib): Cargo.toml build.rs src/lib.rs src/ffi.rs src/state.rs src/strings.rs src/events.rs src/completion.rs src/command.rs src/init.rs
	CARGO_TARGET_DIR="$(rust_core_target_dir)" CONFIG_H="$(abs_builddir)/config.h" TCLRL_LIBRARY="$(TCLRL_DIR)" $(rust_tcl_stubs_env) TCL_LIB_SPEC="$(TCL_LIB_SPEC)" READLINE_LIB_SPEC="$(LIBS)" $(CARGO) build --release --manifest-path $(srcdir)/Cargo.toml --lib

tclshrl$(EXEEXT): libtclreadline.la Cargo.toml build.rs src/bin/tclshrl.rs src/common.rs
	CARGO_TARGET_DIR="$(cargo_target_dir)/tclshrl" TCLREADLINE_LINK_SELF=1 $(rust_tcl_stubs_env) $(cargo_env) $(CARGO) build --release --manifest-path $(srcdir)/Cargo.toml --bin tclshrl
	cp "$(cargo_target_dir)/tclshrl/release/tclshrl$(EXEEXT)" "$@"

wishrl$(EXEEXT): libtclreadline.la Cargo.toml build.rs src/bin/wishrl.rs src/common.rs
	CARGO_TARGET_DIR="$(cargo_target_dir)/wishrl" TCLREADLINE_LINK_SELF=1 $(rust_tcl_stubs_env) $(cargo_env) $(CARGO) build --release --manifest-path $(srcdir)/Cargo.toml --bin wishrl
	cp "$(cargo_target_dir)/wishrl/release/wishrl$(EXEEXT)" "$@"

man_MANS = tclreadline.n
