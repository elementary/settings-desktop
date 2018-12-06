/*
* Copyright (c) 2011-2016 elementary LLC. (http://launchpad.net/switchboard-plug-pantheon-shell)
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

public class HotCorners : Gtk.Grid {
    private Gtk.Revealer custom_command_revealer;
    private Gee.HashSet<string> keys_using_custom_command = new Gee.HashSet<string> ();
    private const string CUSTOM_COMMAND_ID = "5";

    construct {
        column_spacing = 12;
        row_spacing = 24;
        halign = Gtk.Align.CENTER;

        custom_command_revealer = new Gtk.Revealer ();

        var expl = new Gtk.Label (_("When the cursor enters the corner of the display:"));
        expl.get_style_context ().add_class ("h4");
        expl.halign = Gtk.Align.START;

        var topleft = create_hotcorner ();
        topleft.changed.connect (() => hotcorner_changed ("hotcorner-topleft", topleft));
        topleft.active_id = BehaviorSettings.get_default ().schema.get_enum ("hotcorner-topleft").to_string ();
        topleft.valign = Gtk.Align.START;

        var topright = create_hotcorner ();
        topright.changed.connect (() => hotcorner_changed ("hotcorner-topright", topright));
        topright.active_id = BehaviorSettings.get_default ().schema.get_enum ("hotcorner-topright").to_string ();
        topright.valign = Gtk.Align.START;

        var bottomleft = create_hotcorner ();
        bottomleft.changed.connect (() => hotcorner_changed ("hotcorner-bottomleft", bottomleft));
        bottomleft.active_id = BehaviorSettings.get_default ().schema.get_enum ("hotcorner-bottomleft").to_string ();
        bottomleft.valign = Gtk.Align.END;

        var bottomright = create_hotcorner ();
        bottomright.changed.connect (() => hotcorner_changed ("hotcorner-bottomright", bottomright));
        bottomright.active_id = BehaviorSettings.get_default ().schema.get_enum ("hotcorner-bottomright").to_string ();
        bottomright.valign = Gtk.Align.END;

        var icon = new Gtk.Grid ();
        icon.height_request = 198;
        icon.width_request = 292;
        icon.get_style_context ().add_class ("hotcorner-display");

        var custom_command = new Gtk.Entry ();
        custom_command.primary_icon_name = "utilities-terminal-symbolic";
        custom_command.text = BehaviorSettings.get_default ().hotcorner_custom_command;
        custom_command.changed.connect (() => BehaviorSettings.get_default ().hotcorner_custom_command = custom_command.text );

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

        attach (expl, 0, 0, 3, 1);
        attach (icon, 1, 1, 1, 3);
        attach (topleft, 0, 1, 1, 1);
        attach (topright, 2, 1, 1, 1);
        attach (bottomleft, 0, 3, 1, 1);
        attach (bottomright, 2, 3, 1, 1);
        attach (custom_command_revealer, 0, 4, 2, 1);
    }

    private void hotcorner_changed (string settings_key, Gtk.ComboBoxText combo) {
        BehaviorSettings.get_default ().schema.set_enum (settings_key, int.parse (combo.active_id));
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
