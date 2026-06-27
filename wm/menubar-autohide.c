// Hides the macOS menu bar live (same private API System Settings uses),
// so sketchybar is the only top row. Run at WM startup.
//   menubar-autohide 1   -> hide (autohide on)
//   menubar-autohide 0   -> show
#include <stdbool.h>
#include <stdio.h>

extern int SLSMainConnectionID(void);
extern int SLSSetMenuBarAutohideEnabled(int cid, int enabled);

int main(int argc, char **argv) {
    int cid = SLSMainConnectionID();
    int on = (argc > 1) ? (argv[1][0] - '0') : 1;
    int err = SLSSetMenuBarAutohideEnabled(cid, on);
    printf("menu bar autohide=%d err=%d\n", on, err);
    return err;
}
