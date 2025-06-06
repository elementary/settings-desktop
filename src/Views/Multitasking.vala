/*
* Copyright 2011-2019 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Tom Beckmann
*/

public class PantheonShell.Multitasking : Switchboard.SettingsPage {
    private GLib.Settings behavior_settings;

    public Multitasking () {
        Object (
            title: _("Multitasking"),
            icon: new ThemedIcon ("preferences-desktop-workspaces"),
            show_end_title_buttons: true
        );
    }

    construct {
        var hotcorner_title = new Granite.HeaderLabel (_("When the pointer enters a display corner")) {
            margin_bottom = 6
        };

        var topleft = new HotcornerControl (_("Top Left"), "topleft");
        var topright = new HotcornerControl (_("Top Right"), "topright");
        var bottomleft = new HotcornerControl (_("Bottom Left"), "bottomleft");
        var bottomright = new HotcornerControl (_("Bottom Right"), "bottomright");

        var fullscreen_hotcorner_switch = new Gtk.Switch () {
            valign = CENTER
        };

        var fullscreen_hotcorner_header = new Granite.HeaderLabel (_("Activate Hot Corners in fullscreen")) {
            secondary_text = _("May interfere with fullscreen video games, for example"),
            hexpand = true,
            mnemonic_widget = fullscreen_hotcorner_switch
        };

        var fullscreen_hotcorner_box = new Gtk.Box (HORIZONTAL, 12) {
            margin_top = 12
        };
        fullscreen_hotcorner_box.append (fullscreen_hotcorner_header);
        fullscreen_hotcorner_box.append (fullscreen_hotcorner_switch);

        var workspaces_label = new Granite.HeaderLabel (_("Move windows to a new workspace"));

        var fullscreen_checkbutton = new Gtk.CheckButton.with_label (_("When entering fullscreen"));
        var maximize_checkbutton = new Gtk.CheckButton.with_label (_("When maximizing"));

        var checkbutton_box = new Gtk.Box (HORIZONTAL, 12);
        checkbutton_box.append (fullscreen_checkbutton);
        checkbutton_box.append (maximize_checkbutton);

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 6
        };
        grid.attach (hotcorner_title, 0, 0, 2);
        grid.attach (topleft, 0, 1, 2);
        grid.attach (topright, 0, 2, 2);
        grid.attach (bottomleft, 0, 3, 2);
        grid.attach (bottomright, 0, 4, 2);
        grid.attach (fullscreen_hotcorner_box, 0, 6, 2);
        grid.attach (workspaces_label, 0, 7, 2);
        grid.attach (checkbutton_box, 0, 8, 2);

        child = grid;

        behavior_settings = new GLib.Settings ("io.elementary.desktop.wm.behavior");
        behavior_settings.bind ("enable-hotcorners-in-fullscreen", fullscreen_hotcorner_switch, "active", DEFAULT);
        behavior_settings.bind ("move-fullscreened-workspace", fullscreen_checkbutton, "active", GLib.SettingsBindFlags.DEFAULT);
        behavior_settings.bind ("move-maximized-workspace", maximize_checkbutton, "active", GLib.SettingsBindFlags.DEFAULT);
    }

    private class HotcornerControl : Gtk.Grid {
        public string label { get; construct; }
        public string position { get; construct; }

        private Gtk.Entry command_entry;
        private static Settings settings;
        private static Gtk.SizeGroup size_group;

        public HotcornerControl (string label, string position) {
            Object (
                label: label,
                position: position
            );
        }

        static construct {
            settings = new Settings ("io.elementary.desktop.wm.behavior");
            size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.BOTH);
        }

        construct {
            var label = new Gtk.Label (label) {
                max_width_chars = 12,
                wrap = true,
                wrap_mode = Pango.WrapMode.WORD_CHAR
            };

            label.add_css_class (Granite.STYLE_CLASS_CARD);
            label.add_css_class (Granite.STYLE_CLASS_ROUNDED);
            label.add_css_class ("hotcorner");
            label.add_css_class (position);

            var text_direction = get_default_direction ();

            var combo = new Gtk.ComboBoxText () {
                hexpand = true,
                valign = Gtk.Align.END
            };
            combo.append ("none", _("Do nothing"));
            combo.append ("show-workspace-view", _("Multitasking View"));
            combo.append ("maximize-current", _("Maximize current window"));
            // Only show Applications Menu hotcorner for the same panel corner
            if (
                position == "topleft" && text_direction == LTR ||
                position == "topright" && text_direction == RTL
            ) {
                combo.append ("open-launcher", _("Show Applications Menu"));
            }
            combo.append ("window-overview-all", _("Show all windows"));
            combo.append ("switch-to-workspace-previous", _("Switch to previous workspace"));
            combo.append ("switch-to-workspace-next", _("Switch to next workspace"));
            combo.append ("switch-to-workspace-last", _("Switch to new workspace"));
            combo.append ("custom-command", _("Execute custom command"));

            command_entry = new Gtk.Entry () {
                primary_icon_name = "utilities-terminal-symbolic",
            };

            var command_revealer = new Gtk.Revealer () {
                child = command_entry,
                margin_top = 6,
                transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
            };

            margin_bottom = 12;
            column_spacing = 12;
            attach (label, 0, 0, 1, 2);
            attach (combo, 1, 0);
            attach (command_revealer, 1, 1);

            size_group.add_widget (label);

            settings.bind ("hotcorner-" + position, combo, "active-id", SettingsBindFlags.DEFAULT);

            settings.bind_with_mapping (
                "hotcorner-" + position, command_revealer, "reveal-child", SettingsBindFlags.GET,
                (value, variant, user_data) => {
                    value.set_boolean (variant.get_string () == "custom-command");
                    return true;
                },
                (value, expected_type, user_data) => {
                    return new Variant.string ("custom-command");
                },
                null, null
            );

            settings.bind_with_mapping (
                "hotcorner-custom-command",
                command_entry,
                "text",
                DEFAULT,
                (value, variant, instance) => {
                    string[] commands = ((string) variant).split (";;");
                    foreach (unowned string command in commands) {
                        if (command.has_prefix ("hotcorner-" + ((HotcornerControl) instance).position)) {
                            value.set_string (command.replace ("hotcorner-%s:".printf (((HotcornerControl) instance).position), ""));
                            return true;
                        }
                    }

                    value.set_string ("");
                    return true;
                },
                (value, expected_type, instance) => {
                    var this_command = "hotcorner-%s:%s".printf (((HotcornerControl) instance).position, value.get_string ());

                    var setting_string = settings.get_string ("hotcorner-custom-command");

                    var found = false;
                    string[] commands = setting_string.split (";;");
                    for (int i = 0; i < commands.length ; i++) {
                        if (commands[i].has_prefix ("hotcorner-" + ((HotcornerControl) instance).position)) {
                            found = true;
                            commands[i] = this_command;
                        }
                    }

                    if (!found) {
                        commands += this_command;
                    }

                    return new Variant.string (string.joinv (";;", commands));
                },
                this, null
            );
        }
    }
}
