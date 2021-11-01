/*
* Copyright 2021 elementary, Inc. (https://elementary.io)
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
*/

public class PantheonShell.Text : Gtk.Grid {
    private const string DYSLEXIA_KEY = "dyslexia-friendly-support";
    private const string FONT_KEY = "font-name";
    private const string DOCUMENT_FONT_KEY = "document-font-name";
    private const string MONOSPACE_FONT_KEY = "monospace-font-name";

    private const string OD_REG_FONT = "OpenDyslexic Regular 9";
    private const string OD_DOC_FONT = "OpenDyslexic Regular 10";
    private const string OD_MON_FONT = "OpenDyslexicMono Regular 10";

    construct {
        var text_size_label = new Gtk.Label (_("Size:")) {
            halign = Gtk.Align.END,
            valign = Gtk.Align.START
        };

        var text_size_adjustment = new Gtk.Adjustment (-1, 0.75, 1.5, 0.05, 0.05, 0.05);

        var text_size_scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, text_size_adjustment) {
            draw_value = false
        };
        text_size_scale.add_mark (0.75, Gtk.PositionType.BOTTOM, _("Small"));
        text_size_scale.add_mark (1, Gtk.PositionType.BOTTOM, _("Default"));
        text_size_scale.add_mark (1.25, Gtk.PositionType.BOTTOM, null);
        // Avoid rendering bug when putting mark at the very end
        text_size_scale.add_mark (1.45, Gtk.PositionType.BOTTOM, _("Largest"));

        var dyslexia_font_label = new Gtk.Label (_("Dyslexia-friendly:")) {
            halign = Gtk.Align.END,
            margin_top = 18
        };

        var dyslexia_font_switch = new Gtk.Switch () {
            halign = Gtk.Align.START,
            margin_top = 18
        };

        var dyslexia_font_description_label = new Gtk.Label (
            _("Bottom-heavy shapes and increased character spacing can help improve legibility and reading speed.")
        ) {
            max_width_chars = 60,
            wrap = true,
            xalign = 0
        };
        dyslexia_font_description_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        column_spacing = 12;
        halign = Gtk.Align.CENTER;
        row_spacing = 6;
        margin_start = margin_end = 12;
        margin_bottom = 24;
        attach (text_size_label, 0, 0);
        attach (text_size_scale, 1, 0, 2);
        attach (dyslexia_font_label, 0, 1);
        attach (dyslexia_font_switch, 1, 1);
        attach (dyslexia_font_description_label, 1, 2, 2);

        var interface_settings = new Settings ("org.gnome.desktop.interface");
        interface_settings.bind ("text-scaling-factor", text_size_adjustment, "value", SettingsBindFlags.GET);

        // Setting scale is slow, so we wait to keep UI responsive
        text_size_scale.button_release_event.connect (() => {
            interface_settings.set_double ("text-scaling-factor", text_size_scale.get_value ());
            return Gdk.EVENT_PROPAGATE;
        });

        dyslexia_font_switch.set_active (update_dyslexia_font_switch (interface_settings));

        dyslexia_font_switch.state_set.connect (() => {
            toggle_dyslexia_support (interface_settings, dyslexia_font_switch.get_active () );
        });
    }

    private void toggle_dyslexia_support (GLib.Settings interface_settings, bool state) {
        if (state == true) {
            interface_settings.set_string (FONT_KEY, OD_REG_FONT);
            interface_settings.set_string (DOCUMENT_FONT_KEY, OD_DOC_FONT);
            interface_settings.set_string (MONOSPACE_FONT_KEY, OD_MON_FONT);
        }
        else {
            interface_settings.reset (FONT_KEY);
            interface_settings.reset (DOCUMENT_FONT_KEY);
            interface_settings.reset (MONOSPACE_FONT_KEY);
        }
    }

    private bool update_dyslexia_font_switch (GLib.Settings interface_settings) {
        var interface_font = interface_settings.get_string (FONT_KEY);
        var document_font = interface_settings.get_string (DOCUMENT_FONT_KEY);
        var monospace_font = interface_settings.get_string (MONOSPACE_FONT_KEY);

        if (interface_font == OD_REG_FONT || document_font == OD_DOC_FONT || monospace_font == OD_MON_FONT ) {
            return true;
        }

        else {
            return false;
        }
    }
}
