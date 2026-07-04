use std::ffi::{c_char, CStr, CString};
use std::ptr;

use crate::completion;
use crate::events;
use crate::ffi::{self, ClientData, TclInterp, TclObj, TCL_ERROR, TCL_OK};
use crate::state;
use crate::strings;

const SUBCOMMANDS: [&[u8]; 13] = [
    b"read\0",
    b"initialize\0",
    b"write\0",
    b"add\0",
    b"complete\0",
    b"customcompleter\0",
    b"builtincompleter\0",
    b"eofchar\0",
    b"reset-terminal\0",
    b"bell\0",
    b"text\0",
    b"update\0",
    b"historyexpansion\0",
];

pub unsafe extern "C" fn command(
    _client_data: ClientData,
    interp: *mut TclInterp,
    objc: i32,
    objv: *mut *mut TclObj,
) -> i32 {
    unsafe {
        ffi::Tcl_ResetResult(interp);
    }

    if objc < 2 {
        unsafe { ffi::Tcl_WrongNumArgs(interp, 1, objv, c"option ?arg arg ...?".as_ptr()) };
        return TCL_ERROR;
    }

    let table = SUBCOMMANDS
        .iter()
        .map(|item| item.as_ptr() as *const c_char)
        .chain(std::iter::once(ptr::null()))
        .collect::<Vec<_>>();

    let mut obj_idx = 0;
    let status = unsafe {
        ffi::Tcl_GetIndexFromObj(
            interp,
            *objv.add(1),
            table.as_ptr(),
            c"option".as_ptr(),
            0,
            &mut obj_idx,
        )
    };
    if status != TCL_OK {
        return status;
    }

    match obj_idx {
        0 => read(interp, objc, objv),
        1 => initialize(interp, objc, objv),
        2 => write(interp, objc, objv),
        3 => add(interp, objc, objv),
        4 => complete(interp, objc, objv),
        5 => string_setting(
            interp,
            objc,
            objv,
            state::custom_completer(),
            c"?scriptCompleter?".as_ptr(),
        ),
        6 => bool_setting(interp, objc, objv, state::builtin_completer()),
        7 => string_setting(
            interp,
            objc,
            objv,
            state::eof_script(),
            c"?script?".as_ptr(),
        ),
        8 => reset_terminal(interp, objc, objv),
        9 => bell(interp, objc, objv),
        10 => text(interp, objc, objv),
        11 => update(interp, objc, objv),
        12 => bool_setting(interp, objc, objv, state::history_expansion()),
        _ => TCL_ERROR,
    }
}

unsafe fn obj_string(objv: *mut *mut TclObj, index: usize) -> *mut c_char {
    unsafe { ffi::Tcl_GetStringFromObj(*objv.add(index), ptr::null_mut()) }
}

unsafe fn read(interp: *mut TclInterp, objc: i32, objv: *mut *mut TclObj) -> i32 {
    let mut prompt_ds = ffi::TclDString::uninit();
    let mut prompt = c"% ".as_ptr();

    unsafe {
        ffi::Tcl_DStringInit(&mut prompt_ds);
        if objc == 3 {
            prompt = ffi::Tcl_UtfToExternalDString(
                ptr::null_mut(),
                obj_string(objv, 2),
                -1,
                &mut prompt_ds,
            );
        }
    }

    let line_state = unsafe { events::read_line(prompt) };
    unsafe { ffi::Tcl_DStringFree(&mut prompt_ds) };

    match line_state {
        state::LINE_COMPLETE => TCL_OK,
        state::LINE_EOF => {
            let eof = state::eof_script().lock().expect("eof lock");
            if let Some(script) = eof.as_ref() {
                unsafe { ffi::Tcl_Eval(interp, script.as_ptr()) }
            } else {
                TCL_OK
            }
        }
        other => other,
    }
}

unsafe fn initialize(interp: *mut TclInterp, objc: i32, objv: *mut *mut TclObj) -> i32 {
    if objc != 3 {
        unsafe { ffi::Tcl_WrongNumArgs(interp, 2, objv, c"historyfile".as_ptr()) };
        return TCL_ERROR;
    }
    crate::init::readline_initialize(interp, unsafe { obj_string(objv, 2) })
}

unsafe fn write(interp: *mut TclInterp, objc: i32, objv: *mut *mut TclObj) -> i32 {
    if objc != 3 {
        unsafe { ffi::Tcl_WrongNumArgs(interp, 2, objv, c"historyfile".as_ptr()) };
        return TCL_ERROR;
    }
    let file = unsafe { obj_string(objv, 2) };
    if unsafe { ffi::write_history(file) } != 0 {
        unsafe {
            ffi::Tcl_AppendResult(
                interp,
                c"unable to write history to `".as_ptr(),
                file,
                c"'\n".as_ptr(),
                ptr::null::<c_char>(),
            );
        }
        return TCL_ERROR;
    }
    unsafe {
        if state::TCLRL_HISTORY_LENGTH >= 0 {
            ffi::history_truncate_file(file, state::TCLRL_HISTORY_LENGTH);
        }
    }
    TCL_OK
}

unsafe fn add(interp: *mut TclInterp, objc: i32, objv: *mut *mut TclObj) -> i32 {
    if objc != 3 {
        unsafe { ffi::Tcl_WrongNumArgs(interp, 2, objv, c"completerLine".as_ptr()) };
        return TCL_ERROR;
    }
    unsafe {
        completion::known_commands(obj_string(objv, 2), 0, state::CMD_SET);
    }
    TCL_OK
}

unsafe fn complete(interp: *mut TclInterp, objc: i32, objv: *mut *mut TclObj) -> i32 {
    if objc != 3 {
        unsafe { ffi::Tcl_WrongNumArgs(interp, 2, objv, c"line".as_ptr()) };
        return TCL_ERROR;
    }
    let done = unsafe { ffi::Tcl_CommandComplete(obj_string(objv, 2)) != 0 };
    unsafe {
        ffi::Tcl_AppendResult(
            interp,
            if done { c"1".as_ptr() } else { c"0".as_ptr() },
            ptr::null::<c_char>(),
        );
    }
    TCL_OK
}

unsafe fn string_setting(
    interp: *mut TclInterp,
    objc: i32,
    objv: *mut *mut TclObj,
    slot: &'static std::sync::Mutex<Option<CString>>,
    usage: *const c_char,
) -> i32 {
    if objc > 3 {
        unsafe { ffi::Tcl_WrongNumArgs(interp, 2, objv, usage) };
        return TCL_ERROR;
    }
    let mut guard = slot.lock().expect("setting lock");
    if objc == 3 {
        let value = unsafe { CStr::from_ptr(obj_string(objv, 2)) };
        *guard = if strings::blank_line(value) {
            None
        } else {
            Some(strings::stripwhite_cstring(value))
        };
    }
    unsafe {
        ffi::Tcl_AppendResult(
            interp,
            guard
                .as_ref()
                .map(|v| v.as_ptr())
                .unwrap_or(ptr::null::<c_char>()),
            ptr::null::<c_char>(),
        );
    }
    TCL_OK
}

unsafe fn bool_setting(
    interp: *mut TclInterp,
    objc: i32,
    objv: *mut *mut TclObj,
    slot: &'static std::sync::Mutex<bool>,
) -> i32 {
    if objc > 3 {
        unsafe { ffi::Tcl_WrongNumArgs(interp, 2, objv, c"?boolean?".as_ptr()) };
        return TCL_ERROR;
    }
    let mut guard = slot.lock().expect("boolean lock");
    if objc == 3 {
        let mut value = if *guard { 1 } else { 0 };
        if unsafe { ffi::Tcl_GetBoolean(interp, obj_string(objv, 2), &mut value) } != TCL_OK {
            unsafe {
                ffi::Tcl_AppendResult(
                    interp,
                    c"wrong # args: should be a boolean value.".as_ptr(),
                    ptr::null::<c_char>(),
                );
            }
            return TCL_ERROR;
        }
        *guard = value != 0;
    }
    unsafe {
        ffi::Tcl_AppendResult(
            interp,
            if *guard { c"1".as_ptr() } else { c"0".as_ptr() },
            ptr::null::<c_char>(),
        );
    }
    TCL_OK
}

unsafe fn reset_terminal(interp: *mut TclInterp, objc: i32, objv: *mut *mut TclObj) -> i32 {
    if objc > 3 {
        unsafe { ffi::Tcl_WrongNumArgs(interp, 2, objv, c"?terminal-name?".as_ptr()) };
        return TCL_ERROR;
    }
    unsafe {
        if objc == 3 {
            ffi::rl_reset_terminal(obj_string(objv, 2));
        } else {
            #[cfg(has_rl_cleanup_after_signal)]
            ffi::rl_cleanup_after_signal();
        }
    }
    TCL_OK
}

unsafe fn bell(interp: *mut TclInterp, objc: i32, objv: *mut *mut TclObj) -> i32 {
    if objc != 2 {
        unsafe { ffi::Tcl_WrongNumArgs(interp, 2, objv, c"".as_ptr()) };
        return TCL_ERROR;
    }
    unsafe { ffi::rl_ding() };
    TCL_OK
}

unsafe fn update(interp: *mut TclInterp, objc: i32, objv: *mut *mut TclObj) -> i32 {
    if objc != 2 {
        unsafe { ffi::Tcl_WrongNumArgs(interp, 2, objv, c"".as_ptr()) };
        return TCL_ERROR;
    }
    unsafe {
        if !ffi::rl_line_buffer.is_null() {
            ffi::rl_forced_update_display();
        }
    }
    TCL_OK
}

unsafe fn text(interp: *mut TclInterp, objc: i32, objv: *mut *mut TclObj) -> i32 {
    if objc != 2 {
        unsafe { ffi::Tcl_WrongNumArgs(interp, 2, objv, c"".as_ptr()) };
        return TCL_ERROR;
    }
    unsafe {
        ffi::Tcl_SetObjResult(
            interp,
            ffi::Tcl_NewStringObj(
                if ffi::rl_line_buffer.is_null() {
                    c"".as_ptr()
                } else {
                    ffi::rl_line_buffer
                },
                -1,
            ),
        );
    }
    TCL_OK
}
