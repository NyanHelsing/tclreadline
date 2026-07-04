use std::env;
use std::fs;

fn main() {
    println!("cargo:rustc-check-cfg=cfg(has_rl_cleanup_after_signal)");
    println!("cargo:rustc-check-cfg=cfg(has_rl_extend_line_buffer)");
    println!("cargo:rustc-check-cfg=cfg(use_tcl_stubs)");
    println!("cargo:rerun-if-env-changed=CONFIG_H");
    println!("cargo:rerun-if-env-changed=TCLREADLINE_LIB_DIR");
    println!("cargo:rerun-if-env-changed=TCLRL_LIBDIR");
    println!("cargo:rerun-if-env-changed=TCLRL_LIBRARY");
    println!("cargo:rerun-if-env-changed=TCLREADLINE_LINK_SELF");
    println!("cargo:rerun-if-env-changed=TCLREADLINE_USE_TCL_STUBS");
    println!("cargo:rerun-if-env-changed=TCL_LIB_SPEC");
    println!("cargo:rerun-if-env-changed=TK_LIB_SPEC");
    println!("cargo:rerun-if-env-changed=READLINE_LIB_SPEC");

    emit_config_cfgs();

    if let Ok(dir) = env::var("TCLREADLINE_LIB_DIR") {
        println!("cargo:rustc-link-search=native={dir}");
    }
    if let Ok(dir) = env::var("TCLRL_LIBDIR") {
        println!("cargo:rustc-link-arg=-Wl,-rpath,{dir}");
    }
    if let Ok(dir) = env::var("TCLRL_LIBRARY") {
        println!("cargo:rustc-env=TCLRL_LIBRARY={dir}");
    }

    let link_wrappers = env::var("TCLREADLINE_LINK_SELF").is_ok();
    if link_wrappers {
        println!("cargo:rustc-link-lib=tclreadline");
        emit_bin_link_arg("-ltclreadline");
    }
    emit_link_spec("TCL_LIB_SPEC", link_wrappers);
    emit_link_spec("TK_LIB_SPEC", link_wrappers);
    emit_link_spec("READLINE_LIB_SPEC", link_wrappers);
}

fn emit_config_cfgs() {
    let path = env::var("CONFIG_H").unwrap_or_else(|_| "config.h".to_string());
    println!("cargo:rerun-if-changed={path}");

    if let Ok(config) = fs::read_to_string(&path) {
        if config.contains("#define CLEANUP_AFER_SIGNAL 1") {
            println!("cargo:rustc-cfg=has_rl_cleanup_after_signal");
        }
        if config.contains("#define EXTEND_LINE_BUFFER 1") {
            println!("cargo:rustc-cfg=has_rl_extend_line_buffer");
        }
    }

    if env::var("TCLREADLINE_USE_TCL_STUBS").is_ok() {
        println!("cargo:rustc-cfg=use_tcl_stubs");
    }
}

fn emit_link_spec(name: &str, emit_for_bins: bool) {
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
                if emit_for_bins {
                    emit_bin_link_arg(token);
                }
            }
        } else if token.starts_with("-Wl,") {
            println!("cargo:rustc-link-arg={token}");
            if emit_for_bins {
                emit_bin_link_arg(token);
            }
        }
    }
}

fn emit_bin_link_arg(flag: &str) {
    println!("cargo:rustc-link-arg-bin=tclshrl={flag}");
    println!("cargo:rustc-link-arg-bin=wishrl={flag}");
}
