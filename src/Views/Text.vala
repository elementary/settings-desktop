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

public class PantheonShell.Text : Switchboard.SettingsPage {
    private uint scale_timeout;

    public Text () {
        Object (
            title: _("Text"),
            icon: new ThemedIcon ("preferences-desktop-font"),
            show_end_title_buttons: true
        );
    }

    construct {
        var mono_filter = new Gtk.BoolFilter (
            new Gtk.PropertyExpression (typeof (Pango.FontFamily), null, "is-monospace")
        );

        var noto_filter = new Gtk.CustomFilter (noto_filter_func);

        var mono_font_filter = new Gtk.EveryFilter ();
        mono_font_filter.append (noto_filter);
        mono_font_filter.append (mono_filter);

        var default_font_dialog = new Gtk.FontDialog () {
            filter = noto_filter,
            language = Pango.Language.get_default ()
        };

        var default_font_button = new Gtk.FontDialogButton (default_font_dialog) {
            use_font = true,
            use_size = true,
            level = FAMILY
        };

        var default_font_label = new Granite.HeaderLabel (_("Interface Font")) {
            secondary_text = _("The default font used throughout the operating system."),
            mnemonic_widget = default_font_button
        };

        var mono_font_dialog = new Gtk.FontDialog () {
            filter = mono_font_filter
        };

        var mono_font_button = new Gtk.FontDialogButton (mono_font_dialog) {
            use_font = true,
            use_size = true,
            level = FAMILY
        };

        var mono_font_label = new Granite.HeaderLabel (_("Monospace Font")) {
            secondary_text = _("Used in Code and Terminal for example."),
            mnemonic_widget = mono_font_button
        };

        var font_box = new Granite.Box (VERTICAL, HALF);
        font_box.append (default_font_label);
        font_box.append (default_font_button);
        font_box.append (mono_font_label);
        font_box.append (mono_font_button);

        var size_label = new Granite.HeaderLabel (_("Size"));

        var size_adjustment = new Gtk.Adjustment (-1, 0.75, 1.5, 0.05, 0, 0);

        var size_scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, size_adjustment) {
            draw_value = false,
            hexpand = true
        };
        size_scale.add_mark (1, Gtk.PositionType.TOP, null);
        size_scale.add_mark (1.25, Gtk.PositionType.TOP, null);

        var size_spinbutton = new Gtk.SpinButton (size_adjustment, 0.25, 2) {
            valign = CENTER
        };

        var size_grid = new Gtk.Grid () {
            column_spacing = 12
        };
        size_grid.attach (size_label, 0, 0);
        size_grid.attach (size_scale, 0, 1);
        size_grid.attach (size_spinbutton, 1, 1);

        var box = new Granite.Box (VERTICAL, DOUBLE);
        box.append (font_box);
        box.append (size_grid);

        child = box;

        var interface_settings = new Settings ("org.gnome.desktop.interface");
        interface_settings.bind ("text-scaling-factor", size_adjustment, "value", SettingsBindFlags.GET);

        // Setting scale is slow, so we wait while pressed to keep UI responsive
        size_adjustment.value_changed.connect (() => {
            if (scale_timeout != 0) {
                GLib.Source.remove (scale_timeout);
            }

            scale_timeout = Timeout.add (300, () => {
                scale_timeout = 0;
                interface_settings.set_double ("text-scaling-factor", size_adjustment.value);
                return false;
            });
        });

        interface_settings.bind_with_mapping (
            "font-name", default_font_button, "font-desc", DEFAULT,
            (SettingsBindGetMappingShared) to_fontbutton_fontdesc,
            (SettingsBindSetMappingShared) from_fontbutton_fontdesc,
            new Variant.int32 (9), null
        );

        interface_settings.bind_with_mapping (
            "monospace-font-name", mono_font_button, "font-desc", DEFAULT,
            (SettingsBindGetMappingShared) to_fontbutton_fontdesc,
            (SettingsBindSetMappingShared) from_fontbutton_fontdesc,
            new Variant.int32 (10), null
        );
    }

    private static bool to_fontbutton_fontdesc (Value font_desc, Variant settings_value, void* user_data) {
        string font = settings_value.get_string ();
        var desc = Pango.FontDescription.from_string (font);
        font_desc.set_boxed (desc);
        return true;
    }

    private static Variant from_fontbutton_fontdesc (Value font_desc, VariantType expected_type, void* user_data) {
        var desc = (Pango.FontDescription) font_desc.get_boxed ();
        var font_string = "%s %i".printf (desc.to_string (), ((Variant) user_data).get_int32 ());
        return new Variant.string (font_string);
    }

    private static bool noto_filter_func (Object item) {
        var font_family = ((Pango.FontFamily) item);
        return !font_family.get_name ().contains ("Noto");
    }
}
