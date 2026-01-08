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
    private enum AccentColor {
        NO_PREFERENCE,
        RED,
        ORANGE,
        YELLOW,
        GREEN,
        MINT,
        BLUE,
        PURPLE,
        PINK,
        BROWN,
        GRAY,
        LATTE;

        public string to_string () {
            switch (this) {
                case RED:
                    return "strawberry";
                case ORANGE:
                    return "orange";
                case YELLOW:
                    return "banana";
                case GREEN:
                    return "lime";
                case MINT:
                    return "mint";
                case BLUE:
                    return "blueberry";
                case PURPLE:
                    return "grape";
                case PINK:
                    return "bubblegum";
                case BROWN:
                    return "cocoa";
                case GRAY:
                    return "slate";
                case LATTE:
                    return "latte";
                default:
                    return "auto";
            }
        }
    }

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

        var dim_switch = new Gtk.Switch () {
            valign = CENTER
        };

        var dim_label = new Granite.HeaderLabel (_("Dim Wallpaper With Dark Style")) {
            hexpand = true,
            mnemonic_widget = dim_switch
        };

        var dim_box = new Gtk.Box (HORIZONTAL, 12) {
            margin_top = 18
        };
        dim_box.append (dim_label);
        dim_box.append (dim_switch);

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

        Pantheon.AccountsService? pantheon_act = null;

        string? user_path = null;
        try {
            FDO.Accounts? accounts_service = GLib.Bus.get_proxy_sync (
                GLib.BusType.SYSTEM,
               "org.freedesktop.Accounts",
               "/org/freedesktop/Accounts"
            );

            user_path = accounts_service.find_user_by_name (GLib.Environment.get_user_name ());
        } catch (Error e) {
            critical (e.message);
        }

        if (user_path != null) {
            try {
                pantheon_act = GLib.Bus.get_proxy_sync (
                    GLib.BusType.SYSTEM,
                    "org.freedesktop.Accounts",
                    user_path,
                    GLib.DBusProxyFlags.GET_INVALIDATED_PROPERTIES
                );
            } catch (Error e) {
                warning ("Unable to get AccountsService proxy, color scheme preference may be incorrect");
            }
        }

        var grid = new Gtk.Grid () {
            row_spacing = 6
        };
        grid.attach (prefer_style_box, 0, 2, 2);
        grid.attach (dim_box, 0, 3, 2);
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

        var blueberry_button = new PrefersAccentColorButton (AccentColor.BLUE);
        blueberry_button.tooltip_text = _("Blueberry");

        var mint_button = new PrefersAccentColorButton (AccentColor.MINT, blueberry_button);
        mint_button.tooltip_text = _("Mint");

        var lime_button = new PrefersAccentColorButton (AccentColor.GREEN, blueberry_button);
        lime_button.tooltip_text = _("Lime");

        var banana_button = new PrefersAccentColorButton (AccentColor.YELLOW, blueberry_button);
        banana_button.tooltip_text = _("Banana");

        var orange_button = new PrefersAccentColorButton (AccentColor.ORANGE, blueberry_button);
        orange_button.tooltip_text = _("Orange");

        var strawberry_button = new PrefersAccentColorButton (AccentColor.RED, blueberry_button);
        strawberry_button.tooltip_text = _("Strawberry");

        var bubblegum_button = new PrefersAccentColorButton (AccentColor.PINK, blueberry_button);
        bubblegum_button.tooltip_text = _("Bubblegum");

        var grape_button = new PrefersAccentColorButton (AccentColor.PURPLE, blueberry_button);
        grape_button.tooltip_text = _("Grape");

        var cocoa_button = new PrefersAccentColorButton (AccentColor.BROWN, blueberry_button);
        cocoa_button.tooltip_text = _("Cocoa");

        var slate_button = new PrefersAccentColorButton (AccentColor.GRAY, blueberry_button);
        slate_button.tooltip_text = _("Slate");

        var latte_button = new PrefersAccentColorButton (AccentColor.LATTE, blueberry_button);
        latte_button.tooltip_text = _("Latte");

        var auto_button = new PrefersAccentColorButton (AccentColor.NO_PREFERENCE, blueberry_button);
        auto_button.tooltip_text = _("Automatic based on wallpaper");

        var accent_box = new Gtk.Box (HORIZONTAL, 6) {
            accessible_role = Gtk.AccessibleRole.LIST
        };
        accent_box.append (blueberry_button);
        accent_box.append (mint_button);
        accent_box.append (lime_button);
        accent_box.append (banana_button);
        accent_box.append (orange_button);
        accent_box.append (strawberry_button);
        accent_box.append (bubblegum_button);
        accent_box.append (grape_button);
        accent_box.append (cocoa_button);
        accent_box.append (slate_button);
        accent_box.append (latte_button);
        accent_box.append (auto_button);

        var accent_label = new Granite.HeaderLabel (_("Accent Color")) {
            margin_top = 18,
            mnemonic_widget = accent_box
        };

        grid.attach (accent_label, 0, 8, 2);
        grid.attach (accent_box, 0, 9, 2);

        var animations_switch = new Gtk.Switch () {
            halign = Gtk.Align.END,
            hexpand = true,
            valign = Gtk.Align.CENTER
        };

        var animations_label = new Granite.HeaderLabel (_("Reduce Motion")) {
            mnemonic_widget = animations_switch,
            secondary_text = _("Disable animations in the window manager and some other interface elements.")
        };

        var animations_box = new Gtk.Box (HORIZONTAL, 12) {
            margin_top = 18
        };
        animations_box.append (animations_label);
        animations_box.append (animations_switch);

        var scrollbar_switch = new Gtk.Switch () {
            valign = CENTER
        };

        var scrollbar_label = new Granite.HeaderLabel (_("Always Show Scrollbars")) {
            hexpand = true,
            mnemonic_widget = scrollbar_switch,
            secondary_text = _("Scrollbars will take up space, even when not in use.")
        };

        var scrollbar_box = new Gtk.Box (HORIZONTAL, 12) {
            margin_top = 18
        };
        scrollbar_box.append (scrollbar_label);
        scrollbar_box.append (scrollbar_switch);

        grid.attach (animations_box, 0, 10, 2);
        grid.attach (scrollbar_box, 0, 11, 2);

        child = grid;
        add_css_class ("appearance-view");

        // This key should be deprecated. Set only because interface settings is the source of truth
        var animations_settings = new Settings ("io.elementary.desktop.wm.animations");
        animations_switch.notify["active"].connect (() => {
            animations_settings.set_boolean ("enable-animations", !animations_switch.active);
        });

        var interface_settings = new GLib.Settings ("org.gnome.desktop.interface");
        interface_settings.bind ("overlay-scrolling", scrollbar_switch, "active", INVERT_BOOLEAN);
        interface_settings.bind ("enable-animations", animations_switch, "active", INVERT_BOOLEAN);

        var background_settings = new GLib.Settings ("io.elementary.desktop.background");
        background_settings.bind ("dim-wallpaper-in-dark-style", dim_switch, "active", DEFAULT);

        var accent_color_action = new SimpleAction.stateful ("prefers-accent-color", GLib.VariantType.INT32, new Variant.int32 (AccentColor.NO_PREFERENCE));

        var color_scheme_action = settings.create_action ("color-scheme");
        var prefer_dark_action = settings.create_action ("prefer-dark-schedule");

        var action_group = new SimpleActionGroup ();
        action_group.add_action (accent_color_action);
        action_group.add_action (color_scheme_action);
        action_group.add_action (prefer_dark_action);

        insert_action_group ("desktop-appearance", action_group);

        if (pantheon_act != null) {
            accent_color_action.set_state (new Variant.int32 (pantheon_act.prefers_accent_color));

            ((DBusProxy) pantheon_act).g_properties_changed.connect ((changed, invalid) => {
                var accent_color = changed.lookup_value ("PrefersAccentColor", new VariantType ("i"));
                if (accent_color != null && !accent_color_action.get_state ().equal (accent_color)) {
                    accent_color_action.set_state (accent_color);
                }
            });

            accent_color_action.activate.connect ((value) => {
                if (!accent_color_action.get_state ().equal (value)) {
                    accent_color_action.set_state (value);
                    pantheon_act.prefers_accent_color = value.get_int32 ();
                }
            });
        }
    }

    private class PrefersAccentColorButton : Gtk.CheckButton {
        public AccentColor color { get; construct; }

        public PrefersAccentColorButton (AccentColor color, Gtk.CheckButton? group_member = null) {
            Object (
                color: color,
                group: group_member
            );
        }

        construct {
            add_css_class (Granite.STYLE_CLASS_COLOR_BUTTON);
            add_css_class (color.to_string ());

            action_name = "desktop-appearance.prefers-accent-color";
            action_target = new Variant.int32 (color);
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
            overlay.add_css_class (Granite.STYLE_CLASS_CARD);
            overlay.add_css_class (Granite.STYLE_CLASS_ROUNDED);

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
