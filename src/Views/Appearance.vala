/*
* Copyright 2018–2021 elementary, Inc. (https://elementary.io)
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

public class PantheonShell.Appearance : Switchboard.SettingsPage {
    public Appearance () {
        Object (
            title: _("Appearance"),
            description : _("Apps may follow these preferences, but can choose their own accents or style."),
            icon: new ThemedIcon ("preferences-desktop-theme"),
            show_end_title_buttons: true
        );
    }

    construct {
        var default_preview = new DesktopPreview ("default");

        var prefer_default_radio = new Gtk.CheckButton () {
            action_name = "desktop-appearance.color-scheme",
            action_target = new Variant.string ("no-preference")
        };
        prefer_default_radio.add_css_class ("image-button");

        var prefer_default_grid = new Gtk.Grid ();
        prefer_default_grid.attach (default_preview, 0, 0);
        prefer_default_grid.attach (new Gtk.Label (_("Default")), 0, 1);
        prefer_default_grid.set_parent (prefer_default_radio);

        var dark_preview = new DesktopPreview ("dark");

        var prefer_dark_radio = new Gtk.CheckButton () {
            action_name = "desktop-appearance.color-scheme",
            action_target = new Variant.string ("prefer-dark"),
            group = prefer_default_radio
        };
        prefer_dark_radio.add_css_class ("image-button");

        var prefer_dark_grid = new Gtk.Grid ();
        prefer_dark_grid.attach (dark_preview, 0, 0);
        prefer_dark_grid.attach (new Gtk.Label (_("Dark")), 0, 1);
        prefer_dark_grid.set_parent (prefer_dark_radio);

        var prefer_style_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        prefer_style_box.append (prefer_default_radio);
        prefer_style_box.append (prefer_dark_radio);

        var dim_switch = new Granite.SwitchModelButton (_("Dim Wallpaper With Dark Style")) {
            margin_top = 18
        };

        var schedule_disabled_radio = new Gtk.CheckButton.with_label (_("Disabled")) {
            action_name = "desktop-appearance.prefer-dark-schedule",
            action_target = new Variant.string ("disabled"),
            margin_bottom = 3
        };

        var schedule_sunset_radio = new Gtk.CheckButton.with_label (
            _("Sunset to Sunrise")
        ) {
            action_name = "desktop-appearance.prefer-dark-schedule",
            action_target = new Variant.string ("sunset-to-sunrise"),
            group = schedule_disabled_radio
        };

        var from_label = new Gtk.Label (_("From:"));

        var from_time = new Granite.TimePicker () {
            hexpand = true,
            margin_end = 6
        };

        var to_label = new Gtk.Label (_("To:"));

        var to_time = new Granite.TimePicker () {
            hexpand = true
        };

        var schedule_manual_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        schedule_manual_box.append (from_label);
        schedule_manual_box.append (from_time);
        schedule_manual_box.append (to_label);
        schedule_manual_box.append (to_time);

        var schedule_manual_radio = new Gtk.CheckButton () {
            action_name = "desktop-appearance.prefer-dark-schedule",
            action_target = new Variant.string ("manual"),
            child = schedule_manual_box,
            group = schedule_disabled_radio
        };

        var schedule_box = new Gtk.Box (VERTICAL, 3) {
            accessible_role = LIST
        };
        schedule_box.append (schedule_disabled_radio);
        schedule_box.append (schedule_sunset_radio);
        schedule_box.append (schedule_manual_radio);

        var schedule_label = new Granite.HeaderLabel (_("Schedule")) {
            mnemonic_widget = schedule_box
        };

        var grid = new Gtk.Grid () {
            row_spacing = 6
        };
        grid.attach (prefer_style_box, 0, 2, 2);
        grid.attach (dim_switch, 0, 3, 2);
        grid.attach (schedule_label, 0, 4, 2);
        grid.attach (schedule_box, 0, 5, 2);

        var settings = new GLib.Settings ("io.elementary.settings-daemon.prefers-color-scheme");

        from_time.time = double_date_time (settings.get_double ("prefer-dark-schedule-from"));
        from_time.time_changed.connect (() => {
            settings.set_double ("prefer-dark-schedule-from", date_time_double (from_time.time));
        });
        to_time.time = double_date_time (settings.get_double ("prefer-dark-schedule-to"));
        to_time.time_changed.connect (() => {
            settings.set_double ("prefer-dark-schedule-to", date_time_double (to_time.time));
        });

        schedule_manual_radio.bind_property ("active", schedule_manual_box, "sensitive", BindingFlags.SYNC_CREATE);

        var accent_box = new Granite.Box (HORIZONTAL) {
            accessible_role = Gtk.AccessibleRole.LIST
        };

        Granite.AccentColor[] colors = {
            BLUE,
            TEAL,
            GREEN,
            YELLOW,
            ORANGE,
            RED,
            PINK,
            PURPLE,
            BROWN,
            GRAY,
            LATTE,
            AUTOMATIC
        };
        foreach (unowned var color in colors) {
            accent_box.append (new PrefersAccentColorButton (color));
        }

        var accent_label = new Granite.HeaderLabel (_("Accent Color")) {
            margin_top = 18,
            mnemonic_widget = accent_box
        };

        grid.attach (accent_label, 0, 8, 2);
        grid.attach (accent_box, 0, 9, 2);

        var animations_switch = new Granite.SwitchModelButton (_("Reduce Motion")) {
            description = _("Disable animations in the window manager and some other interface elements.")
        };

        var scrollbar_switch = new Granite.SwitchModelButton (_("Always Show Scrollbars")) {
            description = _("Scrollbars will take up space, even when not in use.")
        };

        var a11y_box = new Gtk.ListBox () {
            margin_top = 18,
            show_separators = true
        };
        a11y_box.add_css_class (Granite.CssClass.CARD);
        a11y_box.append (new Granite.ListItem () { child = animations_switch });
        a11y_box.append (new Granite.ListItem () { child = scrollbar_switch });

        grid.attach (a11y_box, 0, 10, 2);

        child = grid;
        add_css_class ("appearance-view");

        var interface_settings = new GLib.Settings ("org.gnome.desktop.interface");
        interface_settings.bind ("overlay-scrolling", scrollbar_switch, "active", INVERT_BOOLEAN);

        var a11y_settings = new GLib.Settings ("io.elementary.settings-daemon.a11y");
        a11y_settings.bind ("reduced-motion", animations_switch, "active", DEFAULT);

        var background_settings = new GLib.Settings ("io.elementary.desktop.background");
        background_settings.bind ("dim-wallpaper-in-dark-style", dim_switch, "active", DEFAULT);

        var accent_color_action = new GLib.Settings ("io.elementary.settings-daemon.interface").create_action ("accent-color");
        var color_scheme_action = settings.create_action ("color-scheme");
        var prefer_dark_action = settings.create_action ("prefer-dark-schedule");

        var action_group = new SimpleActionGroup ();
        action_group.add_action (accent_color_action);
        action_group.add_action (color_scheme_action);
        action_group.add_action (prefer_dark_action);

        insert_action_group ("desktop-appearance", action_group);
    }

    private class PrefersAccentColorButton : Gtk.CheckButton {
        public Granite.AccentColor color { get; construct; }

        public PrefersAccentColorButton (Granite.AccentColor color) {
            Object (color: color);
        }

        construct {
            tooltip_text = color.to_name ();
            if (color == AUTOMATIC) {
                tooltip_text = _("Automatic based on wallpaper");
            }

            var action_target_string = color.to_css_class ();
            action_target_string = action_target_string.replace ("teal", "mint");

            action_target = new Variant.string (action_target_string);
            action_name = "desktop-appearance.accent-color";

            accessible_role = Gtk.AccessibleRole.RADIO;
            add_css_class (Granite.CssClass.ACCENT);
            add_css_class (color.to_css_class ());

            update_property_value (
                {LABEL},
                {_("accent color")}
            );
        }
    }

    private static DateTime double_date_time (double dbl) {
        var hours = (int) dbl;
        var minutes = (int) Math.round ((dbl - hours) * 60);

        var date_time = new DateTime.local (1, 1, 1, hours, minutes, 0.0);

        return date_time;
    }

    private static double date_time_double (DateTime date_time) {
        double time_double = 0;
        time_double += date_time.get_hour ();
        time_double += (double) date_time.get_minute () / 60;

        return time_double;
    }

    private class DesktopPreview : Gtk.Widget {
        private static Settings pantheon_settings;
        private static Settings gnome_settings;
        private Gtk.Picture picture;

        class construct {
            set_css_name ("desktop-preview");
        }

        static construct {
            set_layout_manager_type (typeof (Gtk.BinLayout));

            pantheon_settings = new Settings ("io.elementary.desktop.background");
            gnome_settings = new Settings ("org.gnome.desktop.background");
        }

        public DesktopPreview (string style_class) {
            picture = new Gtk.Picture () {
                content_fit = COVER
            };

            var dock = new Gtk.Box (HORIZONTAL, 0) {
                halign = CENTER,
                valign = END
            };
            dock.add_css_class ("dock");

            var window_back = new Gtk.Box (HORIZONTAL, 0) {
                halign = CENTER,
                valign = CENTER
            };
            window_back.add_css_class ("window");
            window_back.add_css_class ("back");

            var window_front = new Gtk.Box (HORIZONTAL, 0) {
                halign = CENTER,
                valign = CENTER
            };
            window_front.add_css_class ("window");
            window_front.add_css_class ("front");

            var shell = new Gtk.Box (HORIZONTAL, 0);
            shell.add_css_class ("shell");

            var overlay = new Gtk.Overlay () {
                child = picture,
                overflow = HIDDEN
            };
            overlay.add_overlay (shell);
            overlay.add_overlay (dock);
            overlay.add_overlay (window_back);
            overlay.add_overlay (window_front);
            overlay.add_css_class (Granite.CssClass.CARD);

            var monitor = Gdk.Display.get_default ().get_monitor_at_surface (
                (((Gtk.Application) Application.get_default ()).active_window).get_surface ()
            );

            var monitor_ratio = (float) monitor.geometry.width / monitor.geometry.height;

            var frame = new Gtk.AspectFrame (0.5f, 0.5f, monitor_ratio, false) {
                child = overlay
            };
            frame.set_parent (this);

            add_css_class (style_class);

            update_picture ();
            gnome_settings.changed.connect (update_picture);

            if (has_css_class ("dark")) {
                update_dim ();
                pantheon_settings.changed.connect (update_dim);
            }
        }

        private void update_dim () {
            if (pantheon_settings.get_boolean ("dim-wallpaper-in-dark-style")) {
                add_css_class ("dim");
            } else {
                remove_css_class ("dim");
            }
        }

        private void update_picture () {
            if (gnome_settings.get_string ("picture-options") == "none") {
                Gdk.RGBA rgba = {};
                rgba.parse (gnome_settings.get_string ("primary-color"));

                var pixbuf = new Gdk.Pixbuf (RGB, false, 8, 500, 500);
                pixbuf.fill (PantheonShell.SolidColorContainer.rgba_to_pixel (rgba));

                picture.paintable = Gdk.Texture.for_pixbuf (pixbuf);
                return;
            }

            if (has_css_class ("dark")) {
                var dark_file = File.new_for_uri (
                    gnome_settings.get_string ("picture-uri-dark")
                );

                if (dark_file.query_exists ()) {
                    picture.file = dark_file;
                    return;
                }
            }

            picture.file = File.new_for_uri (
                gnome_settings.get_string ("picture-uri")
            );
        }

        ~DesktopPreview () {
            get_first_child ().unparent ();
        }
    }
}
