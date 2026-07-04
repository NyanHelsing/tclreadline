use std::ffi::{c_char, CStr, CString};
use std::ptr;

use crate::ffi::{self, ClientData, TCL_ERROR, TCL_READABLE};
use crate::state;

pub unsafe fn line_complete() -> bool {
    unsafe { state::TCLRL_STATE != state::LINE_PENDING }
}

pub unsafe fn terminate(line_state: i32) {
    unsafe {
        state::TCLRL_STATE = line_state;
        ffi::rl_callback_handler_remove();
    }
}

pub unsafe extern "C" fn read_handler(_client_data: ClientData, mask: i32) {
    if mask & TCL_READABLE != 0 {
        unsafe {
            ffi::rl_callback_read_char();
        }
    }
}

pub unsafe extern "C" fn line_complete_handler(ptr: *mut c_char) {
    unsafe {
        ffi::Tcl_ResetResult(state::TCLRL_INTERP);
    }

    if ptr.is_null() {
        unsafe {
            terminate(state::LINE_EOF);
        }
        return;
    }

    let mut expansion = ptr;
    let mut expand_output: *mut c_char = ptr::null_mut();
    let use_history_expansion = *state::history_expansion().lock().expect("history lock");

    if use_history_expansion {
        let status = unsafe { ffi::history_expand(ptr, &mut expand_output) };

        if status >= 2 {
            unsafe {
                ffi::printf(c"%s\n".as_ptr(), expand_output);
                ffi::free(ptr.cast());
                ffi::free(expand_output.cast());
            }
            return;
        }

        if status <= -1 {
            unsafe {
                ffi::Tcl_AppendResult(
                    state::TCLRL_INTERP,
                    c"error in history expansion: ".as_ptr(),
                    expand_output,
                    c"\n".as_ptr(),
                    ptr::null::<c_char>(),
                );
                terminate(TCL_ERROR);
                ffi::free(ptr.cast());
                ffi::free(expand_output.cast());
            }
            return;
        }

        if status == 1 {
            expansion = expand_output;
        }
    }

    unsafe {
        ffi::Tcl_AppendResult(state::TCLRL_INTERP, expansion, ptr::null::<c_char>());
    }

    if !expansion.is_null() {
        let expansion_cstr = unsafe { CStr::from_ptr(expansion) };
        let mut last_line = state::last_line().lock().expect("last-line lock");
        let differs = last_line
            .as_ref()
            .map(|last| last.as_c_str() != expansion_cstr)
            .unwrap_or(true);

        if !expansion_cstr.to_bytes().is_empty() && differs {
            unsafe {
                ffi::add_history(expansion);
            }
        }
        *last_line = Some(CString::new(expansion_cstr.to_bytes()).expect("CStr has no NUL"));
    }

    unsafe {
        terminate(state::LINE_COMPLETE);
        ffi::free(ptr.cast());
        if !expand_output.is_null() {
            ffi::free(expand_output.cast());
        }
    }
}

pub unsafe fn read_line(prompt: *const c_char) -> i32 {
    unsafe {
        ffi::rl_callback_handler_install(prompt, Some(line_complete_handler));
        ffi::Tcl_CreateFileHandler(0, TCL_READABLE, Some(read_handler), ptr::null_mut());
        state::TCLRL_STATE = state::LINE_PENDING;

        while !line_complete() {
            ffi::Tcl_DoOneEvent(ffi::TCL_ALL_EVENTS);
        }

        ffi::Tcl_DeleteFileHandler(0);
        state::TCLRL_STATE
    }
}
