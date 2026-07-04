# -*- tclsh -*-
# control statement and command dispatch helpers.
# Sourced by ../tclreadlineCompleter.tcl.

namespace eval tclreadline {
    proc CompleteControlStatement {text start end line pos mod pre new_line} {
        set pre [GetQuotedPrefix $pre]
        set cmd [Lindex $new_line 0]
        set diff [expr {[string length $line] - [string length $new_line]}]
        if {$diff == [expr {$start + 1}]} {
            set mod1 $mod
        } else {
            set mod1 $text
            set pre ""
        }
        set new_end [expr {$end - $diff}]
        set new_start [expr {$new_end - [string length $mod1]}]
        if {$new_start < 0} {
            return ""; # when does this occur?
        }
        set res [ScriptCompleter $mod1 $new_start $new_end $new_line]
        if {[string length [Lindex $res 0]]} {
            return ${pre}${res}
        } else {
            return $res
        }
        return ""
    }

    proc BraceOrCommand {text start end line pos mod} {
        if {![string length [Lindex $line $pos]]} {
            return [list \{ {}]; # \}
        } else {
            set new_line [string trim [IncompleteListRemainder $line]]
            if {![regexp {^([\{\"])(.*)$} $new_line all pre new_line]} {
                set pre ""
            }
            return [CompleteControlStatement $text \
                        $start $end $line $pos $mod $pre $new_line]
        }
    }

    proc FullQualifiedMatches {qualifier matchlist} {
        set new ""
        if {"" != $qualifier && ![regexp ::$ $qualifier]} {
            append qualifier ::
        }
        foreach entry $matchlist {
            set full ${qualifier}${entry}
            if {"" != [namespace which $full]} {
                lappend new $full
            }
        }
        return $new
    }

    proc ProcsOnlyCompletion {cmd} {
        return [CommandCompletion $cmd procs]
    }

    proc CommandsOnlyCompletion {cmd} {
        return [CommandCompletion $cmd commands]
    }

    proc CommandCompletion {cmd {action both} {spc ::}} {
        # get the leading colons in `cmd'.
        regexp {^:*} $cmd pre
        return [CommandCompletionWithPre $cmd $action $spc $pre]
    }

    proc CommandCompletionWithPre {cmd action spc pre} {
        set cmd [StripPrefix $cmd]
        set quali [namespace qualifiers $cmd]
        if {[string length $quali]} {
            set matches [CommandCompletionWithPre \
                             [namespace tail $cmd] $action ${spc}${quali} $pre]
            return $matches
        }
        set cmd [string trim $cmd]*
        if {"procs" != $action} {
            set all_commands [namespace eval $spc [list info commands $cmd]]
            set commands ""
            foreach command $all_commands {
                if {[namespace eval $spc [list namespace origin $command]]
                        == [namespace eval $spc [list namespace which $command]]} {
                    lappend commands $command
                }
            }
        } else {
            set commands ""
        }
        if {"commands" != $action} {
            set all_procs [namespace eval $spc [list info procs $cmd]]
            set procs ""
            foreach proc $all_procs {
                if {[namespace eval $spc [list namespace origin $proc]]
                        == [namespace eval $spc [list namespace which $proc]]} {
                    lappend procs $proc
                }
            }
        } else {
            set procs ""
        }
        set matches [namespace eval $spc concat $commands $procs]
        set namespaces [namespace children $spc $cmd]

        if {![llength $matches] && 1 == [llength $namespaces]} {
            set matches [CommandCompletionWithPre {} $action $namespaces $pre]
            return $matches
        }

        # make `namespaces' having exactly
        # the same number of colons as `cmd'.
        #
        regsub -all {^:*} $spc $pre spc

        set matches [FullQualifiedMatches $spc $matches]
        return [string trim "$matches $namespaces"]
    }

    #**
    # check, if the first argument starts with a '['
    # and must be evaluated before continuing.
    # NOTE: trims the `line'.
    #       eventually modifies all arguments.
    #
    proc EventuallyEvaluateFirst {partT startT endT lineT} {
        # return; # disabled
        upvar $partT part $startT start $endT end $lineT line

        set oldlen [string length $line]
        # set line [string trim $line]
        set line [string trimleft $line]
        set diff [expr {[string length $line] - $oldlen}]
        incr start $diff
        incr end $diff

        set char [string index $line 0]
        if {{[} != $char && {$} != $char} {return}

        set pos 0
        while {-1 != [set idx [string first {]} $line $pos]]} {
            set cmd [string range $line 0 $idx]
            if {[info complete $cmd]} {
                break;
            }
            set pos [expr {$idx + 1}]
        }

        if {![info exists cmd]} {return}
        if {![info complete $cmd]} {return}
        set cmd [string range $cmd 1 [expr {[string length $cmd] - 2}]]
        set rest [String range $line [expr {$idx + 1}] end]

        if {[catch [list set result [string trim [eval $cmd]]]]} {return}

        set line ${result}${rest}
        set diff [expr {[string length $result] - ([string length $cmd] + 2)}]
        incr start $diff
        incr end $diff
    }

    # if the line entered so far is
    # % puts $b<TAB>
    # part  == $b
    # start == 5
    # end   == 7
    # line  == "$puts $b"
}
