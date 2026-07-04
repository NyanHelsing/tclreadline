use std::ffi::{c_char, c_int, CString};

pub const TCL_OK: c_int = 0;
pub const TCL_ERROR: c_int = 1;

const TCL_GLOBAL_ONLY: c_int = 1;

#[repr(C)]
pub struct TclInterp {
    _private: [u8; 0],
}

pub type AppInitProc = unsafe extern "C" fn(*mut TclInterp) -> c_int;
type PackageInitProc = unsafe extern "C" fn(*mut TclInterp) -> c_int;

extern "C" {
    pub fn Tcl_EvalFile(interp: *mut TclInterp, file_name: *const c_char) -> c_int;
    pub fn Tcl_Init(interp: *mut TclInterp) -> c_int;
    fn Tcl_SetVar(
        interp: *mut TclInterp,
        var_name: *const c_char,
        new_value: *const c_char,
        flags: c_int,
    ) -> *const c_char;
    fn Tcl_StaticPackage(
        interp: *mut TclInterp,
        package_name: *const c_char,
        init_proc: Option<PackageInitProc>,
        safe_init_proc: Option<PackageInitProc>,
    );
}

pub unsafe fn init_tcl(interp: *mut TclInterp) -> c_int {
    Tcl_Init(interp)
}

pub unsafe fn init_readline(interp: *mut TclInterp, rc_file: &str) -> c_int {
    if tclreadline::Tclreadline_Init(interp.cast()) == TCL_ERROR {
        return TCL_ERROR;
    }

    register_static_package(interp);
    set_rc_file(interp, rc_file);
    eval_init_script(interp)
}

unsafe fn register_static_package(interp: *mut TclInterp) {
    let package = cstring("tclreadline");
    Tcl_StaticPackage(
        interp,
        package.as_ptr(),
        Some(tclreadline_init),
        Some(tclreadline_safe_init),
    );
}

unsafe extern "C" fn tclreadline_init(interp: *mut TclInterp) -> c_int {
    tclreadline::Tclreadline_Init(interp.cast())
}

unsafe extern "C" fn tclreadline_safe_init(interp: *mut TclInterp) -> c_int {
    tclreadline::Tclreadline_SafeInit(interp.cast())
}

unsafe fn set_rc_file(interp: *mut TclInterp, rc_file: &str) {
    let name = cstring("tcl_rcFileName");
    let value = cstring(rc_file);

    Tcl_SetVar(interp, name.as_ptr(), value.as_ptr(), TCL_GLOBAL_ONLY);
}

unsafe fn eval_init_script(interp: *mut TclInterp) -> c_int {
    let path = cstring(format!("{}/tclreadlineInit.tcl", env!("TCLRL_LIBRARY")));
    let status = Tcl_EvalFile(interp, path.as_ptr());
    if status != TCL_OK {
        eprintln!(
            "(TclreadlineAppInit) unable to eval {}",
            path.to_string_lossy()
        );
        std::process::exit(1);
    }

    TCL_OK
}

fn cstring(value: impl AsRef<str>) -> CString {
    CString::new(value.as_ref()).expect("Tcl strings used by wrappers cannot contain NUL")
}
