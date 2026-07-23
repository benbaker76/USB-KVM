// resource.h — resource identifiers for the Windows tray application.

#ifndef USBKVM_RESOURCE_H
#define USBKVM_RESOURCE_H

// Full-colour application icon. Must stay the lowest-numbered ICON resource:
// that is the one Explorer, Alt-Tab and the title bar pick up.
#define IDI_APP             100

// Tray icons. Two artwork variants so the silhouette stays visible on both light
// and dark taskbars, each with an error form shown when no switch is attached.
#define IDI_TRAY_DARK       101
#define IDI_TRAY_LIGHT      102
#define IDI_TRAY_DARK_OFF   103
#define IDI_TRAY_LIGHT_OFF  104

// Context menu commands.
#define IDM_SWITCH_ALL      201
#define IDM_SWITCH_KVM      202
#define IDM_SWITCH_AUDIO    203
#define IDM_SELECT_PC3      204
#define IDM_SELECT_PC4      205
#define IDM_SWITCH_OPT      206
#define IDM_RUN_AT_STARTUP  207
#define IDM_ABOUT           208
#define IDM_EXIT            209

#endif  // USBKVM_RESOURCE_H
