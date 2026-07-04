#!/usr/bin/env tclsh

proc usage {} {
    puts stderr "usage: tools/install.tcl ?--prefix DIR? ?--destdir DIR? ?--tcl-config FILE? ?--tk-config FILE? ?--with-wish? ?--debug?"
    exit 2
}

proc optionValue {argvVar indexVar} {
    upvar 1 $argvVar argv $indexVar index
    incr index
    if {$index >= [llength $argv]} {
        usage
    }
    return [lindex $argv $index]
}

proc shellUnquote {value} {
    set value [string trim $value]
    if {[string length $value] >= 2} {
        set first [string index $value 0]
        set last [string index $value end]
        if {($first eq "'" && $last eq "'") || ($first eq "\"" && $last eq "\"")} {
            return [string range $value 1 end-1]
        }
    }
    return $value
}

proc readShellConfig {path} {
    set fp [open $path r]
    set data [read $fp]
    close $fp

    set vars [dict create]
    foreach line [split $data \n] {
        set line [string trim $line]
        if {$line eq "" || [string index $line 0] eq "#"} {
            continue
        }
        if {[regexp {^([A-Za-z_][A-Za-z0-9_]*)=(.*)$} $line -> key value]} {
            dict set vars $key [shellUnquote $value]
        }
    }
    return $vars
}

proc findConfig {name option explicit} {
    if {$explicit ne ""} {
        return [file normalize $explicit]
    }
    foreach dir {/usr/lib /usr/lib64 /usr/local/lib /usr/local/lib/unix /opt/tcl/lib} {
        set path [file join $dir $name]
        if {[file exists $path]} {
            return [file normalize $path]
        }
    }
    error "could not find $name; pass $option FILE"
}

proc cargoVersion {root} {
    set fp [open [file join $root Cargo.toml] r]
    set data [read $fp]
    close $fp
    if {![regexp -line {^version = "([^"]+)"} $data -> version]} {
        error "could not read package version from Cargo.toml"
    }
    return $version
}

proc versionPart {version index} {
    return [lindex [split $version .] $index]
}

proc majorMinor {version} {
    return "[versionPart $version 0].[versionPart $version 1]"
}

proc renderTemplate {source dest replacements} {
    set fp [open $source r]
    set data [read $fp]
    close $fp

    foreach {key value} $replacements {
        set data [string map [list @$key@ $value] $data]
    }

    file mkdir [file dirname $dest]
    set fp [open $dest w]
    puts -nonewline $fp $data
    close $fp
}

proc installFile {source dest} {
    file mkdir [file dirname $dest]
    file copy -force $source $dest
}

array set opt {
    prefix ""
    destdir ""
    tcl-config ""
    tk-config ""
    readline-lib-spec "-lreadline"
    release 1
    tclshrl 1
    wishrl 0
}

for {set i 0} {$i < [llength $argv]} {incr i} {
    set arg [lindex $argv $i]
    switch -- $arg {
        --prefix { set opt(prefix) [optionValue argv i] }
        --destdir { set opt(destdir) [optionValue argv i] }
        --tcl-config { set opt(tcl-config) [optionValue argv i] }
        --tk-config { set opt(tk-config) [optionValue argv i] }
        --readline-lib-spec { set opt(readline-lib-spec) [optionValue argv i] }
        --with-wish { set opt(wishrl) 1 }
        --without-tclshrl { set opt(tclshrl) 0 }
        --debug { set opt(release) 0 }
        -h -
        --help { usage }
        default { usage }
    }
}

set root [file normalize [file join [file dirname [info script]] ..]]
set version [cargoVersion $root]
set tclConfig [findConfig tclConfig.sh --tcl-config $opt(tcl-config)]
set tclVars [readShellConfig $tclConfig]

if {$opt(prefix) eq ""} {
    if {[dict exists $tclVars TCL_PREFIX]} {
        set opt(prefix) [dict get $tclVars TCL_PREFIX]
    } else {
        set opt(prefix) /usr/local
    }
}

set libdir [file join $opt(prefix) lib]
set pkgdir [file join $libdir tclreadline[majorMinor $version]]
set bindir [file join $opt(prefix) bin]
set includedir [file join $opt(prefix) include]
set mandir [file join $opt(prefix) share man mann]

set env(PREFIX) $opt(prefix)
set env(TCL_CONFIG) $tclConfig
set env(TCLRL_LIBDIR) $libdir
set env(TCLRL_LIBRARY) $pkgdir
set env(READLINE_LIB_SPEC) $opt(readline-lib-spec)

set cargo [list cargo build --manifest-path [file join $root Cargo.toml]]
if {$opt(release)} {
    lappend cargo --release
    set profile release
} else {
    set profile debug
}
lappend cargo --lib
if {$opt(tclshrl)} {
    lappend cargo --bin tclshrl
}
if {$opt(wishrl)} {
    set tkConfig [findConfig tkConfig.sh --tk-config $opt(tk-config)]
    set env(TK_CONFIG) $tkConfig
    lappend cargo --features wishrl --bin wishrl
}

puts [join $cargo " "]
exec {*}$cargo >@ stdout 2>@ stderr

set targetDir [file join $root target $profile]
set destPrefix "$opt(destdir)$opt(prefix)"
set destLibdir "$opt(destdir)$libdir"
set destPkgdir "$opt(destdir)$pkgdir"
set destBindir "$opt(destdir)$bindir"
set destIncludedir "$opt(destdir)$includedir"
set destMandir "$opt(destdir)$mandir"
set exe [expr {$::tcl_platform(platform) eq "windows" ? ".exe" : ""}]

installFile [file join $targetDir libtclreadline[info sharedlibextension]] \
    [file join $destLibdir libtclreadline[info sharedlibextension]]
if {$opt(tclshrl)} {
    installFile [file join $targetDir tclshrl$exe] [file join $destBindir tclshrl$exe]
}
if {$opt(wishrl)} {
    installFile [file join $targetDir wishrl$exe] [file join $destBindir wishrl$exe]
}

set replacements [list \
    VERSION $version \
    PATCHLEVEL_STR $version \
    MAJOR [versionPart $version 0] \
    MINOR [versionPart $version 1] \
    PATCHLEVEL [versionPart $version 2] \
    TCLRL_DIR $pkgdir \
    TCLRL_LIBDIR $libdir]

renderTemplate [file join $root pkgIndex.tcl.in] [file join $destPkgdir pkgIndex.tcl] $replacements
renderTemplate [file join $root tclreadlineInit.tcl.in] [file join $destPkgdir tclreadlineInit.tcl] $replacements
renderTemplate [file join $root tclreadlineSetup.tcl.in] [file join $destPkgdir tclreadlineSetup.tcl] $replacements
renderTemplate [file join $root tclreadline.n.in] [file join $destMandir tclreadline.n] $replacements
renderTemplate [file join $root src tclreadline.h.in] [file join $destIncludedir tclreadline.h] $replacements
installFile [file join $root src tclreadlineCompleter.tcl] [file join $destPkgdir tclreadlineCompleter.tcl]

puts "installed tclreadline $version to $destPrefix"
