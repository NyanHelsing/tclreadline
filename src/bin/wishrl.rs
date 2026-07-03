#![no_main]

use std::ffi::{c_char, c_int};

#[path = "../common.rs"]
mod common;

use common::{init_readline, init_tcl, AppInitProc, TclInterp, TCL_ERROR};

extern "C" {
    fn Tk_Init(interp: *mut TclInterp) -> c_int;
    fn Tk_Main(argc: c_int, argv: *mut *mut c_char, app_init_proc: Option<AppInitProc>);
}

#[no_mangle]
pub unsafe extern "C" fn main(argc: c_int, argv: *mut *mut c_char) -> c_int {
    unsafe {
        Tk_Main(argc, argv, Some(app_init));
    }

    0
}

unsafe extern "C" fn app_init(interp: *mut TclInterp) -> c_int {
    if init_tcl(interp) == TCL_ERROR {
        return TCL_ERROR;
    }

    if Tk_Init(interp) == TCL_ERROR {
        return TCL_ERROR;
    }

    init_readline(interp, "~/.wishrc")
}
