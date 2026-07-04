use std::ffi::{c_char, CStr, CString};
use std::ptr;

use crate::events;
use crate::ffi::{self, TCL_OK};
use crate::state;
use crate::strings;

static mut COMPLETION_LEN: usize = 0;
static mut COMPLETION_INDEX: usize = 0;
static mut COMPLETION_SUB: usize = 0;
static mut COMPLETION_COMMAND_INDEX: Option<usize> = None;

pub unsafe extern "C" fn completion(text: *const c_char, start: i32, end: i32) -> *mut *mut c_char {
    unsafe {
        ffi::rl_completion_append_character = b' ' as i32;
    }

    #[cfg(has_rl_extend_line_buffer)]
    unsafe {
        if *state::history_expansion().lock().expect("history lock")
            && !text.is_null()
            && (*text == b'!' as c_char
                || (start != 0
                    && !ffi::rl_line_buffer.is_null()
                    && *ffi::rl_line_buffer.add(start as usize - 1) == b'!' as c_char))
        {
            let mut expansion: *mut c_char = ptr::null_mut();
            let old_len = ffi::cstr_len(ffi::rl_line_buffer);
            let status = ffi::history_expand(ffi::rl_line_buffer, &mut expansion);
            if status >= 1 && !expansion.is_null() {
                let new_len = ffi::cstr_len(expansion);
                ffi::rl_extend_line_buffer((new_len + 1) as i32);
                ffi::strcpy(ffi::rl_line_buffer, expansion);
                ffi::rl_end = new_len as i32;
                ffi::rl_point += new_len as i32 - old_len as i32;
                ffi::free(expansion.cast());
                return ptr::null_mut();
            }
            if !expansion.is_null() {
                ffi::free(expansion.cast());
            }
        }
    }

    if let Some(matches) = custom_completion(text, start, end) {
        return matches;
    }

    if *state::builtin_completer().lock().expect("builtin lock") {
        unsafe { ffi::rl_completion_matches(text, Some(generator)) }
    } else {
        ptr::null_mut()
    }
}

fn custom_completion(text: *const c_char, start: i32, end: i32) -> Option<*mut *mut c_char> {
    let completer = state::custom_completer()
        .lock()
        .expect("custom completer lock")
        .clone()?;

    unsafe {
        let quoted_text = strings::quote_for_tcl(text, b"$[]{}\"");
        let quoted_line = strings::quote_for_tcl(ffi::rl_line_buffer, b"$[]{}\"");
        let start_s = CString::new(start.to_string()).expect("number");
        let end_s = CString::new(end.to_string()).expect("number");

        ffi::Tcl_ResetResult(state::TCLRL_INTERP);
        let status = ffi::Tcl_VarEval(
            state::TCLRL_INTERP,
            completer.as_ptr(),
            c" \"".as_ptr(),
            quoted_text,
            c"\" ".as_ptr(),
            start_s.as_ptr(),
            c" ".as_ptr(),
            end_s.as_ptr(),
            c" \"".as_ptr(),
            quoted_line,
            c"\"".as_ptr(),
            ptr::null::<c_char>(),
        );

        if status != TCL_OK {
            ffi::Tcl_AppendResult(
                state::TCLRL_INTERP,
                c" `".as_ptr(),
                completer.as_ptr(),
                c"' failed.".as_ptr(),
                ptr::null::<c_char>(),
            );
            events::terminate(status);
            ffi::free(quoted_text.cast());
            ffi::free(quoted_line.cast());
            return Some(ptr::null_mut());
        }

        ffi::free(quoted_text.cast());
        ffi::free(quoted_line.cast());

        let obj = ffi::Tcl_GetObjResult(state::TCLRL_INTERP);
        let mut objc = 0;
        let mut objv: *mut *mut ffi::TclObj = ptr::null_mut();
        if ffi::Tcl_ListObjGetElements(state::TCLRL_INTERP, obj, &mut objc, &mut objv) != TCL_OK
            || objc <= 0
        {
            ffi::Tcl_ResetResult(state::TCLRL_INTERP);
            return Some(ptr::null_mut());
        }

        let out = ffi::malloc((objc as usize + 1) * std::mem::size_of::<*mut c_char>())
            as *mut *mut c_char;
        if out.is_null() {
            return Some(ptr::null_mut());
        }

        let mut actual = 0usize;
        for i in 0..objc as usize {
            let value = ffi::Tcl_GetStringFromObj(*objv.add(i), ptr::null_mut());
            *out.add(actual) = ffi::strdup(value);
            if objc == 1 && ffi::cstr_len(*out.add(actual)) == 0 {
                ffi::free((*out.add(actual)).cast());
                ffi::free(out.cast());
                ffi::Tcl_ResetResult(state::TCLRL_INTERP);
                return Some(ptr::null_mut());
            }
            actual += 1;
        }

        if objc == 2 && ffi::cstr_len(*out.add(1)) == 0 {
            actual -= 1;
            ffi::free((*out.add(1)).cast());
            ffi::rl_completion_append_character = 0;
        }

        *out.add(actual) = ptr::null_mut();
        ffi::Tcl_ResetResult(state::TCLRL_INTERP);
        Some(out)
    }
}

pub unsafe extern "C" fn generator(text: *const c_char, state_no: i32) -> *mut c_char {
    known_commands(text, state_no, state::CMD_GET)
}

pub unsafe fn known_commands(text: *const c_char, state_no: i32, mode: i32) -> *mut c_char {
    match mode {
        state::CMD_SET => {
            if text.is_null() {
                return ptr::null_mut();
            }
            let words = strings::parse_words(unsafe { CStr::from_ptr(text) });
            state::known_commands()
                .lock()
                .expect("known commands lock")
                .push(words);
            ptr::null_mut()
        }
        state::CMD_GET => unsafe { get_known_command(text, state_no) },
        _ => ptr::null_mut(),
    }
}

unsafe fn get_known_command(text: *const c_char, state_no: i32) -> *mut c_char {
    if text.is_null() {
        return ptr::null_mut();
    }

    let text_bytes = unsafe { CStr::from_ptr(text).to_bytes() };
    let line_words = if unsafe { ffi::rl_line_buffer.is_null() } {
        Vec::new()
    } else {
        strings::parse_words(unsafe { CStr::from_ptr(ffi::rl_line_buffer) })
    };

    unsafe {
        if state_no == 0 {
            COMPLETION_LEN = text_bytes.len();
            COMPLETION_INDEX = 0;
            COMPLETION_SUB = line_words.len();
            COMPLETION_COMMAND_INDEX = None;
        }
    }

    let commands = state::known_commands().lock().expect("known commands lock");

    if line_words.is_empty() || (line_words.len() == 1 && !text_bytes.is_empty()) {
        unsafe {
            while COMPLETION_INDEX < commands.len() {
                let idx = COMPLETION_INDEX;
                COMPLETION_INDEX += 1;
                if commands[idx]
                    .first()
                    .map(|cmd| cmd.as_bytes().starts_with(text_bytes))
                    .unwrap_or(false)
                {
                    return ffi::strdup(commands[idx][0].as_ptr());
                }
            }
        }
        return ptr::null_mut();
    }

    unsafe {
        if state_no == 0 {
            COMPLETION_COMMAND_INDEX = commands.iter().position(|cmd| {
                cmd.first()
                    .map(|first| first.as_bytes() == line_words[0].as_bytes())
                    .unwrap_or(false)
            });
        }

        let Some(command_idx) = COMPLETION_COMMAND_INDEX else {
            return ptr::null_mut();
        };

        let cmd = &commands[command_idx];
        if COMPLETION_SUB < cmd.len() && cmd[COMPLETION_SUB].as_bytes().starts_with(text_bytes) {
            let result = ffi::strdup(cmd[COMPLETION_SUB].as_ptr());
            COMPLETION_COMMAND_INDEX = None;
            result
        } else {
            ptr::null_mut()
        }
    }
}
