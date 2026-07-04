#![allow(non_camel_case_types)]

use std::ffi::{c_char, c_int, c_void};

pub const TCL_OK: c_int = 0;
pub const TCL_ERROR: c_int = 1;
pub const TCL_READABLE: c_int = 1 << 1;
pub const TCL_ALL_EVENTS: c_int = !TCL_DONT_WAIT;
const TCL_DONT_WAIT: c_int = 1 << 1;

pub const TCL_LINK_INT: c_int = 1;
pub const TCL_LINK_STRING: c_int = 4;
pub const TCL_LINK_READ_ONLY: c_int = 0x80;

pub type ClientData = *mut c_void;

#[repr(C)]
pub struct TclInterp {
    _private: [u8; 0],
}

#[repr(C)]
pub struct TclObj {
    _private: [u8; 0],
}

pub type TclObjCmdProc =
    unsafe extern "C" fn(ClientData, *mut TclInterp, c_int, *mut *mut TclObj) -> c_int;
pub type TclFileProc = unsafe extern "C" fn(ClientData, c_int);
pub type RlLineHandler = unsafe extern "C" fn(*mut c_char);
pub type RlCompletionFunc = unsafe extern "C" fn(*const c_char, c_int, c_int) -> *mut *mut c_char;
pub type RlGeneratorFunc = unsafe extern "C" fn(*const c_char, c_int) -> *mut c_char;

#[repr(C)]
pub struct TclDString {
    string: *mut c_char,
    length: c_int,
    space_avail: c_int,
    static_space: [c_char; 200],
}

impl TclDString {
    pub fn uninit() -> Self {
        Self {
            string: std::ptr::null_mut(),
            length: 0,
            space_avail: 0,
            static_space: [0; 200],
        }
    }
}

unsafe extern "C" {
    pub fn malloc(size: usize) -> *mut c_void;
    pub fn free(ptr: *mut c_void);
    pub fn strdup(s: *const c_char) -> *mut c_char;
    pub fn strlen(s: *const c_char) -> usize;
    pub fn strcpy(dst: *mut c_char, src: *const c_char) -> *mut c_char;
    pub fn printf(fmt: *const c_char, ...) -> c_int;

    pub fn Tcl_AppendResult(interp: *mut TclInterp, ...);
    pub fn Tcl_CommandComplete(cmd: *const c_char) -> c_int;
    pub fn Tcl_CreateFileHandler(
        fd: c_int,
        mask: c_int,
        proc_: Option<TclFileProc>,
        client_data: ClientData,
    );
    pub fn Tcl_CreateObjCommand(
        interp: *mut TclInterp,
        cmd_name: *const c_char,
        proc_: Option<TclObjCmdProc>,
        client_data: ClientData,
        delete_proc: Option<unsafe extern "C" fn(ClientData)>,
    ) -> ClientData;
    pub fn Tcl_DeleteFileHandler(fd: c_int);
    pub fn Tcl_DoOneEvent(flags: c_int) -> c_int;
    pub fn Tcl_DStringFree(ds: *mut TclDString);
    pub fn Tcl_DStringInit(ds: *mut TclDString);
    pub fn Tcl_Eval(interp: *mut TclInterp, script: *const c_char) -> c_int;
    pub fn Tcl_GetBoolean(
        interp: *mut TclInterp,
        src: *const c_char,
        bool_ptr: *mut c_int,
    ) -> c_int;
    pub fn Tcl_GetIndexFromObj(
        interp: *mut TclInterp,
        obj: *mut TclObj,
        table: *const *const c_char,
        msg: *const c_char,
        flags: c_int,
        index_ptr: *mut c_int,
    ) -> c_int;
    pub fn Tcl_GetObjResult(interp: *mut TclInterp) -> *mut TclObj;
    pub fn Tcl_GetStringFromObj(obj: *mut TclObj, length_ptr: *mut c_int) -> *mut c_char;
    #[cfg(use_tcl_stubs)]
    pub fn Tcl_InitStubs(
        interp: *mut TclInterp,
        version: *const c_char,
        exact: c_int,
    ) -> *const c_char;
    pub fn Tcl_LinkVar(
        interp: *mut TclInterp,
        var_name: *const c_char,
        addr: *mut c_char,
        type_: c_int,
    ) -> c_int;
    pub fn Tcl_ListObjGetElements(
        interp: *mut TclInterp,
        list: *mut TclObj,
        objc: *mut c_int,
        objv: *mut *mut *mut TclObj,
    ) -> c_int;
    pub fn Tcl_NewStringObj(bytes: *const c_char, length: c_int) -> *mut TclObj;
    pub fn Tcl_PkgProvide(
        interp: *mut TclInterp,
        name: *const c_char,
        version: *const c_char,
    ) -> c_int;
    pub fn Tcl_PkgRequire(
        interp: *mut TclInterp,
        name: *const c_char,
        version: *const c_char,
        exact: c_int,
    ) -> *const c_char;
    pub fn Tcl_ResetResult(interp: *mut TclInterp);
    pub fn Tcl_SetObjResult(interp: *mut TclInterp, obj: *mut TclObj);
    pub fn Tcl_UtfToExternalDString(
        encoding: ClientData,
        src: *const c_char,
        len: c_int,
        ds: *mut TclDString,
    ) -> *const c_char;
    pub fn Tcl_VarEval(interp: *mut TclInterp, ...) -> c_int;
    pub fn Tcl_WrongNumArgs(
        interp: *mut TclInterp,
        objc: c_int,
        objv: *mut *mut TclObj,
        message: *const c_char,
    );

    pub fn add_history(line: *const c_char);
    pub fn history_expand(line: *const c_char, output: *mut *mut c_char) -> c_int;
    pub fn history_truncate_file(file: *const c_char, nlines: c_int) -> c_int;
    pub fn read_history(file: *const c_char) -> c_int;
    pub fn using_history();
    pub fn write_history(file: *const c_char) -> c_int;

    pub fn rl_callback_handler_install(prompt: *const c_char, handler: Option<RlLineHandler>);
    pub fn rl_callback_handler_remove();
    pub fn rl_callback_read_char();
    pub fn rl_cleanup_after_signal();
    pub fn rl_completion_matches(
        text: *const c_char,
        generator: Option<RlGeneratorFunc>,
    ) -> *mut *mut c_char;
    pub fn rl_ding();
    pub fn rl_extend_line_buffer(len: c_int);
    pub fn rl_forced_update_display();
    pub fn rl_reset_terminal(name: *const c_char);

    pub static mut rl_attempted_completion_function: Option<RlCompletionFunc>;
    pub static mut rl_basic_word_break_characters: *mut c_char;
    pub static mut rl_completion_append_character: c_int;
    pub static mut rl_end: c_int;
    pub static mut rl_line_buffer: *mut c_char;
    pub static mut rl_point: c_int;
    pub static mut rl_readline_name: *mut c_char;
    pub static mut rl_special_prefixes: *mut c_char;
}

pub unsafe fn cstr_len(ptr: *const c_char) -> usize {
    if ptr.is_null() {
        0
    } else {
        unsafe { strlen(ptr) }
    }
}

pub unsafe fn alloc_c_string(bytes: &[u8]) -> *mut c_char {
    let ptr = unsafe { malloc(bytes.len() + 1) as *mut c_char };
    if ptr.is_null() {
        return ptr;
    }
    unsafe {
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), ptr as *mut u8, bytes.len());
        *ptr.add(bytes.len()) = 0;
    }
    ptr
}
