# -*- tclsh -*-
# line parsing, quoting, and command lookup helpers.
# Sourced by ../tclreadlineCompleter.tcl.

namespace eval tclreadline {
    proc SplitLine {start line} {
        set depth 0
        for {set i $start} {$i >= 0} {incr i -1} {
            set c [string index $line $i]
            if {{;} == $c} {
                incr i; # discard command break character
                return [list [expr {$start - $i}] [String range $line $i end]]
            } elseif {{]} == $c} {
                incr depth
            } elseif {{[} == $c} {
                incr depth -1
                if {$depth < 0} {
                    incr i; # discard command break character
                    return [list [expr {$start - $i}] [String range $line $i end]]
                }
            }
        }
        return ""
    }

    proc IsWhite {char} {
        if {" " == $char || "\n" == $char || "\t" == $char} {
            return 1
        } else {
            return 0
        }
    }

    proc PreviousWordOfIncompletePosition {start line} {
        return [lindex [ProperList [string range $line 0 $start]] end]
    }

    proc PreviousWord {start line} {
        incr start -1
        set found 0
        for {set i $start} {$i > 0} {incr i -1} {
            set c [string index $line $i]
            if {$found && [IsWhite $c]} {
                break
            } elseif {!$found && ![IsWhite $c]} {
                set found 1
            }
        }
        return [string trim [string range $line $i $start]]
    }

    proc Quote {value left} {
        set right [Right $left]
        if {1 < [llength $value] && "" == $right} {
            return [list \"$value\"]
        } else {
            return [list ${left}${value}${right}]
        }
    }

    # the following two channel proc's make use of
    # the brand new (Sep 99) `file channels' command
    # but have some fallback behaviour for older
    # tcl version.
    #
    proc InChannelId {text {switches ""}} {
        if [catch {set chs [file channels]}] {
            set chs {stdin}
        }
        set result ""
        foreach ch $chs {
            if {![catch {fileevent $ch readable}]} {
                lappend result $ch
            }
        }
        return [ChannelId $text <inChannel> $result $switches]
    }

    proc OutChannelId {text {switches ""}} {
        if [catch {set chs [file channels]}] {
            set chs {stdout stderr}
        }
        set result ""
        foreach ch $chs {
            if {![catch {fileevent $ch writable}]} {
                lappend result $ch
            }
        }
        return [ChannelId $text <outChannel> $result $switches]
    }

    proc ChannelId {text {descript <channelId>} {chs ""} {switches ""}} {
        if {"" == $chs} {
            # the `file channels' command is present
            # only in pretty new versions.
            #
            if [catch {set chs [file channels]}] {
                set chs {stdin stdout stderr}
            }
        }
        if {[llength [set channel [TryFromList $text "$chs $switches"]]]} {
            return $channel
        } else {
            return [DisplayHints [string trim "$descript $switches"]]
        }
    }

    proc QuoteQuotes {line} {
        regsub -all -- \" $line {\"} line
        regsub -all -- \{ $line {\{} line; # \}\} (keep the editor happy)
        return $line
    }

    #**
    # get the word position.
    # @return the word position
    # @note will returned modified values.
    # @sa EventuallyEvaluateFirst
    #
    # % p<TAB>
    # % bla put<TAB> $b
    # % put<TAB> $b
    # part  == put
    # start == 0
    # end   == 3
    # line  == "put $b"
    # [PartPosition] should return 0
    #
    proc PartPosition {partT startT endT lineT} {

        upvar $partT part $startT start $endT end $lineT line
        EventuallyEvaluateFirst part start end line
        return [Llength [string range $line 0 [expr {$start - 1}]]]

    #
    #     set local_start [expr {$start - 1}]
    #     set local_start_chr [string index $line $local_start]
    #     if {"\"" == $local_start_chr || "\{" == $local_start_chr} {
    #         incr local_start -1
    #     }
    #
    #     set pre_text [QuoteQuotes [string range $line 0 $local_start]]
    #     return [llength $pre_text]
    #
    }

    proc Right {left} {
        if {"\"" == $left} {
            return "\""
        } elseif {"\\\"" == $left} {
            return "\\\""
        } elseif {"\{" == $left} {
            return "\}"
        } elseif {"\\\{" == $left} {
            return "\\\}"
        }
        return ""
    }

    proc GetQuotedPrefix {text} {
        set null [string index $text 0]
        if {"\"" == $null || "\{" == $null} {
            return \\$null
        } else {
            return {}
        }
    }

    proc CountChar {line char} {
        set found 0
        set pos 0
        while {-1 != [set pos [string first $char $line $pos]]} {
            incr pos
            incr found
        }
        return $found
    }

    #**
    # make a proper tcl list from an icomplete
    # string, that is: remove the junk. This is
    # complementary to `IncompleteListRemainder'.
    # e.g.:
    #       for {set i 1} "
    #  -->  for {set i 1}
    #
    proc ProperList {line} {
        set last [expr {[string length $line] - 1}]
        for {set i $last} {$i >= 0} {incr i -1} {
            if {![catch {llength [string range $line 0 $i]}]} {
                break
            }
        }
        return [string range $line 0 $i]
    }

    #**
    # return the last part of a line which
    # prevents the line from being a list.
    # This is complementary to `ProperList'.
    #
    proc IncompleteListRemainder {line} {
        set last [expr {[string length $line] - 1}]
        for {set i $last} {$i >= 0} {incr i -1} {
            if {![catch {llength [string range $line 0 $i]}]} {
                break
            }
        }
        incr i
        return [String range $line $i end]
    }

    #**
    # save `lindex'. works also for non-complete lines
    # with opening parentheses or quotes.
    # usage as `lindex'.
    # Eventually returns the Rest of an incomplete line,
    # if the index is `end' or == [Llength $line].
    #
    proc Lindex {line pos} {
        if {[catch [list set sub [lindex $line $pos]]]} {
            if {"end" == $pos || [Llength $line] == $pos} {
                return [IncompleteListRemainder $line]
            }
            set line [ProperList $line]
            if {[catch [list set sub [lindex $line $pos]]]} { return {} }
        }
        return $sub
    }

    #**
    # save `llength' (see above).
    #
    proc Llength {line} {
        if {[catch [list set len [llength $line]]]} {
            set line [ProperList $line]
            if {[catch [list set len [llength $line]]]} { return {} }
        }
        return $len
    }

    #**
    # save `lrange' (see above).
    #
    proc Lrange {line first last} {
        if {[catch [list set range [lrange $line $first $last]]]} {
            set rest [IncompleteListRemainder $line]
            set proper [ProperList $line]
            if {[catch [list set range [lindex $proper $first $last]]]} {
                return {}
            }
            if {"end" == $last || [Llength $line] == $last} {
                append sub " $rest"
            }
        }
        return $range
    }

    #**
    # Lunique -- remove duplicate entries from a sorted list
    # Only useful prior to Tcl 8.3 when lsort didn't have the
    # -unique flag
    # @param   list
    # @return  unique list
    #
    proc Lunique lst {
        set unique ""
        foreach element $lst {
            if {$element != [lindex $unique end]} {
                lappend unique $element
            }
        }
        return $unique
    }

    #**
    # string function, which works also for older versions
    # of tcl, which don't have the `end' index.
    # I tried also defining `string' and thus overriding
    # the builtin `string' which worked, but slowed down
    # things considerably. So I decided to call `String'
    # only if I really need the `end' index.
    #
    proc String args {
        if {[info tclversion] < 8.2} {
            switch [lindex $args 1] {
                range -
                index {
                    if {"end" == [lindex $args end]} {
                        set str [lindex $args 2]
                        lreplace args end end [expr {[string length $str] - 1}]
                    }
                }
            }
        }
        return [eval string $args]
    }

    proc StripPrefix {text} {
        set null [string index $text 0]
        if {"\"" == $null || "\{" == $null} {
            return [String range $text 1 end]
        } else {
            return $text
        }
    }

    proc VarCompletion {text {level -1}} {
        if {"#" != [string index $level 0]} {
            if {-1 == $level} {
                set level [info level]
            } else {
                incr level
            }
        }
        set pre [GetQuotedPrefix $text]
        set var [StripPrefix $text]

        # arrays
        #
        if {[regexp {([^(]*)\((.*)} $var all array name]} {
            set names [uplevel $level array names $array $name*]
            if {1 == [llength $names]} { ; # unique match
                return "${array}($names)"
            } elseif {"" != $names} {
                return "${array}([CompleteLongest $names] $names"
            } else {
                return ""; # nothing to complete
            }
        }

        # non-arrays
        #
        regsub ":$" $var "::" var
        set namespaces [namespace children :: ${var}*]
        if {[llength $namespaces] && "::" != [string range $var 0 1]} {
            foreach name $namespaces {
                regsub "^::" $name "" name
                if {[string length $name]} {
                    lappend new ${name}::
                }
            }
            set namespaces $new
            unset new
        }
        set matches \
            [string trim "[uplevel $level info vars ${var}*] $namespaces"]
        if {1 == [llength $matches]} { ; # unique match

            # check if this unique match is an
            # array name, (whith no "(" yet).
            #
            if {[uplevel $level array exists $matches]} {
                return [VarCompletion ${matches}( $level]; # recursion
            } else {
                return ${pre}${matches}[Right $pre]
            }
        } elseif {"" != $matches} { ; # more than one match
              return [CompleteFromList $text $matches]
        } else {
            return ""; # nothing to complete
        }
    }
}
