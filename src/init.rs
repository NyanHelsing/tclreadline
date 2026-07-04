use std::ffi::{c_char, CString};
use std::ptr;

use crate::command;
use crate::completion;
use crate::ffi::{
    self, TclInterp, TCL_ERROR, TCL_LINK_INT, TCL_LINK_READ_ONLY, TCL_LINK_STRING, TCL_OK,
};
use crate::state;

#[unsafe(no_mangle)]
pub unsafe extern "C" fn Tclreadline_SafeInit(interp: *mut TclInterp) -> i32 {
    unsafe { Tclreadline_Init(interp) }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn Tclreadline_Init(interp: *mut TclInterp) -> i32 {
    unsafe {
        #[cfg(use_tcl_stubs)]
        let tcl_api = ffi::Tcl_InitStubs(interp, c"8.6-".as_ptr(), 0);
        #[cfg(not(use_tcl_stubs))]
        let tcl_api = ffi::Tcl_PkgRequire(interp, c"Tcl".as_ptr(), c"8.6-".as_ptr(), 0);
        if tcl_api.is_null() {
            return TCL_ERROR;
        }

        state::init_static_strings();
        ffi::Tcl_CreateObjCommand(
            interp,
            c"::tclreadline::readline".as_ptr(),
            Some(command::command),
            ptr::null_mut(),
            None,
        );
        state::TCLRL_INTERP = interp;

        let links = [
            (
                c"::tclreadline::historyLength".as_ptr(),
                std::ptr::addr_of_mut!(state::TCLRL_HISTORY_LENGTH) as *mut c_char,
                TCL_LINK_INT,
            ),
            (
                c"::tclreadline::library".as_ptr(),
                std::ptr::addr_of_mut!(state::TCLRL_LIBRARY) as *mut c_char,
                TCL_LINK_STRING | TCL_LINK_READ_ONLY,
            ),
            (
                c"::tclreadline::version".as_ptr(),
                std::ptr::addr_of_mut!(state::TCLRL_VERSION) as *mut c_char,
                TCL_LINK_STRING | TCL_LINK_READ_ONLY,
            ),
            (
                c"::tclreadline::patchLevel".as_ptr(),
                std::ptr::addr_of_mut!(state::TCLRL_PATCHLEVEL) as *mut c_char,
                TCL_LINK_STRING | TCL_LINK_READ_ONLY,
            ),
            (
                c"::tclreadline::license".as_ptr(),
                std::ptr::addr_of_mut!(state::TCLRL_LICENSE) as *mut c_char,
                TCL_LINK_STRING | TCL_LINK_READ_ONLY,
            ),
            (
                c"tclreadline_library".as_ptr(),
                std::ptr::addr_of_mut!(state::TCLRL_LIBRARY) as *mut c_char,
                TCL_LINK_STRING | TCL_LINK_READ_ONLY,
            ),
            (
                c"tclreadline_version".as_ptr(),
                std::ptr::addr_of_mut!(state::TCLRL_VERSION) as *mut c_char,
                TCL_LINK_STRING | TCL_LINK_READ_ONLY,
            ),
            (
                c"tclreadline_patchLevel".as_ptr(),
                std::ptr::addr_of_mut!(state::TCLRL_PATCHLEVEL) as *mut c_char,
                TCL_LINK_STRING | TCL_LINK_READ_ONLY,
            ),
        ];

        for (name, addr, kind) in links {
            let status = ffi::Tcl_LinkVar(interp, name, addr, kind);
            if status != TCL_OK {
                return status;
            }
        }

        ffi::Tcl_PkgProvide(interp, c"tclreadline".as_ptr(), state::TCLRL_VERSION)
    }
}

pub unsafe fn readline_initialize(interp: *mut TclInterp, historyfile: *const c_char) -> i32 {
    unsafe {
        ffi::rl_readline_name = CString::new("tclreadline").unwrap().into_raw();
        ffi::rl_special_prefixes = CString::new("$").unwrap().into_raw();
        ffi::rl_basic_word_break_characters = CString::new(" \t\n\\@$=;|&[]").unwrap().into_raw();
        ffi::using_history();

        if state::eof_script().lock().expect("eof lock").is_none() {
            *state::eof_script().lock().expect("eof lock") =
                Some(CString::new("puts {}; exit").unwrap());
        }

        ffi::rl_attempted_completion_function = Some(completion::completion);
        if ffi::read_history(historyfile) != 0 && ffi::write_history(historyfile) != 0 {
            ffi::Tcl_AppendResult(
                interp,
                c"warning: `".as_ptr(),
                historyfile,
                c"' is not writable.".as_ptr(),
                ptr::null::<c_char>(),
            );
        }
    }
    TCL_OK
}
