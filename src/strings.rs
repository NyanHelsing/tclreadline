use std::ffi::{c_char, CStr, CString};

use crate::ffi;

pub fn blank_line(s: &CStr) -> bool {
    s.to_bytes().iter().all(|c| is_white(*c))
}

pub fn stripwhite_cstring(s: &CStr) -> CString {
    let trimmed = trim_ascii_space(s.to_bytes());
    CString::new(trimmed).expect("trimmed C string cannot contain NUL")
}

pub fn quote_for_tcl(ptr: *const c_char, quotechars: &[u8]) -> *mut c_char {
    if ptr.is_null() {
        return std::ptr::null_mut();
    }
    let bytes = unsafe { CStr::from_ptr(ptr).to_bytes() };
    let mut out = Vec::with_capacity(bytes.len());
    for byte in bytes {
        if quotechars.contains(byte) {
            out.push(b'\\');
        }
        out.push(*byte);
    }
    unsafe { ffi::alloc_c_string(&out) }
}

pub fn parse_words(line: &CStr) -> Vec<CString> {
    line.to_bytes()
        .split(is_white_ref)
        .filter(|part| !part.is_empty())
        .map(|part| CString::new(part).expect("word from CStr cannot contain NUL"))
        .collect()
}

fn trim_ascii_space(bytes: &[u8]) -> &[u8] {
    let start = bytes.iter().position(|c| *c > b' ').unwrap_or(bytes.len());
    let end = bytes
        .iter()
        .rposition(|c| *c > b' ')
        .map(|idx| idx + 1)
        .unwrap_or(start);
    &bytes[start..end]
}

fn is_white(byte: u8) -> bool {
    matches!(byte, b' ' | b'\t' | b'\n')
}

fn is_white_ref(byte: &u8) -> bool {
    is_white(*byte)
}
