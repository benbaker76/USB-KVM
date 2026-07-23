// main.cpp — system tray application for ActionStar USB KVM switches.
//
// Replaces the original Delphi USBKVM.exe. Left-click the tray icon to switch
// video, USB and audio to the next port; right-click for the full command set.
//
// The device re-enumerates every time it switches (the KVM physically hands the
// USB link to the other host), so no handle is held open between commands. Each
// command enumerates, opens, writes and closes. Presence is refreshed from
// WM_DEVICECHANGE rather than polled.

#include "usbkvm/usbkvm.h"

#include "resource.h"

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif

#include <windows.h>

#include <dbt.h>
#include <shellapi.h>
#include <windowsx.h>  // GET_X_LPARAM / GET_Y_LPARAM

extern "C" {
#include <hidsdi.h>
}

#include <string>

namespace {

constexpr wchar_t kWindowClass[] = L"UsbKvmTrayWindow";
constexpr wchar_t kAppName[]     = L"USB KVM";
constexpr wchar_t kMutexName[]   = L"Local\\UsbKvmTraySingleInstance";

// Registry value used for the "Start with Windows" toggle.
constexpr wchar_t kRunKey[]      = L"Software\\Microsoft\\Windows\\CurrentVersion\\Run";
constexpr wchar_t kRunValue[]    = L"USB KVM";

constexpr UINT kTrayIconId       = 1;
constexpr UINT WM_TRAYICON       = WM_APP + 1;

// Device arrival/removal arrives in bursts; collapse them into one refresh.
constexpr UINT_PTR kRefreshTimer   = 1;
constexpr UINT     kRefreshDelayMs = 400;

HINSTANCE g_instance      = nullptr;
HWND      g_window        = nullptr;
HDEVNOTIFY g_deviceNotify = nullptr;
bool      g_devicePresent = false;
UINT      g_taskbarCreated = 0;

std::wstring toWide(const std::string& text) {
    if (text.empty())
        return {};

    const int needed = ::MultiByteToWideChar(CP_UTF8, 0, text.c_str(),
                                             static_cast<int>(text.size()), nullptr, 0);
    if (needed <= 0)
        return {};

    std::wstring out(static_cast<size_t>(needed), L'\0');
    ::MultiByteToWideChar(CP_UTF8, 0, text.c_str(), static_cast<int>(text.size()),
                          out.data(), needed);
    return out;
}

// Windows exposes the taskbar theme here. Missing value means light, which is
// what pre-1903 builds always used.
bool systemUsesLightTheme() {
    HKEY key = nullptr;
    if (::RegOpenKeyExW(HKEY_CURRENT_USER,
                        L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
                        0, KEY_QUERY_VALUE, &key) != ERROR_SUCCESS) {
        return true;
    }

    DWORD value = 1;
    DWORD size  = sizeof(value);
    DWORD type  = 0;
    const LSTATUS status =
        ::RegQueryValueExW(key, L"SystemUsesLightTheme", nullptr, &type,
                           reinterpret_cast<LPBYTE>(&value), &size);
    ::RegCloseKey(key);

    if (status != ERROR_SUCCESS || type != REG_DWORD)
        return true;

    return value != 0;
}

HICON currentTrayIcon() {
    // A light taskbar needs the dark silhouette, and vice versa. When no switch
    // is attached we show the warning artwork, matching the macOS menu bar app.
    const bool light = systemUsesLightTheme();

    int id;
    if (g_devicePresent)
        id = light ? IDI_TRAY_DARK : IDI_TRAY_LIGHT;
    else
        id = light ? IDI_TRAY_DARK_OFF : IDI_TRAY_LIGHT_OFF;

    const int size = ::GetSystemMetrics(SM_CXSMICON);
    return static_cast<HICON>(::LoadImageW(g_instance, MAKEINTRESOURCEW(id), IMAGE_ICON,
                                           size, size, LR_DEFAULTCOLOR));
}

void fillNotifyIconData(NOTIFYICONDATAW& data) {
    ZeroMemory(&data, sizeof(data));
    data.cbSize           = sizeof(data);
    data.hWnd             = g_window;
    data.uID              = kTrayIconId;
    data.uFlags           = NIF_ICON | NIF_MESSAGE | NIF_TIP;
    data.uCallbackMessage = WM_TRAYICON;
    data.hIcon            = currentTrayIcon();

    const std::wstring tip =
        g_devicePresent ? std::wstring(kAppName) + L" — click to switch"
                        : std::wstring(kAppName) + L" — no switch detected";
    ::wcsncpy_s(data.szTip, tip.c_str(), _TRUNCATE);
}

void addTrayIcon() {
    NOTIFYICONDATAW data;
    fillNotifyIconData(data);
    ::Shell_NotifyIconW(NIM_ADD, &data);

    // Opt into the richer callback encoding (NIN_SELECT, WM_CONTEXTMENU).
    data.uVersion = NOTIFYICON_VERSION_4;
    ::Shell_NotifyIconW(NIM_SETVERSION, &data);

    if (data.hIcon)
        ::DestroyIcon(data.hIcon);
}

void updateTrayIcon() {
    NOTIFYICONDATAW data;
    fillNotifyIconData(data);
    ::Shell_NotifyIconW(NIM_MODIFY, &data);

    if (data.hIcon)
        ::DestroyIcon(data.hIcon);
}

void removeTrayIcon() {
    NOTIFYICONDATAW data;
    ZeroMemory(&data, sizeof(data));
    data.cbSize = sizeof(data);
    data.hWnd   = g_window;
    data.uID    = kTrayIconId;
    ::Shell_NotifyIconW(NIM_DELETE, &data);
}

void refreshDeviceState() {
    const bool present = !usbkvm::enumerate().empty();
    if (present == g_devicePresent)
        return;

    g_devicePresent = present;
    updateTrayIcon();
}

void showBalloon(const std::wstring& title, const std::wstring& text, bool error) {
    NOTIFYICONDATAW data;
    ZeroMemory(&data, sizeof(data));
    data.cbSize = sizeof(data);
    data.hWnd   = g_window;
    data.uID    = kTrayIconId;
    data.uFlags = NIF_INFO;
    data.dwInfoFlags = error ? NIIF_ERROR : NIIF_INFO;
    ::wcsncpy_s(data.szInfoTitle, title.c_str(), _TRUNCATE);
    ::wcsncpy_s(data.szInfo, text.c_str(), _TRUNCATE);
    ::Shell_NotifyIconW(NIM_MODIFY, &data);
}

// Opens the switch, sends one command and closes again.
void sendCommand(const usbkvm::Command& command) {
    usbkvm::Device device;

    if (!device.openFirst()) {
        showBalloon(kAppName, toWide(device.lastError()), true);
        refreshDeviceState();
        return;
    }

    if (!device.send(command)) {
        showBalloon(kAppName, toWide(device.lastError()), true);
        return;
    }

    // Switching drops and re-adds the USB device; re-check once it settles.
    ::SetTimer(g_window, kRefreshTimer, kRefreshDelayMs, nullptr);
}

bool runAtStartupEnabled() {
    HKEY key = nullptr;
    if (::RegOpenKeyExW(HKEY_CURRENT_USER, kRunKey, 0, KEY_QUERY_VALUE, &key) !=
        ERROR_SUCCESS) {
        return false;
    }

    const LSTATUS status =
        ::RegQueryValueExW(key, kRunValue, nullptr, nullptr, nullptr, nullptr);
    ::RegCloseKey(key);

    return status == ERROR_SUCCESS;
}

void setRunAtStartup(bool enable) {
    HKEY key = nullptr;
    if (::RegCreateKeyExW(HKEY_CURRENT_USER, kRunKey, 0, nullptr, 0, KEY_SET_VALUE,
                          nullptr, &key, nullptr) != ERROR_SUCCESS) {
        return;
    }

    if (enable) {
        wchar_t path[MAX_PATH] = {};
        const DWORD length = ::GetModuleFileNameW(nullptr, path, MAX_PATH);
        if (length > 0 && length < MAX_PATH) {
            // Quote it: the path may contain spaces.
            const std::wstring quoted = L"\"" + std::wstring(path) + L"\"";
            ::RegSetValueExW(key, kRunValue, 0, REG_SZ,
                             reinterpret_cast<const BYTE*>(quoted.c_str()),
                             static_cast<DWORD>((quoted.size() + 1) * sizeof(wchar_t)));
        }
    } else {
        ::RegDeleteValueW(key, kRunValue);
    }

    ::RegCloseKey(key);
}

void showContextMenu(int x, int y) {
    HMENU menu = ::CreatePopupMenu();
    if (!menu)
        return;

    const UINT enabled = g_devicePresent ? MF_STRING : (MF_STRING | MF_GRAYED);

    ::AppendMenuW(menu, enabled, IDM_SWITCH_ALL,   L"&Switch All (video + USB + audio)");
    ::AppendMenuW(menu, enabled, IDM_SWITCH_KVM,   L"Switch &KVM only");
    ::AppendMenuW(menu, enabled, IDM_SWITCH_AUDIO, L"Switch &audio only");
    ::AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    ::AppendMenuW(menu, enabled, IDM_SELECT_PC3,   L"Select PC &3");
    ::AppendMenuW(menu, enabled, IDM_SELECT_PC4,   L"Select PC &4");
    ::AppendMenuW(menu, enabled, IDM_SWITCH_OPT,   L"Send &OPT switch");
    ::AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    ::AppendMenuW(menu,
                  MF_STRING | (runAtStartupEnabled() ? MF_CHECKED : MF_UNCHECKED),
                  IDM_RUN_AT_STARTUP, L"Start with &Windows");
    ::AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    ::AppendMenuW(menu, MF_STRING, IDM_ABOUT, L"A&bout...");
    ::AppendMenuW(menu, MF_STRING, IDM_EXIT,  L"E&xit");

    ::SetMenuDefaultItem(menu, IDM_SWITCH_ALL, FALSE);

    // Required so the menu dismisses when the user clicks elsewhere.
    ::SetForegroundWindow(g_window);
    ::TrackPopupMenu(menu, TPM_RIGHTBUTTON | TPM_BOTTOMALIGN, x, y, 0, g_window, nullptr);
    ::PostMessageW(g_window, WM_NULL, 0, 0);

    ::DestroyMenu(menu);
}

void showAbout() {
    std::wstring text =
        L"USB KVM tray control\n\n"
        L"Controls ActionStar-chip USB KVM switches over their vendor HID\n"
        L"interface (usage page 0xFF01, report ID 3).\n\n";

    const auto devices = usbkvm::enumerate();
    if (devices.empty()) {
        text += L"No switch currently detected.";
    } else {
        wchar_t line[256];
        ::swprintf_s(line, L"Detected: %04x:%04x\n%s", devices.front().vendorId,
                     devices.front().productId,
                     toWide(devices.front().product).c_str());
        text += line;
    }

    ::MessageBoxW(nullptr, text.c_str(), kAppName, MB_OK | MB_ICONINFORMATION);
}

void registerDeviceNotifications() {
    GUID hidGuid{};
    ::HidD_GetHidGuid(&hidGuid);

    DEV_BROADCAST_DEVICEINTERFACE_W filter{};
    filter.dbcc_size       = sizeof(filter);
    filter.dbcc_devicetype = DBT_DEVTYP_DEVICEINTERFACE;
    filter.dbcc_classguid  = hidGuid;

    g_deviceNotify = ::RegisterDeviceNotificationW(g_window, &filter,
                                                   DEVICE_NOTIFY_WINDOW_HANDLE);
}

LRESULT CALLBACK windowProc(HWND window, UINT message, WPARAM wParam, LPARAM lParam) {
    // Explorer restarting wipes the tray; re-add on its broadcast.
    if (message == g_taskbarCreated && g_taskbarCreated != 0) {
        addTrayIcon();
        return 0;
    }

    switch (message) {
        case WM_TRAYICON:
            // With NOTIFYICON_VERSION_4 the event is in the low word of lParam
            // and the cursor position is in wParam.
            switch (LOWORD(lParam)) {
                case NIN_SELECT:
                case NIN_KEYSELECT:
                    if (g_devicePresent)
                        sendCommand(usbkvm::Command::switchAll());
                    else
                        refreshDeviceState();
                    return 0;

                case WM_CONTEXTMENU:
                    showContextMenu(GET_X_LPARAM(wParam), GET_Y_LPARAM(wParam));
                    return 0;

                default:
                    return 0;
            }

        case WM_COMMAND:
            switch (LOWORD(wParam)) {
                case IDM_SWITCH_ALL:
                    sendCommand(usbkvm::Command::switchAll());
                    return 0;
                case IDM_SWITCH_KVM:
                    sendCommand(usbkvm::Command::kvmSwitch());
                    return 0;
                case IDM_SWITCH_AUDIO:
                    sendCommand(usbkvm::Command::select(usbkvm::Target::Audio));
                    return 0;
                case IDM_SELECT_PC3:
                    sendCommand(usbkvm::Command::select(usbkvm::Target::Pc3));
                    return 0;
                case IDM_SELECT_PC4:
                    sendCommand(usbkvm::Command::select(usbkvm::Target::Pc4));
                    return 0;
                case IDM_SWITCH_OPT:
                    sendCommand(usbkvm::Command::optSwitch());
                    return 0;
                case IDM_RUN_AT_STARTUP:
                    setRunAtStartup(!runAtStartupEnabled());
                    return 0;
                case IDM_ABOUT:
                    showAbout();
                    return 0;
                case IDM_EXIT:
                    ::DestroyWindow(window);
                    return 0;
                default:
                    break;
            }
            break;

        case WM_DEVICECHANGE:
            if (wParam == DBT_DEVICEARRIVAL || wParam == DBT_DEVICEREMOVECOMPLETE ||
                wParam == DBT_DEVNODES_CHANGED) {
                ::SetTimer(window, kRefreshTimer, kRefreshDelayMs, nullptr);
            }
            return TRUE;

        case WM_TIMER:
            if (wParam == kRefreshTimer) {
                ::KillTimer(window, kRefreshTimer);
                refreshDeviceState();
            }
            return 0;

        case WM_SETTINGCHANGE:
            // Fired when the user flips between light and dark mode.
            if (lParam && ::lstrcmpiW(reinterpret_cast<LPCWSTR>(lParam),
                                      L"ImmersiveColorSet") == 0) {
                updateTrayIcon();
            }
            return 0;

        case WM_DPICHANGED:
            updateTrayIcon();
            return 0;

        case WM_DESTROY:
            ::PostQuitMessage(0);
            return 0;

        default:
            break;
    }

    return ::DefWindowProcW(window, message, wParam, lParam);
}

}  // namespace

int APIENTRY wWinMain(HINSTANCE instance, HINSTANCE, LPWSTR, int) {
    g_instance = instance;

    // One tray icon is enough; hand focus to whatever is already running.
    HANDLE mutex = ::CreateMutexW(nullptr, TRUE, kMutexName);
    if (mutex && ::GetLastError() == ERROR_ALREADY_EXISTS) {
        ::CloseHandle(mutex);
        return 0;
    }

    g_taskbarCreated = ::RegisterWindowMessageW(L"TaskbarCreated");

    WNDCLASSEXW windowClass{};
    windowClass.cbSize        = sizeof(windowClass);
    windowClass.lpfnWndProc   = windowProc;
    windowClass.hInstance     = instance;
    windowClass.lpszClassName = kWindowClass;
    // Gives the About box and any message boxes the full-colour app icon.
    windowClass.hIcon         = ::LoadIconW(instance, MAKEINTRESOURCEW(IDI_APP));
    windowClass.hIconSm       = windowClass.hIcon;

    if (!::RegisterClassExW(&windowClass)) {
        ::MessageBoxW(nullptr, L"Failed to register the window class.", kAppName,
                      MB_OK | MB_ICONERROR);
        return 1;
    }

    // A real (never shown) top-level window: TrackPopupMenu and WM_DEVICECHANGE
    // both need one. WS_EX_TOOLWINDOW keeps it off the taskbar and Alt-Tab.
    g_window = ::CreateWindowExW(WS_EX_TOOLWINDOW, kWindowClass, kAppName, WS_POPUP,
                                 0, 0, 0, 0, nullptr, nullptr, instance, nullptr);
    if (!g_window) {
        ::MessageBoxW(nullptr, L"Failed to create the message window.", kAppName,
                      MB_OK | MB_ICONERROR);
        return 1;
    }

    g_devicePresent = !usbkvm::enumerate().empty();
    addTrayIcon();
    registerDeviceNotifications();

    MSG message;
    while (::GetMessageW(&message, nullptr, 0, 0) > 0) {
        ::TranslateMessage(&message);
        ::DispatchMessageW(&message);
    }

    if (g_deviceNotify)
        ::UnregisterDeviceNotification(g_deviceNotify);

    removeTrayIcon();

    if (mutex)
        ::CloseHandle(mutex);

    return static_cast<int>(message.wParam);
}
