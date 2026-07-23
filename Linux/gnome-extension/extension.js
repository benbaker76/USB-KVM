// extension.js — GNOME Shell top bar control for ActionStar USB KVM switches.
//
// The Shell cannot link the C++ core directly, so every operation shells out to
// the kvmctl helper built from that same core. kvmctl speaks JSON on --json,
// which keeps the protocol knowledge in one place.

import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import St from 'gi://St';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

// How often to re-check whether the switch is attached.
const STATUS_POLL_SECONDS = 5;

// Switching makes the KVM hand the USB link to the other host, so the device
// disappears and comes back. Re-check shortly after issuing a command.
const POST_COMMAND_RECHECK_MS = 1200;

// Panel icons, mirroring the macOS app: the plain monitor when a switch is
// attached, the warning variant when it is not.
const ICON_CONNECTED = 'usbkvm-symbolic.svg';
const ICON_DISCONNECTED = 'usbkvm-error-symbolic.svg';

// Locations searched for the helper when it is not already on PATH.
const FALLBACK_HELPER_PATHS = [
    '/usr/local/bin/kvmctl',
    '/usr/bin/kvmctl',
];

/** Locates the kvmctl helper, or null if it is not installed. */
function findHelper() {
    const onPath = GLib.find_program_in_path('kvmctl');
    if (onPath)
        return onPath;

    for (const candidate of FALLBACK_HELPER_PATHS) {
        if (GLib.file_test(candidate, GLib.FileTest.IS_EXECUTABLE))
            return candidate;
    }

    return null;
}

/**
 * Runs kvmctl and resolves with its parsed JSON output.
 *
 * Resolves rather than rejects on a non-zero exit: kvmctl uses exit status to
 * report "no device", which is a normal state here, and still prints JSON.
 */
function runHelper(helper, args) {
    return new Promise(resolve => {
        let process;
        try {
            process = Gio.Subprocess.new(
                [helper, '--json', ...args],
                Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE);
        } catch (error) {
            resolve({ok: false, error: String(error)});
            return;
        }

        process.communicate_utf8_async(null, null, (source, result) => {
            try {
                const [, stdout, stderr] = source.communicate_utf8_finish(result);
                const text = (stdout ?? '').trim();

                if (!text) {
                    resolve({ok: false, error: (stderr ?? '').trim() || 'no output'});
                    return;
                }

                resolve(JSON.parse(text));
            } catch (error) {
                resolve({ok: false, error: String(error)});
            }
        });
    });
}

const UsbKvmIndicator = GObject.registerClass(
class UsbKvmIndicator extends PanelMenu.Button {
    _init(extension) {
        super._init(0.5, 'USB KVM', false);

        this._extension = extension;
        this._helper = findHelper();
        this._present = false;
        this._pollSource = null;
        this._recheckSource = null;

        const loadIcon = name => new Gio.FileIcon({
            file: Gio.File.new_for_path(
                GLib.build_filenamev([extension.path, 'icons', name])),
        });

        this._iconConnected = loadIcon(ICON_CONNECTED);
        this._iconDisconnected = loadIcon(ICON_DISCONNECTED);

        this._icon = new St.Icon({
            gicon: this._iconDisconnected,
            style_class: 'system-status-icon',
        });
        this.add_child(this._icon);

        this._buildMenu();
        this._setPresent(false);

        this._refreshStatus();
        this._pollSource = GLib.timeout_add_seconds(
            GLib.PRIORITY_DEFAULT, STATUS_POLL_SECONDS, () => {
                this._refreshStatus();
                return GLib.SOURCE_CONTINUE;
            });
    }

    _buildMenu() {
        this._statusItem = new PopupMenu.PopupMenuItem('Checking…', {
            reactive: false,
            style_class: 'popup-inactive-menu-item',
        });
        this.menu.addMenuItem(this._statusItem);
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        this._commandItems = [];

        const addCommand = (label, args) => {
            const item = new PopupMenu.PopupMenuItem(label);
            item.connect('activate', () => this._sendCommand(args));
            this.menu.addMenuItem(item);
            this._commandItems.push(item);
            return item;
        };

        addCommand('Switch All (video + USB + audio)', ['switch']);
        addCommand('Switch KVM only', ['kvm']);
        addCommand('Switch audio only', ['audio']);

        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        addCommand('Select PC 3', ['pc3']);
        addCommand('Select PC 4', ['pc4']);
        addCommand('Send OPT switch', ['opt']);
    }

    /** Primary click switches immediately; other buttons open the menu. */
    vfunc_event(event) {
        const type = event.type();

        if (type === Clutter.EventType.BUTTON_PRESS &&
            event.get_button() === Clutter.BUTTON_PRIMARY) {
            this._sendCommand(['switch']);
            return Clutter.EVENT_STOP;
        }

        if (type === Clutter.EventType.TOUCH_BEGIN) {
            this._sendCommand(['switch']);
            return Clutter.EVENT_STOP;
        }

        return super.vfunc_event(event);
    }

    _setPresent(present, detail) {
        this._present = present;
        this._icon.gicon = present ? this._iconConnected : this._iconDisconnected;

        for (const item of this._commandItems)
            item.setSensitive(present);

        if (!this._helper)
            this._statusItem.label.text = 'kvmctl helper not found';
        else if (present)
            this._statusItem.label.text = detail ?? 'Switch ready';
        else
            this._statusItem.label.text = detail ?? 'No switch detected';
    }

    async _refreshStatus() {
        if (!this._helper) {
            this._helper = findHelper();
            if (!this._helper) {
                this._setPresent(false);
                return;
            }
        }

        const result = await runHelper(this._helper, ['status']);

        if (result.present && result.accessible) {
            const device = result.device;
            const detail = device
                ? `Ready — ${device.vendorId}:${device.productId}`
                : 'Switch ready';
            this._setPresent(true, detail);
        } else if (result.present) {
            // Node exists but cannot be opened: almost always the udev rule.
            this._setPresent(false, 'Found, but no permission (install udev rule)');
        } else {
            this._setPresent(false);
        }
    }

    async _sendCommand(args) {
        if (!this._helper) {
            Main.notify('USB KVM', 'The kvmctl helper is not installed.');
            return;
        }

        if (!this._present)
            return;

        const result = await runHelper(this._helper, args);

        if (!result.ok && result.error)
            Main.notify('USB KVM', result.error);

        // The device re-enumerates after a switch; let it settle, then re-check.
        this._clearRecheck();
        this._recheckSource = GLib.timeout_add(
            GLib.PRIORITY_DEFAULT, POST_COMMAND_RECHECK_MS, () => {
                this._recheckSource = null;
                this._refreshStatus();
                return GLib.SOURCE_REMOVE;
            });
    }

    _clearRecheck() {
        if (this._recheckSource) {
            GLib.Source.remove(this._recheckSource);
            this._recheckSource = null;
        }
    }

    destroy() {
        if (this._pollSource) {
            GLib.Source.remove(this._pollSource);
            this._pollSource = null;
        }
        this._clearRecheck();

        super.destroy();
    }
});

export default class UsbKvmExtension extends Extension {
    enable() {
        this._indicator = new UsbKvmIndicator(this);
        Main.panel.addToStatusArea(this.uuid, this._indicator);
    }

    disable() {
        this._indicator?.destroy();
        this._indicator = null;
    }
}
