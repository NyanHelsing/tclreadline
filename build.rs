use std::env;

fn main() {
    println!("cargo:rerun-if-env-changed=TCLREADLINE_LIB_DIR");
    println!("cargo:rerun-if-env-changed=TCLRL_LIBDIR");
    println!("cargo:rerun-if-env-changed=TCLRL_LIBRARY");
    println!("cargo:rerun-if-env-changed=TCL_LIB_SPEC");
    println!("cargo:rerun-if-env-changed=TK_LIB_SPEC");

    if let Ok(dir) = env::var("TCLREADLINE_LIB_DIR") {
        println!("cargo:rustc-link-search=native={dir}");
    }
    if let Ok(dir) = env::var("TCLRL_LIBDIR") {
        println!("cargo:rustc-link-arg=-Wl,-rpath,{dir}");
    }
    if let Ok(dir) = env::var("TCLRL_LIBRARY") {
        println!("cargo:rustc-env=TCLRL_LIBRARY={dir}");
    }

    println!("cargo:rustc-link-lib=tclreadline");
    emit_link_spec("TCL_LIB_SPEC");
    emit_link_spec("TK_LIB_SPEC");
}

fn emit_link_spec(name: &str) {
    let Ok(spec) = env::var(name) else {
        return;
    };

    for token in spec.split_whitespace() {
        if let Some(path) = token.strip_prefix("-L") {
            if !path.is_empty() {
                println!("cargo:rustc-link-search=native={path}");
                println!("cargo:rustc-link-arg=-Wl,-rpath,{path}");
            }
        } else if let Some(lib) = token.strip_prefix("-l") {
            if !lib.is_empty() {
                println!("cargo:rustc-link-lib={lib}");
            }
        } else if token.starts_with("-Wl,") {
            println!("cargo:rustc-link-arg={token}");
        }
    }
}
