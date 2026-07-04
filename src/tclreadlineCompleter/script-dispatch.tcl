# -*- tclsh -*-
# top-level script completer dispatcher.
# Sourced by ../tclreadlineCompleter.tcl.

namespace eval tclreadline {
    proc ScriptCompleter {part start end line} {

        # if the character before the cursor is a terminating
        # quote and the user wants completion, we insert a white
        # space here.
        #
        set char [string index $line [expr {$end - 1}]]
        if {"\}" == $char} {
            append $part " "
            return [list $part]
        }

        if {{$} == [string index $part 0]} {

            # check for a !$ history event
            #
            if {$start > 0} {
                if {{!} == [string index $line [expr {$start - 1}]]} {
                    return ""
                }
            }
            # variable completion. Check first, if the
            # variable starts with a plain `$' or should
            # be enclosed in braces.
            #
            set var [String range $part 1 end]

            # check if $var is an array name, which
            # already has already a "(" somewhere inside.
            #
            if {"" != [set vc [VarCompletion $var]]} {
                if {"" == [lindex $vc 0]} {
                    return "\$ [lrange $vc 1 end]"
                } else {
                    return \$${vc}
                }
            } else {
                return ""
            }

        # SCENARIO:
        #
        # % puts bla; put<TAB> $b
        # part  == put
        # start == 10
        # end   == 13
        # line  == "puts bla; put $b"
        # [SplitLine] --> {1 " put $b"} == sub
        # new_start = [lindex $sub 0] == 1
        # new_end   = [expr {$end - ($start - $new_start)}] == 4
        # new_part  == $part == put
        # new_line  = [lindex $sub 1] == " put $b"
        #
        } elseif {"" != [set sub [SplitLine $start $line]]} {

            set new_start [lindex $sub 0]
            set new_end [expr {$end - ($start - $new_start)}]
            set new_line [lindex $sub 1]
            return [ScriptCompleter $part $new_start $new_end $new_line]

        } elseif {0 == [set pos [PartPosition part start end line]]} {

            # XXX
            #     note that line will be [string trimleft'ed]
            #     after PartPosition.
            # XXX

            set all [CommandCompletion $part]
            # return [Format $all $part]
            return [TryFromList $part $all]

        } else {

            # try to use $pos further ...
            #
            # if {"." == [string index [string trim $line] 0]} {
            #   set alias WIDGET
            #   set namespc ""; # widgets are always in the global
            # } else {

                # the double `lindex' strips {} or quotes.
                # the subst enables variables containing
                # command names.
                #
                set alias [uplevel [info level] \
                               subst [lindex [lindex [QuoteQuotes $line] 0] 0]]

                # make `alias' a fully qualified name.
                # this can raise an error, if alias is
                # no valid command.
                #
                if {[catch {set alias [namespace origin $alias]}]} {
                    return ""
                }

                set full_path $alias

                # strip leading ::'s.
                #
                regsub -all {^::} $alias {} alias
                set namespc [namespace qualifiers $alias]
                set alias [namespace tail $alias]
            # }

            # try first a specific completer, then an OO completer if
            # appropriate, then, and only then, tclreadline_complete_unknown.
            #
            set completers [list $alias tclreadline_complete_unknown]
            set is_object 0
            if {![catch {package present TclOO 1.0}]} {
                if {[info object isa object $full_path]} {
                    set completers [linsert $completers 1 _tcloo]
                    set is_object 1
                }
            }
            if {![catch {package present Itcl 3.0}] ||
                    ![catch {package present itcl 4.0}]} {
                if {[::itcl::find objects $full_path] eq $full_path} {
                    set completers [linsert $completers 1 _itcl]
                    set is_object 1
                }
            }

            foreach cmd $completers {
                # Set the namespace for the current command. This is to make it
                # possible for generic object completers, which are defined in
                # ::tclreadline, to coexist with the hypothetical future
                # completers for specific objects defined in
                # ::tclreadline::somepackage.
                set namespc_cc $namespc
                if {$is_object && [string match _* $cmd]} {
                    set namespc_cc ""
                }

                if {"" != [namespace eval \
                        ::tclreadline::${namespc_cc} \
                                [list info procs complete($cmd)]]} {
                    # to be more error-proof, we check here,
                    # if complete($cmd) takes exactly 5 arguments.
                    #
                    if {6 != [set arguments \
                            [llength \
                                    [namespace eval ::tclreadline::${namespc_cc} \
                                            [list info args complete($cmd)]]]]} {
                        error "complete($cmd) takes $arguments arguments,\
                                but should take exactly 6"
                    }

                    # remove leading quotes
                    #
                    set mod [StripPrefix $part]

                    if {[catch {set script_result \
                            [namespace eval ::tclreadline::${namespc_cc} \
                                    [list complete($cmd) $part $start $end $line $pos $mod]]} \
                                    ::tclreadline::errorMsg]} {
                        error "error during evaluation of `complete($cmd)'"
                    }
                    if {![string length $script_result]
                            && "tclreadline_complete_unknown" == $cmd} {
                        # as we're here, the tclreadline_complete_unknown
                        # returned an empty string. Fall thru and try
                        # further fallback completers.
                        #
                    } else {
                        # return also empty strings, if
                        # they're from a specific completer.
                        #
                        TraceText script_result=|$script_result|
                        return $script_result
                    }
                }
                # set namespc ""; # no qualifiers for tclreadline_complete_unknown
            }

            # as we've reached here no valid specific completer
            # was found. Check, if it's a proc and return the
            # arguments.
            #
            if {![string length $namespc]} {
                set namespc ::
            }
            if {[string length [uplevel [info level] \
                                    namespace eval $namespc [list ::info proc $alias]]]} {
                if ![string length [string trim $part]] {
                    set args [uplevel [info level] \
                                  namespace eval $namespc [list info args $alias]]
                    set arg [lindex $args [expr {$pos - 1}]]
                    if {"" != $arg && "args" != $arg} {
                        if {[uplevel [info level] namespace eval \
                                 $namespc [list info default $alias $arg junk]]} {
                            return [DisplayHints ?$arg?]
                        } else {
                            return [DisplayHints <$arg>]
                        }
                    }
                } else {
                    return ""; # enable file name completion
                }
            }

            # check if the command is an object of known class.
            #
            if [ObjectClassCompleter $part $start $end $line $pos res] {
                return $res
            }

            # Ok, also no proc. Try to do the same as for widgets now:
            # try to complete from the option table if the subcommand
            # is `configure' or `cget' otherwise try to get further
            # subcommands.
            #
            return [CompleteFromOptionsOrSubCmds \
                        $part $start $end $line $pos]
        }
        error "{NOTREACHED (this is probably an error)}"
    }


    # explicit command completers
    #

    # -------------------------------------
    #                 TCL
    # -------------------------------------
}
