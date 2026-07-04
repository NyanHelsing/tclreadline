# -*- tclsh -*-
# namespace variables, exports, and tracing hooks.
# Sourced by ../tclreadlineCompleter.tcl.

namespace eval tclreadline {

    # the following three are from the icccm
    # and used in complete(selection) and
    # descendants.
    #
    variable selection-selections {
        PRIMARY SECONDARY CLIPBOARD
    }
    variable selection-types {
        ADOBE_PORTABLE_DOCUMENT_FORMAT
        APPLE_PICT
        BACKGROUND
        BITMAP
        CHARACTER_POSITION
        CLASS
        CLIENT_WINDOW
        COLORMAP
        COLUMN_NUMBER
        COMPOUND_TEXT
        DELETE
        DRAWABLE
        ENCAPSULATED_POSTSCRIPT
        ENCAPSULATED_POSTSCRIPT_INTERCHANGE
        FILE_NAME
        FOREGROUND
        HOST_NAME
        INSERT_PROPERTY
        INSERT_SELECTION
        LENGTH
        LINE_NUMBER
        LIST_LENGTH
        MODULE
        MULTIPLE
        NAME
        ODIF
        OWNER_OS
        PIXMAP
        POSTSCRIPT
        PROCEDURE
        PROCESS
        STRING
        TARGETS
        TASK
        TEXT
        TIMESTAMP
        USER
    }
    variable selection-formats {
        APPLE_PICT
        ATOM
        ATOM_PAIR
        BITMAP
        COLORMAP
        COMPOUND_TEXT
        DRAWABLE
        INTEGER
        NULL
        PIXEL
        PIXMAP7
        SPAN
        STRING
        TEXT
        WINDOW
    }

    namespace export \
        TryFromList CompleteFromList DisplayHints Rehash \
        PreviousWord CommandCompletion RemoveUsedOptions \
        HostList ChannelId InChannelId OutChannelId \
        Lindex Llength CompleteBoolean WidgetChildren

    # set tclreadline::trace to 1, if you
    # want to enable explicit trace calls.
    #
    variable trace

    # set tclreadline::trace_procs to 1, if you
    # want to enable tracing every entry to a proc.
    #
    variable trace_procs

    if {[info exists trace_procs] && $trace_procs} {
        ::proc proc {name arguments body} {
            ::proc $name $arguments [subst -nocommands {
                TraceText [lrange [info level 0] 1 end]
                $body
            }]
        }
    } else { ;# !$trace_procs
        catch {rename ::tclreadline::proc ""}
    }

    if {[info exists trace] && $trace} {

        ::proc TraceReconf {args} {
            eval .tclreadline_trace.scroll set $args
            .tclreadline_trace.text see end
        }

        ::proc AssureTraceWindow {} {
            variable trace
            if {![info exists trace]} {
                return 0
            }
            if {!$trace} {
                return 0
            }
            if {[catch {package require Tk}]} {
                return 0
            }
            if {![winfo exists .tclreadline_trace.text]} {
                toplevel .tclreadline_trace
                text .tclreadline_trace.text \
                    -yscrollcommand { tclreadline::TraceReconf } \
                    -wrap none
                scrollbar .tclreadline_trace.scroll \
                    -orient vertical \
                    -command { .tclreadline_trace.text yview }
                pack .tclreadline_trace.text -side left -expand yes -fill both
                pack .tclreadline_trace.scroll -side right -expand yes -fill y
            } else {
                raise .tclreadline_trace
            }
            return 1
        }

        ::proc TraceVar vT {
            if {![AssureTraceWindow]} {
                return
            }
            upvar $vT v
            if {[info exists v]} {
                .tclreadline_trace.text insert end \
                    "([lindex [info level -1] 0]) $vT=|$v|\n"
            }
            # silently ignore unset variables.
        }

        ::proc TraceText txt {
            if {![AssureTraceWindow]} {
                return
            }
            .tclreadline_trace.text insert end \
                [format {%32s %s} ([lindex [info level -1] 0]) $txt\n]
        }

    } else {
        ::proc TraceReconf args {}
        ::proc AssureTraceWindow args {}
        ::proc TraceVar args {}
        ::proc TraceText args {}
    }

    #**
    # TryFromList will return an empty string, if
    # the text typed so far does not match any of the
    # elements in list. This might be used to allow
    # subsequent filename completion by the builtin
    # completer.
    # If inhibit is non-zero, the result will be
    # formatted such that readline will not insert
    # a space after a complete (single) match.
}
