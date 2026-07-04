use std::collections::HashMap;
use std::env;
use std::fs;
use std::path::PathBuf;
use std::process::Command;

fn main() {
    println!("cargo:rustc-check-cfg=cfg(has_rl_cleanup_after_signal)");
    println!("cargo:rustc-check-cfg=cfg(has_rl_extend_line_buffer)");
    println!("cargo:rustc-check-cfg=cfg(use_tcl_stubs)");
    println!("cargo:rerun-if-env-changed=PREFIX");
    println!("cargo:rerun-if-env-changed=TCL_CONFIG");
    println!("cargo:rerun-if-env-changed=TK_CONFIG");
    println!("cargo:rerun-if-env-changed=TCLRL_LIBDIR");
    println!("cargo:rerun-if-env-changed=TCLRL_LIBRARY");
    println!("cargo:rerun-if-env-changed=TCLREADLINE_USE_TCL_STUBS");
    println!("cargo:rerun-if-env-changed=TCL_LIB_SPEC");
    println!("cargo:rerun-if-env-changed=TCL_STUB_LIB_SPEC");
    println!("cargo:rerun-if-env-changed=TK_LIB_SPEC");
    println!("cargo:rerun-if-env-changed=READLINE_LIB_SPEC");

    let tcl = read_config("TCL_CONFIG", "tclConfig.sh", &default_config_dirs());
    let use_tcl_stubs = env::var_os("TCLREADLINE_USE_TCL_STUBS").is_some();
    if use_tcl_stubs {
        println!("cargo:rustc-cfg=use_tcl_stubs");
    }

    let prefix = env::var("PREFIX")
        .ok()
        .or_else(|| tcl.get("TCL_PREFIX").cloned())
        .unwrap_or_else(|| "/usr/local".to_string());
    let libdir = env::var("TCLRL_LIBDIR").unwrap_or_else(|_| format!("{prefix}/lib"));
    let package_dir = env::var("TCLRL_LIBRARY").unwrap_or_else(|_| {
        format!(
            "{libdir}/tclreadline{}",
            major_minor(env!("CARGO_PKG_VERSION"))
        )
    });
    println!("cargo:rustc-env=TCLRL_LIBRARY={package_dir}");
    println!("cargo:rustc-link-arg=-Wl,-rpath,{libdir}");

    let tcl_spec = if use_tcl_stubs {
        spec_from_env_or_config("TCL_STUB_LIB_SPEC", &tcl)
    } else {
        spec_from_env_or_config("TCL_LIB_SPEC", &tcl)
    };
    emit_link_spec(&tcl_spec);

    if env::var_os("CARGO_FEATURE_WISHRL").is_some() {
        let tk = read_config("TK_CONFIG", "tkConfig.sh", &default_config_dirs());
        emit_link_spec(&spec_from_env_or_config("TK_LIB_SPEC", &tk));
    }

    let readline_spec = env::var("READLINE_LIB_SPEC").unwrap_or_else(|_| "-lreadline".to_string());
    emit_link_spec(&readline_spec);
    emit_readline_cfgs(&readline_spec);
}

fn default_config_dirs() -> Vec<PathBuf> {
    [
        "/usr/lib",
        "/usr/lib64",
        "/usr/local/lib",
        "/usr/local/lib/unix",
        "/opt/tcl/lib",
    ]
    .into_iter()
    .map(PathBuf::from)
    .collect()
}

fn read_config(env_name: &str, file_name: &str, dirs: &[PathBuf]) -> HashMap<String, String> {
    let path = env::var(env_name)
        .ok()
        .map(PathBuf::from)
        .or_else(|| {
            dirs.iter()
                .map(|dir| dir.join(file_name))
                .find(|path| path.exists())
        })
        .unwrap_or_else(|| {
            panic!("could not find {file_name}; set {env_name}=/path/to/{file_name}")
        });

    println!("cargo:rerun-if-changed={}", path.display());
    parse_shell_assignments(&fs::read_to_string(&path).expect("failed to read config file"))
}

fn parse_shell_assignments(input: &str) -> HashMap<String, String> {
    let mut vars = HashMap::new();
    for line in input.lines() {
        let trimmed = line.trim();
        if trimmed.is_empty() || trimmed.starts_with('#') {
            continue;
        }
        let Some((key, value)) = trimmed.split_once('=') else {
            continue;
        };
        if !key
            .chars()
            .all(|ch| ch == '_' || ch.is_ascii_alphanumeric())
        {
            continue;
        }
        vars.insert(key.to_string(), unquote(value.trim()));
    }
    vars
}

fn unquote(value: &str) -> String {
    let bytes = value.as_bytes();
    if bytes.len() >= 2
        && ((bytes[0] == b'\'' && bytes[bytes.len() - 1] == b'\'')
            || (bytes[0] == b'"' && bytes[bytes.len() - 1] == b'"'))
    {
        value[1..value.len() - 1].to_string()
    } else {
        value.to_string()
    }
}

fn spec_from_env_or_config(name: &str, config: &HashMap<String, String>) -> String {
    env::var(name)
        .ok()
        .or_else(|| config.get(name).cloned())
        .unwrap_or_else(|| panic!("{name} was not provided by environment or config file"))
}

fn emit_link_spec(spec: &str) {
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

fn emit_readline_cfgs(readline_spec: &str) {
    if probe_link(
        "rl_cleanup_after_signal",
        "extern void rl_cleanup_after_signal(void); rl_cleanup_after_signal();",
        readline_spec,
    ) {
        println!("cargo:rustc-cfg=has_rl_cleanup_after_signal");
    }
    if probe_link(
        "rl_extend_line_buffer",
        "extern void rl_extend_line_buffer(int); rl_extend_line_buffer(1);",
        readline_spec,
    ) {
        println!("cargo:rustc-cfg=has_rl_extend_line_buffer");
    }
}

fn probe_link(name: &str, body: &str, link_spec: &str) -> bool {
    let out_dir = PathBuf::from(env::var_os("OUT_DIR").expect("OUT_DIR missing"));
    let source = out_dir.join(format!("{name}.c"));
    let output = out_dir.join(format!("{name}.probe"));
    let program = format!("int main(void) {{ {body} return 0; }}\n");
    fs::write(&source, program).expect("failed to write probe source");

    let mut command = Command::new(env::var("CC").unwrap_or_else(|_| "cc".to_string()));
    command.arg(&source).arg("-o").arg(&output);
    for token in link_spec.split_whitespace() {
        command.arg(token);
    }

    command
        .status()
        .map(|status| status.success())
        .unwrap_or(false)
}

fn major_minor(version: &str) -> String {
    let mut parts = version.split('.');
    match (parts.next(), parts.next()) {
        (Some(major), Some(minor)) => format!("{major}.{minor}"),
        _ => version.to_string(),
    }
}
