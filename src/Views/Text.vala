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
    private const string TEXT_SIZE_KEY = "text-scaling-factor";

    private const string DYSLEXIA_KEY = "dyslexia-friendly-support";
    private const string FONT_KEY = "font-name";
    private const string DOCUMENT_FONT_KEY = "document-font-name";
    private const string MONOSPACE_FONT_KEY = "monospace-font-name";

    private const string OD_REG_FONT = "OpenDyslexic Regular 9";
    private const string OD_DOC_FONT = "OpenDyslexic Regular 10";
    private const string OD_MON_FONT = "OpenDyslexicMono Regular 10";

    private const double[] TEXT_SCALE = {0.75, 1, 1.25, 1.5};

    private Granite.Widgets.ModeButton text_size_modebutton;

    construct {
        var text_size_label = new Gtk.Label (_("Size:")) {
            halign = Gtk.Align.END
        };

        text_size_modebutton = new Granite.Widgets.ModeButton ();
        text_size_modebutton.append_text (_("Small"));
        text_size_modebutton.append_text (_("Default"));
        text_size_modebutton.append_text (_("Large"));
        text_size_modebutton.append_text (_("Larger"));

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
        attach (text_size_modebutton, 1, 0, 2);
        attach (dyslexia_font_label, 0, 1);
        attach (dyslexia_font_switch, 1, 1);
        attach (dyslexia_font_description_label, 1, 2, 2);

        var interface_settings = new Settings ("org.gnome.desktop.interface");
        var interface_font = interface_settings.get_string (FONT_KEY);
        var document_font = interface_settings.get_string (DOCUMENT_FONT_KEY);
        var monospace_font = interface_settings.get_string (MONOSPACE_FONT_KEY);

        text_size_modebutton.set_active (get_text_scale (interface_settings));

        interface_settings.changed.connect (() => {
            text_size_modebutton.set_active (get_text_scale (interface_settings));
        });

        text_size_modebutton.mode_changed.connect (() => {
            interface_settings.set_double (TEXT_SIZE_KEY, TEXT_SCALE[text_size_modebutton.selected]);
        });

        dyslexia_font_switch.active = interface_font == OD_REG_FONT || document_font == OD_DOC_FONT || monospace_font == OD_MON_FONT;

        dyslexia_font_switch.state_set.connect (() => {
            if (dyslexia_font_switch.active) {
                interface_settings.set_string (FONT_KEY, OD_REG_FONT);
                interface_settings.set_string (DOCUMENT_FONT_KEY, OD_DOC_FONT);
                interface_settings.set_string (MONOSPACE_FONT_KEY, OD_MON_FONT);
            } else {
                interface_settings.reset (FONT_KEY);
                interface_settings.reset (DOCUMENT_FONT_KEY);
                interface_settings.reset (MONOSPACE_FONT_KEY);
            }
        });
    }

    private int get_text_scale (GLib.Settings interface_settings) {
        double text_scaling_factor = interface_settings.get_double (TEXT_SIZE_KEY);

        if (text_scaling_factor <= TEXT_SCALE[0]) {
            return 0;
        } else if (text_scaling_factor <= TEXT_SCALE[1]) {
            return 1;
        } else if (text_scaling_factor <= TEXT_SCALE[2]) {
            return 2;
        } else {
            return 3;
        }
    }
}
