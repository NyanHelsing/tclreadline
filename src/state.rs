use std::ffi::{c_char, c_int, CString};
use std::ptr;
use std::sync::{Mutex, OnceLock};

use crate::ffi::TclInterp;

pub const LINE_PENDING: c_int = -1;
pub const LINE_EOF: c_int = 1 << 8;
pub const LINE_COMPLETE: c_int = 1 << 9;

pub const CMD_SET: c_int = 1 << 0;
pub const CMD_GET: c_int = 1 << 1;

pub static mut TCLRL_STATE: c_int = 0;
pub static mut TCLRL_INTERP: *mut TclInterp = ptr::null_mut();
pub static mut TCLRL_HISTORY_LENGTH: c_int = -1;

pub static mut TCLRL_LIBRARY: *mut c_char = ptr::null_mut();
pub static mut TCLRL_VERSION: *mut c_char = ptr::null_mut();
pub static mut TCLRL_PATCHLEVEL: *mut c_char = ptr::null_mut();
pub static mut TCLRL_LICENSE: *mut c_char = ptr::null_mut();

static EOF_SCRIPT: OnceLock<Mutex<Option<CString>>> = OnceLock::new();
static CUSTOM_COMPLETER: OnceLock<Mutex<Option<CString>>> = OnceLock::new();
static LAST_LINE: OnceLock<Mutex<Option<CString>>> = OnceLock::new();
static KNOWN_COMMANDS: OnceLock<Mutex<Vec<Vec<CString>>>> = OnceLock::new();

static BUILTIN_COMPLETER: OnceLock<Mutex<bool>> = OnceLock::new();
static HISTORY_EXPANSION: OnceLock<Mutex<bool>> = OnceLock::new();

pub fn init_static_strings() {
    unsafe {
        TCLRL_LIBRARY = leak(env!("TCLRL_LIBRARY"));
        TCLRL_VERSION = leak(env!("CARGO_PKG_VERSION"));
        TCLRL_PATCHLEVEL = leak(env!("CARGO_PKG_VERSION"));
        TCLRL_LICENSE = leak(LICENSE);
    }
}

fn leak(value: &str) -> *mut c_char {
    CString::new(value)
        .expect("static string cannot contain NUL")
        .into_raw()
}

pub fn eof_script() -> &'static Mutex<Option<CString>> {
    EOF_SCRIPT.get_or_init(|| Mutex::new(None))
}

pub fn custom_completer() -> &'static Mutex<Option<CString>> {
    CUSTOM_COMPLETER.get_or_init(|| Mutex::new(None))
}

pub fn last_line() -> &'static Mutex<Option<CString>> {
    LAST_LINE.get_or_init(|| Mutex::new(None))
}

pub fn known_commands() -> &'static Mutex<Vec<Vec<CString>>> {
    KNOWN_COMMANDS.get_or_init(|| Mutex::new(Vec::new()))
}

pub fn builtin_completer() -> &'static Mutex<bool> {
    BUILTIN_COMPLETER.get_or_init(|| Mutex::new(true))
}

pub fn history_expansion() -> &'static Mutex<bool> {
    HISTORY_EXPANSION.get_or_init(|| Mutex::new(true))
}

const LICENSE: &str = "   Copyright (c) 1998 - 2000, Johannes Zellner <johannes@zellner.org>\n\
   All rights reserved.\n\
   \n\
   Redistribution and use in source and binary forms, with or without\n\
   modification, are permitted provided that the following conditions\n\
   are met:\n\
   \n\
     * Redistributions of source code must retain the above copyright\n\
       notice, this list of conditions and the following disclaimer.\n\
     * Redistributions in binary form must reproduce the above copyright\n\
       notice, this list of conditions and the following disclaimer in the\n\
       documentation and/or other materials provided with the distribution.\n\
     * Neither the name of Johannes Zellner nor the names of contributors\n\
       to this software may be used to endorse or promote products derived\n\
       from this software without specific prior written permission.\n\
       \n\
   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS\n\
   ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT\n\
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR\n\
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR\n\
   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,\n\
   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,\n\
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR\n\
   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF\n\
   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING\n\
   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS\n\
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.";
