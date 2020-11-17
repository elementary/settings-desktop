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

public class PantheonShell.Multitasking : Gtk.Grid {
    private GLib.Settings behavior_settings;
    private Gtk.Revealer custom_command_revealer;
    private Gee.HashSet<string> keys_using_custom_command = new Gee.HashSet<string> ();
    private const string CUSTOM_COMMAND_ID = "5";

    construct {
        column_spacing = 12;
        row_spacing = 6;
        halign = Gtk.Align.CENTER;

        behavior_settings = new GLib.Settings ("org.pantheon.desktop.gala.behavior");

        custom_command_revealer = new Gtk.Revealer ();

        var hotcorner_title = new Gtk.Label (_("When the cursor enters the corner of the display:")) {
            halign = Gtk.Align.START,
            margin_bottom = 6,
            margin_top = 6
        };
        hotcorner_title.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        var topleft = create_hotcorner ();
        topleft.changed.connect (() => hotcorner_changed ("hotcorner-topleft", topleft));
        topleft.active_id = behavior_settings.get_enum ("hotcorner-topleft").to_string ();
        topleft.valign = Gtk.Align.START;

        var topright = create_hotcorner ();
        topright.changed.connect (() => hotcorner_changed ("hotcorner-topright", topright));
        topright.active_id = behavior_settings.get_enum ("hotcorner-topright").to_string ();
        topright.valign = Gtk.Align.START;

        var bottomleft = create_hotcorner ();
        bottomleft.changed.connect (() => hotcorner_changed ("hotcorner-bottomleft", bottomleft));
        bottomleft.active_id = behavior_settings.get_enum ("hotcorner-bottomleft").to_string ();
        bottomleft.valign = Gtk.Align.END;

        var bottomright = create_hotcorner ();
        bottomright.changed.connect (() => hotcorner_changed ("hotcorner-bottomright", bottomright));
        bottomright.active_id = behavior_settings.get_enum ("hotcorner-bottomright").to_string ();
        bottomright.valign = Gtk.Align.END;

        var icon = new Gtk.Grid ();
        icon.height_request = 198;
        icon.width_request = 292;

        unowned Gtk.StyleContext icon_style_context = icon.get_style_context ();
        icon_style_context.add_class (Granite.STYLE_CLASS_CARD);
        icon_style_context.add_class ("hotcorner-display");
        icon_style_context.add_class (Granite.STYLE_CLASS_ROUNDED);

        var custom_command = new Gtk.Entry ();
        custom_command.primary_icon_name = "utilities-terminal-symbolic";

        var cc_label = new Gtk.Label (_("Custom command:"));

        var cc_grid = new Gtk.Grid ();
        cc_grid.column_spacing = column_spacing;
        cc_grid.halign = Gtk.Align.END;
        cc_grid.margin_top = 24;
        cc_grid.add (cc_label);
        cc_grid.add (custom_command);

        var cc_sizegroup = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        cc_sizegroup.add_widget (icon);
        cc_sizegroup.add_widget (custom_command);

        custom_command_revealer.add (cc_grid);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_bottom = 24,
            margin_top = 24
        };

        var workspaces_title = new Gtk.Label (_("Move windows to a new workspace:")) {
            halign = Gtk.Align.START,
            margin_bottom = 6
        };
        workspaces_title.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        var fullscreen_label = new Gtk.Label (_("When entering fullscreen:")) {
            halign = Gtk.Align.END
        };
        var fullscreen_switch = new Gtk.Switch () {
            halign = Gtk.Align.START
        };

        var maximize_label = new Gtk.Label (_("When maximizing:")) {
            halign = Gtk.Align.END
        };
        var maximize_switch = new Gtk.Switch () {
            halign = Gtk.Align.START
        };

        attach (hotcorner_title, 0, 0, 3);
        attach (icon, 1, 1, 1, 3);
        attach (topleft, 0, 1, 1, 1);
        attach (topright, 2, 1, 1, 1);
        attach (bottomleft, 0, 3, 1, 1);
        attach (bottomright, 2, 3, 1, 1);
        attach (custom_command_revealer, 0, 4, 2, 1);
        attach (separator, 0, 5, 3);
        attach (workspaces_title, 0, 6, 3);
        attach (fullscreen_label, 0, 7);
        attach (fullscreen_switch, 1, 7);
        attach (maximize_label, 0, 8);
        attach (maximize_switch, 1, 8);

        behavior_settings.bind ("hotcorner-custom-command", custom_command, "text", GLib.SettingsBindFlags.DEFAULT);
        behavior_settings.bind ("move-fullscreened-workspace", fullscreen_switch, "active", GLib.SettingsBindFlags.DEFAULT);
        behavior_settings.bind ("move-maximized-workspace", maximize_switch, "active", GLib.SettingsBindFlags.DEFAULT);
    }

    private void hotcorner_changed (string settings_key, Gtk.ComboBoxText combo) {
        behavior_settings.set_enum (settings_key, int.parse (combo.active_id));
        if (combo.active_id == CUSTOM_COMMAND_ID) {
            keys_using_custom_command.add (settings_key);
        } else {
            keys_using_custom_command.remove (settings_key);
        }

        custom_command_revealer.reveal_child = keys_using_custom_command.size > 0;
    }

    private Gtk.ComboBoxText create_hotcorner () {
        var box = new Gtk.ComboBoxText ();
        box.append ("0", _("Do nothing"));              // none
        box.append ("1", _("Multitasking View"));       // show-workspace-view
        box.append ("2", _("Maximize current window")); // maximize-current
        box.append ("4", _("Show Applications Menu"));  // open-launcher
        box.append ("7", _("Show all windows"));        // window-overview-all
        box.append ("8", _("Switch to new workspace")); // switch-new-workspace
        box.append (CUSTOM_COMMAND_ID, _("Execute custom command"));  // custom-command

        return box;
    }
}
