#include "tclreadline.h"

#if defined(__GNUC__) || defined(__clang__)
#define TCLRL_USED __attribute__((used))
#else
#define TCLRL_USED
#endif

typedef int (*TclreadlineInitProc)(Tcl_Interp *);

/*
 * The implementation lives in Rust's static archive. Keep explicit references
 * here so the linker pulls the archive member that exports Tcl's package entry
 * points into libtclreadline.so.
 */
static TCLRL_USED TclreadlineInitProc rust_entry_points[] = {
    Tclreadline_Init,
    Tclreadline_SafeInit,
};
