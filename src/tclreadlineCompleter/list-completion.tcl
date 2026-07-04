# -*- tclsh -*-
# list and option completion primitives.
# Sourced by ../tclreadlineCompleter.tcl.

namespace eval tclreadline {
    proc TryFromList {text lst {allow ""} {inhibit 0}} {

        set pre [GetQuotedPrefix $text]
        set matches [MatchesFromList $text $lst $allow]

        if {1 == [llength $matches]} { ; # unique match
            set null [string index $matches 0]
            if {("<" == $null || "?" == $null)
                    && -1 == [string first $null $allow]} {
                set completion [string trim "[list $text] $lst"]
            } else {
                set completion [string trim ${pre}${matches}[Right $pre]]
            }
            if {$inhibit} {
                return [list $completion {}]
            } else {
                return $completion
            }
        } elseif {"" != $matches} {
            set longest [CompleteLongest $matches]
            if {"" == $longest} {
                return [string trim "[list $text] $matches"]
            } else {
                return [string trim "${pre}${longest} $matches"]
            }
        } else {
            return ""; # nothing to complete
        }
    }

    #**
    # CompleteFromList will never return an empty string.
    # completes, if a completion can be done, or ring
    # the bell if not. If inhibit is non-zero, the result
    # will be formatted such that readline will not insert
    # a space after a complete (single) match.
    #
    proc CompleteFromList {text lst {allow ""} {inhibit 0}} {
        set result [TryFromList $text $lst $allow $inhibit]
        if {![llength $result]} {
            Alert
            # return [string trim [list $text] $lst"]
            if {[llength $lst]} {
                return [string trim "$text $lst"]
            } else {
                return [string trim [list $text {}]]
            }
        } else {
            return $result
        }
    }

    #**
    # CompleteBoolean does a CompleteFromList
    # with a list of all valid boolean values.
    #
    proc CompleteBoolean {text} {
        return [CompleteFromList $text {yes no true false 1 0}]
    }

    #**
    # build a list of all executables which can be
    # found in $env(PATH). This is (naturally) a bit
    # slow, and should not called frequently. Instead
    # it is a good idea to check if the variable
    # `executables' exists and then just use it's
    # content instead of calling Rehash.
    # (see complete(exec)).
    #
    proc Rehash {} {

        global env
        variable executables

        if {![info exists env] || ![array exists env]} {
            return
        }
        if {![info exists env(PATH)]} {
            return
        }

        set executables 0
        foreach dir [split $env(PATH) :] {
            if {[catch [list set files [glob -nocomplain ${dir}/*]]]} { continue }
            foreach file $files {
                if {[file executable $file]} {
                    lappend executables [file tail $file]
                }
            }
        }
    }

    #**
    # build a list hosts from the /etc/hosts file.
    # this is only done once. This is sort of a
    # dirty hack, /etc/hosts is hardcoded ...
    # But on the other side, if the user supplies
    # a valid host table in tclreadline::hosts
    # before entering the event loop, this proc
    # will return this list.
    #
    proc HostList {} {
        # read the host table only once.
        #
        variable hosts
        if {![info exists hosts]} {
            catch {
                set hosts ""
                set id [open /etc/hosts r]
                if {0 != $id} {
                    while {-1 != [gets $id line]} {
                        regsub {#.*} $line {} line
                        if {[llength $line] >= 2} {
                            lappend hosts [lindex $line 1]
                        }
                    }
                    close $id
                }
            }
        }
        return $hosts
    }

    #**
    # never return an empty string, never complete.
    # This is useful for showing options lists for example.
    #
    proc DisplayHints {lst} {
        return [string trim "{} $lst"]
    }

    #**
    # find (partial) matches for `text' in `lst'. Ring
    # the bell and return the whole list, if the user
    # tries to complete ?..? options or <..> hints.
    #
    # MatchesFromList returns a list which is not suitable
    # for passing to the readline completer. Thus,
    # MatchesFromList should not be called directly but
    # from formatting routines as TryFromList.
    #
    proc MatchesFromList {text lst {allow ""}} {
        set result ""
        set text [StripPrefix $text]
        set null [string index $text 0]
        foreach char {< ?} {
            if {$char == $null && -1 == [string first $char $allow]} {
                Alert
                return $lst
            }
        }
        foreach word $lst {
            if {[string match ${text}* $word]} {
                lappend result $word
            }
        }
        return [string trim $result]
    }

    #**
    # invoke cmd with a (hopefully) invalid string and
    # parse the error message to get an option list.
    # The strings are carefully chosen to match the
    # results produced by known tcl routines. It's a
    # pity, that not all object commands generate
    # standard error messages!
    #
    # @param   cmd
    # @return  list of options for cmd
    #
    proc TrySubCmds {text cmd} {

        set trystring ----

        # try the command with and w/o trystring.
        # Some commands, e.g.
        #     .canvas bind
        # return an error if invoked w/o arguments
        # but not, if invoked with arguments. Breaking
        # the loop is eventually done at the end ...
        #
        for {set str $trystring} {1} {set str ""} {

            set code [catch {set result [eval $cmd $str]} msg]
            set result ""

            if {$code} {
                set tcmd [string trim $cmd]
                # XXX see
                #         tclIndexObj.c
                #         tkImgPhoto.c
                # XXX
                if {[regexp \
                         {(bad|ambiguous|unrecognized) .*"----": *must *be( .*$)} \
                         $msg all junk raw]} {
                    regsub -all -- , $raw { } raw
                    set len [llength $raw]
                    set len_2 [expr {$len - 2}]
                    for {set i 0} {$i < $len} {incr i} {
                        set word [lindex $raw $i]
                        if {"or" != $word && $i != $len_2} {
                            lappend result $word
                        }
                    }
                    if {[string length $result]
                            && -1 == [string first $trystring $result]} {
                        return [TryFromList $text $result]
                    }

                } elseif {[regexp \
                               "wrong # args: should be \"?${tcmd}\[^ \t\]*\(.*\[^\"\]\)" \
                               $msg all hint]} {
                    # XXX see tclIndexObj.c XXX
                    if {-1 == [string first $trystring $hint]} {
                        return [DisplayHints [list <[string trim $hint]>]]
                    }
                } else {
                    # check, if it's a blt error msg ...
                    #
                    set msglst [split $msg \n]
                    foreach line $msglst {
                        if {[regexp "${tcmd}\[ \t\]\+\(\[^ \t\]*\)\[^:\]*$" \
                                 $line all sub]} {
                            lappend result [list $sub]
                        }
                    }
                    if {[string length $result]
                            && -1 == [string first $trystring $result]} {
                        return [TryFromList $text $result]
                    }
                }
            }
            if {"" == $str} {
                break
            }
        }
        return ""
    }

    #**
    # try to get classes for commands which
    # allow `configure' (cget).
    # @param  command.
    # @param  optionsT where the table will be stored.
    # @return number of options
    #
    proc ClassTable {cmd} {

        # first we build an option table.
        # We always use `configure' here,
        # because cget will not return the
        # option table.
        #
        if {[catch [list set option_table [eval $cmd configure]] msg]} {
            return ""
        }
        set classes ""
        foreach optline $option_table {
            if {5 != [llength $optline]} {
                continue
            } else {
                lappend classes [lindex $optline 2]
            }
        }
        return $classes
    }

    #**
    # try to get options for commands which
    # allow `configure' (cget).
    # @param command.
    # @param optionsT where the table will be stored.
    # @return number of options
    #
    proc OptionTable {cmd optionsT} {
        upvar $optionsT options
        # first we build an option table.
        # We always use `configure' here,
        # because cget will not return the
        # option table.
        #
        if {[catch [list set option_table [eval $cmd configure]] msg]} {
            return 0
        }
        set retval 0
        foreach optline $option_table {
            if {5 == [llength $optline]} {
                # tk returns a list of length 5
                lappend options(switches) [lindex $optline 0]
                lappend options(value)    [lindex $optline 4]
                incr retval
            } elseif {3 == [llength $optline]} {
                # itcl returns a list of length 3
                lappend options(switches) [lindex $optline 0]
                lappend options(value)    [lindex $optline 2]
                incr retval
            }
        }
        return $retval
    }

    #**
    # try to complete a `cmd configure|cget ..' from the command's options.
    # @param   text start line cmd, standard tclreadlineCompleter arguments.
    # @return  -- a flag indicating, if (cget|configure) was found.
    # @return  resultT -- a tclreadline completer formatted string.
    #
    proc CompleteFromOptions {text start line resultT} {

        upvar $resultT result
        set result ""

        # check if either `configure' or `cget' is present.
        #
        set lst [ProperList $line]
        foreach keyword {configure cget} {
            set idx [lsearch $lst $keyword]
            if {-1 != $idx} {
                break
            }
        }
        if {-1 == $idx} {
            return 0
        }

        if {[regexp {(cget|configure)$} $line]} {
            # we are at the end of (configure|cget)
            # but there's no space yet.
            #
            set result $text
            return 1
        }

        # separate the command, but exclude (cget|configure)
        # because cget won't return the option table. Instead
        # OptionTable always uses `configure' to get the
        # option table.
        #
        set cmd [lrange $lst 0 [expr {$idx - 1}]]

        TraceText $cmd
        if {0 < [OptionTable $cmd options]} {

            set prev [PreviousWord $start $line]
            if {-1 != [set found [lsearch -exact $options(switches) $prev]]} {

                # complete only if the user has not
                # already entered something here.
                #
                if {![llength $text]} {

                    # check first, if the SpecificSwitchCompleter
                    # knows something about this switch. (note that
                    # `prev' contains the switch). The `0' as last
                    # argument makes the SpecificSwitchCompleter
                    # returning "" if it knows nothing specific
                    # about this switch.
                    #
                    set values [SpecificSwitchCompleter \
                                    $text $start $line $prev 0]

                    if [string length $values] {
                        set result $values
                        return 1
                    } else {
                        set val [lindex $options(value) $found]
                        if [string length $val] {
                            # return the old value only, if it's non-empty.
                            # Use this double list to quote option
                            # values which have to be quoted.
                            #
                            set result [list [list $val]]
                        } else {
                            set result ""
                        }
                        return 1
                    }
                } else {
                    set result [SpecificSwitchCompleter \
                                    $text $start $line $prev 1]
                    return 1
                }

            } else {
                set result [CompleteFromList $text \
                                [RemoveUsedOptions $line $options(switches)]]
                return 1
            }
        }
        return 1
    }

    proc ObjectClassCompleter {text start end line pos resultT} {
        upvar $resultT result
        set cmd [Lindex $line 0]
        if {"." == [string index $line 0]} {
            # it's a widget. Try to get it's class name.
            #
            if {![catch [list set class [winfo class [Lindex $line 0]]]]} {
                if {[string length [info proc ${class}Obj]]} {
                    set result [${class}Obj $text $start $end $line $pos]
                    if {[string length $result]} {
                        return 1
                    } else {
                        return 0
                    }
                } else {
                    return 0
                }
            }
        }
        if {![catch {set type [image type $cmd]}]} {
            switch -- $type {
                photo {
                    set result [PhotoObj $text $start $end $line $pos]
                    return 1
                }
                default {
                    # let the fallback completers do the job.
                    return 0
                }
            }
        }
        return 0
    }

    proc CompleteFromOptionsOrSubCmds {text start end line pos} {
        if [CompleteFromOptions $text $start $line from_opts] {
            # always return, if CompleteFromOptions returns non-zero,
            # that means (configure|cget) were present. This ensures
            # that TrySubCmds will not configure something by chance.
            #
            return $from_opts
        } else {
            return [TrySubCmds $text \
                        [lrange [ProperList $line] 0 [expr {$pos - 1}]]]
        }
        return ""
    }

    #**
    # TODO: shit. make this better!
    # @param  text, a std completer argument (current word).
    # @param  fullpart, the full text of the current position.
    # @param  lst, the list to complete from.
    # @param  pre, leading `quote'.
    # @param  sep, word separator.
    # @param  post, trailing `quote'.
    # @return a formatted completer string.
    #
    proc CompleteListFromList {text fullpart lst pre sep post} {

        if {![string length $fullpart]} {

            # nothing typed so far. Insert a $pre
            # and inhibit further completion.
            #
            return [list $pre {}]

        } elseif {$post == [String index $text end]} {

            # finalize, append the post and a space.
            #
            set diff \
                [expr {[CountChar $fullpart $pre] - [CountChar $fullpart $post]}]
            for {set i 0} {$i < $diff} {incr i} {
                append text $post
            }
            append text " "
            return $text

        } elseif {![regexp -- ^\(.*\[${pre}${sep}\]\)\(\[^${pre}${sep}\]*\)$ \
                        $text all left right]} {
            set left {}
            set right $text
        }

        # TraceVar left
        # TraceVar right

        set exact_matches [MatchesFromList $right $lst]
        # TODO this is awkward. Think of making it better!
        #
        if {1 == [llength $exact_matches] && -1 != [lsearch $lst $right]
        } {
            #set completion [CompleteFromList $right [list $sep $post] 1]
            return [list ${left}${right}${sep} {}]
        } else {
            set completion [CompleteFromList $right $lst "" 1]
        }
        if {![string length [lindex $completion 0]]} {
            return [concat [list $left] [lrange $completion 1 end]]
        } elseif {[string length $left]} {
            return [list $left]$completion
        } else {
            return $completion
        }
        return ""
    }

    proc FirstNonOption {line} {
        set expr_pos 1
        foreach word [lrange $line 1 end] {; # 0 is the command itself
            if {"-" != [string index $word 0]} {
                break
            } else {
                incr expr_pos
            }
        }
        return $expr_pos
    }

    proc RemoveUsedOptions {line opts {terminate {}}} {
        if {[llength $terminate]} {
            if {[regexp -- $terminate $line]} {
                return ""
            }
        }
        set new ""
        foreach word $opts {
            if {-1 == [string first $word $line]} {
                lappend new $word
            }
        }

        # check if the last word in the line is an options
        # and if this word is at the very end of the line,
        # that means no space after.
        # If this is so, the word is stuffed into the result,
        # so that it can be completed -- probably with a space.
        #
        set last [Lindex $line end]
        if {[string last $last $line] + [string length $last]
                == [string length $line]} {
            if {-1 != [lsearch $opts $last]} {
                lappend new $last
            }
        }

        return [string trim $new]
    }

    proc Alert {} {
        ::tclreadline::readline bell
    }

    #**
    # get the longest common completion
    # e.g. str == {tcl_version tclreadline_version tclreadline_library}
    # --> [CompleteLongest $str] == "tcl"
    #
    proc CompleteLongest {str} {
        set match0 [lindex $str 0]
        set len0 [string length $match0]
        set no_matches [llength $str]
        set part ""
        for {set i 0} {$i < $len0} {incr i} {
            set char [string index $match0 $i]
            for {set j 1} {$j < $no_matches} {incr j} {
                if {$char != [string index [lindex $str $j] $i]} {
                    break
                }
            }
            if {$j < $no_matches} {
                break
            } else {
                append part $char
            }
        }
        return $part
    }
}
