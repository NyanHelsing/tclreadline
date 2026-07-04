# -*- tclsh -*-
# FILE: tclreadlineCompleter.tcl
# Compatibility loader for the tclreadline completer modules.

namespace eval ::tclreadline {}
set ::tclreadline::completer_dir [file join [file dirname [info script]] tclreadlineCompleter]
foreach ::tclreadline::completer_module {
    bootstrap.tcl
    list-completion.tcl
    parse.tcl
    script-control.tcl
    script-dispatch.tcl
    commands-core.tcl
    commands-packages.tcl
    commands-language.tcl
    tk-common.tcl
    tk-commands.tcl
    tk-widgets.tcl
} {
    source [file join $::tclreadline::completer_dir $::tclreadline::completer_module]
}
unset ::tclreadline::completer_module
