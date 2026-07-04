# -*- tclsh -*-
# Tk widget object completers.
# Sourced by ../tclreadlineCompleter.tcl.

namespace eval tclreadline {
    proc CompleteFromBitmaps {text {always 1}} {
        set inames [image names]
        set bitmaps ""
        foreach name $inames {
            if {"bitmap" == [image type $name]} {
                lappend bitmaps $name
            }
        }
        if {[string length $bitmaps]} {
            return [CompleteFromList $text $bitmaps]
        } else {
            if $always {
                return [DisplayHints <bitmaps>]
            } else {
                return ""
            }
        }
    }

    proc CompleteFromImages {text {always 1}} {
        set inames [image names]
        if {[string length $inames]} {
            return [CompleteFromList $text $inames]
        } else {
            if $always {
                return [DisplayHints <image>]
            } else {
                return ""
            }
        }
    }

    proc CompleteAnchor text {
        return [CompleteFromList $text {n ne e se s sw w nw center}]
    }

    proc CompleteJustify text {
        return [CompleteFromList $text {left center right}]
    }

    proc CanvasItem {text start end line pos prev type} {
        switch -- $type {
            arc       {
                switch -- $prev {
                    -extent         { return [DisplayHints <degrees>] }
                    -fill           -
                    -outline        { return [DisplayHints <color>] }
                    -outlinestipple -
                    -stipple        {
                        set inames [image names]
                        set bitmaps ""
                        foreach name $inames {
                            if {"bitmap" == [image type $name]} {
                                lappend bitmaps $name
                            }
                        }
                        if {[string length $bitmaps]} {
                            return [CompleteFromList $text $bitmaps]
                        } else {
                            return [DisplayHints <bitmaps>]
                        }
                    }
                    -start          { return [DisplayHints <degrees>] }
                    -style          { return [DisplayHints <type>] }
                    -tags           { return [DisplayHints <tagList>] }
                    -width          { return [DisplayHints <outlineWidth>] }
                    default         {
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line \
                                         {-extent -fill -outline
                                          -outlinestipple -start
                                          -stipple -style -tags -width}]]
                    }
                }
            }
            bitmap    {
                switch -- $prev {
                    -anchor     { return [CompleteAnchor $text] }
                    -background -
                    -foreground { return [DisplayHints <color>] }
                    -bitmap     { return [CompleteFromBitmaps $text] }
                    -tags       { return [DisplayHints <tagList>] }
                    default     {
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line \
                                         {-anchor -background -bitmap
                                          -foreground -tags}]]
                    }
                }
            }
            image     {
                switch -- $prev {
                    -anchor { return [CompleteAnchor $text] }
                    -image  { return [CompleteFromImages $text] }
                    -tags   { return [DisplayHints <tagList>] }
                    default {
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line \
                                         {-anchor -image -tags}]]
                    }
                }
            }
            line      {
                switch -- $prev {
                    -arrow       { return [CompleteFromList $text {none first last both}] }
                    -arrowshape  { return [DisplayHints <shape>] }
                    -capstyle    { return [CompleteFromList $text {butt projecting round}] }
                    -fill        { return [DisplayHints <color>] }
                    -joinstyle   { return [CompleteFromList $text {bevel miter round}] }
                    -smooth      { return [CompleteBoolean $text] }
                    -splinesteps { return [DisplayHints <number>] }
                    -stipple     { return [CompleteFromBitmaps $text] }
                    -tags        { return [DisplayHints <tagList>] }
                    -width       { return [DisplayHints <lineWidth>] }
                    default      {
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line \
                                         {-arrow -arrowshape -capstyle
                                          -fill -joinstyle -smooth
                                          -splinesteps -stipple -tags -width}]]
                    }
                }
            }
            oval      {
                switch -- $prev {
                    -fill    -
                    -outline { return [DisplayHints <color>] }
                    -stipple { return [CompleteFromBitmaps $text] }
                    -tags    { return [DisplayHints <tagList>] }
                    -width   { return [DisplayHints <lineWidth>] }
                    default  {
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line \
                                         {-fill -outline -stipple -tags -width}]]
                    }
                }
            }
            polygon   {
                switch -- $prev {
                    -fill        -
                    -outline     { return [DisplayHints <color>] }
                    -smooth      { return [CompleteBoolean $text] }
                    -splinesteps { return [DisplayHints <number>] }
                    -stipple     { return [CompleteFromBitmaps $text] }
                    -tags        { return [DisplayHints <tagList>] }
                    -width       { return [DisplayHints <outlineWidth>] }
                    default      {
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line \
                                         {-fill -outline -smooth -splinesteps
                                          -stipple -tags -width}]]
                    }
                }
            }
            rectangle {
                switch -- $prev {
                    -fill    -
                    -outline { return [DisplayHints <color>] }
                    -stipple { return [CompleteFromBitmaps $text] }
                    -tags    { return [DisplayHints <tagList>] }
                    -width   { return [DisplayHints <lineWidth>] }
                    default  {
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line \
                                         {-fill -outline -stipple -tags -width}]]
                    }
                }
            }
            text      {
                switch -- $prev {
                    -anchor  { return [CompleteAnchor $text] }
                    -fill    { return [DisplayHints <color>] }
                    -font    { return [DisplayHints <font>] }
                    -justify { return [CompleteJustify $text] }
                    -stipple { return [CompleteFromBitmaps $text] }
                    -tags    { return [DisplayHints <tagList>] }
                    -text    { return [DisplayHints <string>] }
                    -width   { return [DisplayHints <lineLength>] }
                    default  {
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line \
                                         {-anchor -fill -font -justify
                                          -stipple -tags -text -width}]]
                    }
                }
            }
            window    {
                switch -- $prev {
                    -anchor { return [CompleteAnchor $text] }
                    -height { return [DisplayHints <pixels>] }
                    -tags   { return [DisplayHints <tagList>] }
                    -width  { return [DisplayHints <lineWidth>] }
                    -window { return [TryFromList $text [WidgetChildren $text]] }
                    default {
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line \
                                         {-anchor -height -tags -width -window}]]
                    }
                }
            }
        }
    }

    #**
    # WidgetXviewYview
    #
    # @param    text  -- the word to complete.
    # @param    line  -- the line gathered so far.
    # @param    pos   -- the current word position.
    # @param    prev  -- the previous word.
    # @return   a std tclreadline formatted completer string.
    # @sa       CanvasObj, EntryObj
    #
    proc WidgetXviewYview {text line pos prev} {
        switch -- $pos {
            2 { return [CompleteFromList $text {<index> moveto scroll}] }
            3 {
                switch -- $prev {
                    moveto { return [DisplayHints <fraction>] }
                    scroll { return [DisplayHints <number>] }
                }
            }
            4 {
                set subcmd [Lindex $line 2]
                switch -- $subcmd {
                    scroll { return [DisplayHints <what>] }
                }
            }
        }
    }

    #**
    # WidgetScan
    #
    # @param    text  -- the word to complete.
    # @param    pos   -- the current word position.
    # @return   a std tclreadline formatted completer string.
    # @sa       CanvasObj, EntryObj
    #
    proc WidgetScan {text pos} {
        switch -- $pos {
            2 { return [CompleteFromList $text {mark dragto}] }
            3 { return [DisplayHints <x>] }
            4 { return [DisplayHints <y>] }
        }
    }

    proc CanvasObj {text start end line pos} {
        set sub [Lindex $line 1]
        set prev [PreviousWord $start $line]
        if {1 == $pos} {
            return [TrySubCmds $text [Lindex $line 0]]
        }
        switch -- $sub {
            addtag        {
                switch -- $pos {
                    2       { return [DisplayHints <tag>] }
                    3       {
                        return [CompleteFromList $text \
                                    {above all below closest enclosed overlapping withtag}]
                    }
                    default {
                        set search [Lindex $line 3]
                        switch -- $search {
                            all         {}
                            above       -
                            withtag     -
                            below       { return [DisplayHints <tagOrId>] }
                            closest     {
                                switch -- $pos {
                                    4 { return [DisplayHints <x>] }
                                    5 { return [DisplayHints <y>] }
                                    6 { return [DisplayHints ?halo?] }
                                    7 { return [DisplayHints ?start?] }
                                }
                            }
                            enclosed    -
                            overlapping {
                                switch -- $pos {
                                    4 { return [DisplayHints <x1>] }
                                    5 { return [DisplayHints <y1>] }
                                    6 { return [DisplayHints <x2>] }
                                    7 { return [DisplayHints <y2>] }
                                }
                            }
                        }
                    }
                }
            }
            bbox          {
                switch -- $pos {
                    2       { return [DisplayHints <tagOrId>] }
                    default { return [DisplayHints ?tagOrId?] }
                }
            }
            bind          {
                switch -- $pos {
                    2       { return [DisplayHints <tagOrId>] }
                    3       {
                        set fulltext [Lindex $line 3]
                        return [CompleteSequence $text $fulltext]
                        # return [DisplayHints ?sequence?]
                    }
                    default {
                        return [BraceOrCommand $text $start $end $line $pos $text]
                    }
                }
            }
            canvasx       {
                switch -- $pos {
                    2 { return [DisplayHints <screenx>] }
                    3 { return [DisplayHints ?gridspacing?] }
                }
            }
            canvasy       {
                switch -- $pos {
                    2 { return [DisplayHints <screeny>] }
                    3 { return [DisplayHints ?gridspacing?] }
                }
            }
            coords        {
                switch -- $pos {
                    2       { return [DisplayHints <tagOrId>] }
                    default {
                        switch [expr {$pos % 2}] {
                            1 { return [DisplayHints ?x?] }
                            0 { return [DisplayHints ?y?] }
                        }
                    }
                }
            }
            dchars        {
                switch -- $pos {
                    2 { return [DisplayHints <tagOrId>] }
                    3 { return [DisplayHints <first>] }
                    4 { return [DisplayHints ?last?] }
                }
            }
            delete        { return [DisplayHints ?tagOrId?] }
            dtag          {
                switch -- $pos {
                    2 { return [DisplayHints <tagOrId>] }
                    3 { return [DisplayHints ?tagToDelete?] }
                }
            }
            find          {
                switch -- $pos {
                    2       { return [TrySubCmds $text [Lrange $line 0 1]] }
                    default { return [DisplayHints ?arg?] }
                }
            }
            focus         {
                switch -- $pos {
                    2 { return [DisplayHints ?tagOrId?] }
                }
            }
            gettags       {
                switch -- $pos {
                    2 { return [DisplayHints <tagOrId>] }
                }
            }
            icursor       -
            index         {
                switch -- $pos {
                    2 { return [DisplayHints <tagOrId>] }
                    3 { return [DisplayHints <index>] }
                }
            }
            insert        {
                switch -- $pos {
                    2 { return [DisplayHints <tagOrId>] }
                    3 { return [DisplayHints <beforeThis>] }
                    4 { return [DisplayHints <string>] }
                }
            }
            lower         {
                switch -- $pos {
                    2 { return [DisplayHints <tagOrId>] }
                    3 { return [DisplayHints ?belowThis?] }
                }
            }
            move          {
                switch -- $pos {
                    2 { return [DisplayHints <tagOrId>] }
                    3 { return [DisplayHints <xAmount>] }
                    4 { return [DisplayHints <yAmount>] }
                }
            }
            postscript    {
                switch -- $prev {
                    -file       { return "" }
                    -colormap   -
                    -colormode  -
                    -fontmap    -
                    -height     -
                    -pageanchor -
                    -pageheight -
                    -pagewidth  -
                    -pagex      -
                    -pagey      -
                    -rotate     -
                    -width      -
                    -x          -
                    -y          { return [DisplayHints <[String range $prev 1 end]>] }
                    default     {
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line \
                                         {-colormap -colormode -file -fontmap -height
                                          -pageanchor -pageheight -pagewidth -pagex
                                          -pagey -rotate -width -x -y}]]
                    }
                }
            }
            raise         {
                switch -- $pos {
                    2 { return [DisplayHints <tagOrId>] }
                    3 { return [DisplayHints ?aboveThis?] }
                }
            }
            scale         {
                switch -- $pos {
                    2 { return [DisplayHints <tagOrId>] }
                    3 { return [DisplayHints <xOrigin>] }
                    4 { return [DisplayHints <yOrigin>] }
                    5 { return [DisplayHints <xScale>] }
                    6 { return [DisplayHints <yScale>] }
                }
            }
            scan          { return [WidgetScan $text $pos] }
            select        {
                switch -- $pos {
                    2 { return [CompleteFromList $text {adjust clear item from to}] }
                    3 {
                        set sub [Lindex $line 2]
                        switch -- $sub {
                            adjust -
                            from   -
                            to     { return [DisplayHints <tagOrId>] }
                        }
                    }
                    4 {
                        set sub [Lindex $line 2]
                        switch -- $sub {
                            adjust -
                            from   -
                            to     { return [DisplayHints <index>] }
                        }
                    }
                }
            }
            xview         -
            yview         { return [XviewYview $text $line $pos $prev] }
            create        {
                switch -- $pos {
                    2       {
                        return [CompleteFromList $text \
                                    {arc bitmap image line oval
                                     polygon rectangle text window}]
                    }
                    3       { return [DisplayHints <x1>] }
                    4       { return [DisplayHints <y1>] }
                    5       {
                        set type [Lindex $line 2]
                        switch -- $type {
                            arc       -
                            oval      -
                            rectangle { return [DisplayHints <x2>] }
                            # TODO items with more than 4 coordinates
                            default   {
                                return [CanvasItem $text $start $end \
                                            $line $pos $prev $type]
                            }
                        }
                    }
                    6       {
                        set type [Lindex $line 2]
                        switch -- $type {
                            arc       -
                            oval      -
                            rectangle { return [DisplayHints <y2>] }
                            # TODO items with more than 4 coordinates
                            default   {
                                return [CanvasItem $text $start $end \
                                            $line $pos $prev $type]
                            }
                        }
                    }
                    default {
                        set type [Lindex $line 2]
                        # TODO items with more than 4 coordinates
                        return [CanvasItem $text $start $end \
                                    $line $pos $prev $type]
                    }
                }
            }
            itemconfigure -
            itemcget      {
                switch -- $pos {
                    2       { return [DisplayHints <tagOrId>] }
                    default {
                        set id [Lindex $line 2]
                        set type [[Lindex $line 0] type $id]
                        if {![string length $type]} {
                            return ""; # no such element
                        }

                        return [CanvasItem $text $start $end \
                                    $line $pos $prev $type]
                    }
                }
            }
        }
        return ""
    }

    proc EntryIndex text {
        return [CompleteFromList $text {<number> <@number> anchor end sel.first sel.last}]
    }

    proc EntryObj {text start end line pos} {
        set sub [Lindex $line 1]
        set prev [PreviousWord $start $line]
        if {1 == $pos} {
            return [TrySubCmds $text [Lindex $line 0]]
        }
        switch -- $sub {
            bbox      -
            icursor   -
            index     { return [EntryIndex $text] }
            cget      {}
            configure {}
            get       {}
            insert    {
                switch -- $pos {
                    2 { return [EntryIndex $text] }
                    3 { return [DisplayHints <string>] }
                }
            }
            scan      { return [WidgetScan $text $pos] }
            selection {
                switch -- $pos {
                    2 { return [TrySubCmds $text [Lrange $line 0 1]] }
                    3 {
                        switch -- $prev {
                            adjust  -
                            from    -
                            to      { return [EntryIndex $text] }
                            clear   -
                            present {}
                            range   { return [DisplayHints <start>] }
                        }
                    }
                    4 {
                        switch -- [Lindex $line 2] {
                            range { return [DisplayHints <end>] }
                        }
                    }
                }
            }
            xview     -
            yview     { return [WidgetXviewYview $text $line $pos $prev] }
        }
        return ""
    }

    # proc CheckbuttonObj {text start end line pos} {
    # the fallback routines do the job pretty well.
    # }

    # proc FrameObj {text start end line pos} {
    # the fallback routines do the job pretty well.
    # }

    # proc LabelObj {text start end line pos} {
    # the fallback routines do the job pretty well.
    # }

    proc ListboxObj {text start end line pos} {
        set sub [Lindex $line 1]
        set prev [PreviousWord $start $line]
        if {1 == $pos} {
            return [TrySubCmds $text [Lindex $line 0]]
        }
        switch -- $sub {
            activate     -
            bbox         -
            index        -
            see          {
                switch -- $pos {
                    2 { return [DisplayHints <index>] }
                }
            }
            insert       {
                switch -- $pos {
                    2       { return [DisplayHints <index>] }
                    default { return [DisplayHints ?element?] }
                }
            }
            cget         {}
            configure    {}
            curselection {}
            delete       -
            get          {
                switch -- $pos {
                    2 { return [DisplayHints <first>] }
                    3 { return [DisplayHints ?last?] }
                }
            }
            nearest      {
                switch -- $pos {
                    2 { return [DisplayHints <y>] }
                }
            }
            size         {}

            scan { return [WidgetScan $text $pos] }

            xview -
            yview { return [WidgetXviewYview $text $line $pos $prev] }

            selection {
                switch -- $pos {
                    2 { return [CompleteFromList $text {anchor clear includes set}] }
                    3 {
                        switch -- $prev {
                            anchor   -
                            includes {
                                return [CompleteFromList $text \
                                            {active anchor end @x @y <number>}]
                            }
                            clear    -
                            set      { return [DisplayHints <first>] }
                        }
                    }
                    4 {
                        switch -- [Lindex $line 2] {
                            clear -
                            set   { return [DisplayHints ?last?] }
                        }
                    }
                }
            }
        }
    }

    proc MenuIndex text {
        return [CompleteFromList $text {<number> active end last none <@number> <labelPattern>}]
    }

    proc MenuItem {text start end line pos virtualpos} {
        switch -- $virtualpos {
            2       {
                return [CompleteFromList $text \
                            {cascade checkbutton command radiobutton separator}]
            }
            default {
                switch -- [PreviousWord $start $line] {
                    -activebackground -
                    -activeforeground -
                    -background       -
                    -foreground       -
                    -selectcolor      { return [DisplayHints <color>] }

                    -accelerator { return [DisplayHints <accel>] }
                    -bitmap      { return [CompleteFromBitmaps $text] }

                    -columnbreak -
                    -hidemargin  -
                    -indicatoron { return [CompleteBoolean $text] }
                    -command     {
                        return [BraceOrCommand $text $start \
                                    $end $line $pos $text]
                    }
                    -font        {
                        set names [font names]
                        if {[string length $names]} {
                            return [CompleteFromList $text $names]
                        } else {
                            return [DisplayHints <fontname>]
                        }
                    }
                    -image       -
                    -selectimage { return [CompleteFromImages $text] }

                    -label { return [DisplayHints <label>] }
                    -menu  {
                        set names [WidgetChildren [Lindex $line 0]]
                        if {[string length $names]} {
                            return [CompleteFromList $text $names]
                        } else {
                            return [DisplayHints <menu>]
                        }
                    }

                    -offvalue -
                    -onvalue  { return [DisplayHints <value>] }

                    -state     { return [CompleteFromList $text {normal active disabled}] }
                    -underline { return [DisplayHints <integer>] }
                    -value     { return [DisplayHints <value>] }
                    -variable  { return [VarCompletion $text #0] }

                    default {
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line \
                                         {-activebackground -activeforeground
                                          -accelerator -background -bitmap -columnbreak
                                          -command -font -foreground -hidemargin -image
                                          -indicatoron -label -menu -offvalue -onvalue
                                          -selectcolor -selectimage -state -underline
                                          -value -variable}]]
                    }
                }
            }
        }
    }

    proc MenuObj {text start end line pos} {
        set sub [Lindex $line 1]
        set prev [PreviousWord $start $line]
        if {1 == $pos} {
            return [TrySubCmds $text [Lindex $line 0]]
        }
        switch -- $sub {
            activate    -
            index       -
            invoke      -
            postcascade -
            type        -
            yposition   {
                switch -- $pos {
                    2 { return [MenuIndex $text] }
                }
            }
            configure   {}
            cget        {}

            add            { return [MenuItem $text $start $end $line $pos $pos] }
            clone          {
                switch -- $pos {
                    2 { return [DisplayHints <newPathname>] }
                    3 { return [CompleteFromList $text {normal menubar tearoff}] }
                }
            }
            delete         {
                switch -- $pos {
                    2 -
                    3 { return [MenuIndex $text] }
                }
            }
            insert         {
                switch -- $pos {
                    2       { return [MenuIndex $text] }
                    default {
                        return [MenuItem $text $start $end \
                                    $line $pos [expr {$pos - 1}]]
                    }
                }
            }
            entrycget      -
            entryconfigure {
                switch -- $pos {
                    2       { return [MenuIndex $text] }
                    default { return [MenuItem $text $start $end $line $pos $pos] }
                }
            }
            post           {
                switch -- $pos {
                    2 { return [DisplayHints <x>] }
                    3 { return [DisplayHints <y>] }
                }
            }
            # ??? XXX
            unpost         {}
        }
    }

    proc PhotoObj {text start end line pos} {
        set sub [Lindex $line 1]
        set prev [PreviousWord $start $line]
        set copy_opts { -from -to -shrink -zoom -subsample }
        set read_opts { -from -to -shrink -format }
        set write_opts { -from -format }
        switch -- $pos {
            1       {
                return [CompleteFromList $text \
                            {blank cget configure copy get put read redither write}]
            }
            2       {
                switch -- $sub {
                    blank     {}
                    cget      {}
                    configure {}
                    redither  {}
                    copy      { return [CompleteFromImages $text] }
                    get       { return [DisplayHints <x>] }
                    put       { return [DisplayHints <data>] }
                    read      {}
                    write     {}
                }
            }
            3       {
                switch -- $sub {
                    blank     {}
                    cget      {}
                    configure {}
                    redither  {}
                    copy      { return [CompleteFromList $text $copy_opts] }
                    get       { return [DisplayHints <y>] }
                    put       { return [CompleteFromList $text -to] }
                    read      { return [CompleteFromList $text $read_opts] }
                    write     { return [CompleteFromList $text $write_opts] }
                }
            }
            default {
                switch -- $sub {
                    blank     {}
                    cget      {}
                    configure {}
                    redither  {}
                    get       {}
                    copy      {
                        switch -- $prev {
                            -from      -
                            -to        { return [DisplayHints [list <x1 y1 x2 y2>]] }
                            -zoom      -
                            -subsample { return [DisplayHints [list <x y>]] }
                            default    {
                                return [CompleteFromList $text \
                                            [RemoveUsedOptions $line $copy_opts]]
                            }
                        }
                    }
                    put       {
                        switch -- $prev {
                            -to { return [DisplayHints [list <x1 y1 x2 y2>]] }
                        }
                    }
                    read      {
                        switch -- $prev {
                            -from   { return [DisplayHints [list <x1 y1 x2 y2>]] }
                            -to     { return [DisplayHints [list <x y>]] }
                            -format { return [DisplayHints <formatName>] }
                            default {
                                return [CompleteFromList $text \
                                            [RemoveUsedOptions $line $read_opts]]
                            }
                        }
                    }
                    write     {
                        switch -- $prev {
                            -from   { return [DisplayHints [list <x1 y1 x2 y2>]] }
                            -format { return [DisplayHints <formatName>] }
                            default {
                                return [CompleteFromList $text \
                                            [RemoveUsedOptions $line $write_opts]]
                            }
                        }
                    }
                }
            }
        }
    }

    # proc RadiobuttonObj {text start end line pos} {
    # the fallback routines do the job pretty well.
    # }

    proc ScaleObj {text start end line pos} {

        set sub [Lindex $line 1]
        set prev [PreviousWord $start $line]

        switch -- $pos {
            1 { return [TrySubCmds $text [Lindex $line 0]] }
            2 {
                switch -- $sub {
                    coords   { return [DisplayHints ?value?] }
                    get      { return [DisplayHints ?x?] }
                    identify { return [DisplayHints <x>] }
                    set      { return [DisplayHints <value>] }
                }
            }
            3 {
                switch -- $sub {
                    get      { return [DisplayHints ?y?] }
                    identify { return [DisplayHints <y>] }
                }
            }
        }
    }

    proc ScrollbarObj {text start end line pos} {

        set sub [Lindex $line 1]
        set prev [PreviousWord $start $line]

        # note that the `prefix moveto|scroll'
        # construct is hard to complete.
        #
        switch -- $pos {
            1 { return [TrySubCmds $text [Lindex $line 0]] }
            2 {
                switch -- $sub {
                    activate { return [CompleteFromList $text {arrow1 slider arrow2}] }
                    fraction -
                    identify { return [DisplayHints <x>] }
                    delta    { return [DisplayHints <deltaX>] }
                    set      { return [DisplayHints <first>] }
                }
            }
            3 {
                switch -- $sub {
                    fraction -
                    identify { return [DisplayHints <y>] }
                    delta    { return [DisplayHints <deltaY>] }
                    set      { return [DisplayHints <last>] }
                }
            }
        }
    }

    proc TextObj {text start end line pos} {
        # TODO ...
        return [CompleteFromOptionsOrSubCmds $text $start $end $line $pos]
    }

}
