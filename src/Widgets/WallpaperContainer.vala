/*-
 * Copyright 2015-2022 elementary, Inc. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Erasmo Marín
 *
 */

public class PantheonShell.WallpaperContainer : Gtk.FlowBoxChild {
    public signal void trash ();

    protected const int THUMB_WIDTH = 162;
    protected const int THUMB_HEIGHT = 100;

    private static Gtk.CssProvider check_css_provider;
    private static Gtk.CheckButton check_group; // used for turning CheckButtons into RadioButtons

    private Gtk.Box card_box;
    private Gtk.Popover context_menu;
    private Gtk.GestureClick overlay_event_controller;
    private Gtk.Revealer check_revealer;
    protected Gtk.Picture image;

    public string? thumb_path { get; construct set; }
    public bool thumb_valid { get; construct; }
    public string uri { get; construct; }
    public uint64 creation_date = 0;

    private int scale;

    public bool checked {
        get {
            return Gtk.StateFlags.CHECKED in get_state_flags ();
        } set {
            if (value) {
                card_box.set_state_flags (Gtk.StateFlags.CHECKED, false);
                check_revealer.reveal_child = true;
            } else {
                card_box.unset_state_flags (Gtk.StateFlags.CHECKED);
                check_revealer.reveal_child = false;
            }

            queue_draw ();
        }
    }

    public bool selected {
        get {
            return Gtk.StateFlags.SELECTED in get_state_flags ();
        } set {
            if (value) {
                set_state_flags (Gtk.StateFlags.SELECTED, false);
            } else {
                unset_state_flags (Gtk.StateFlags.SELECTED);
            }

            queue_draw ();
        }
    }

    public WallpaperContainer (string uri, string? thumb_path, bool thumb_valid) {
        Object (uri: uri, thumb_path: thumb_path, thumb_valid: thumb_valid);
    }

    static construct {
        check_css_provider = new Gtk.CssProvider ();
        check_css_provider.load_from_resource ("/io/elementary/switchboard/plug/pantheon-shell/Check.css");

        check_group = new Gtk.CheckButton ();
    }

    construct {
        image = new Gtk.Picture () {
            can_shrink = true
        };

        card_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            overflow = Gtk.Overflow.HIDDEN
        };
        card_box.add_css_class (Granite.STYLE_CLASS_CARD);
        card_box.add_css_class (Granite.STYLE_CLASS_ROUNDED);
        card_box.append (image);

        var check = new Gtk.CheckButton () {
            halign = Gtk.Align.START,
            valign = Gtk.Align.START,
            focusable = false,
            active = true,
            group = check_group
        };
        check.notify["active"].connect (() => {
            check.active = true;
        });
        check.get_style_context ().add_provider (check_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);

        check_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = check
        };

        var overlay = new Gtk.Overlay () {
            child = card_box,
            halign = Gtk.Align.CENTER
        };

        overlay.add_overlay (check_revealer);

        overlay_event_controller = new Gtk.GestureClick ();
        overlay.add_controller (overlay_event_controller);

        add_css_class ("wallpaper-container");
        child = overlay;

        if (uri != null) {
            var move_to_trash = new Gtk.Button.with_label (_("Remove"));
            move_to_trash.clicked.connect (() => trash ());

            var file = File.new_for_uri (uri);
            try {
                var info = file.query_info ("*", FileQueryInfoFlags.NONE);
                creation_date = info.get_attribute_uint64 (GLib.FileAttribute.TIME_CREATED);
                move_to_trash.sensitive = info.get_attribute_boolean (GLib.FileAttribute.ACCESS_CAN_DELETE);
            } catch (Error e) {
                critical (e.message);
            }

            context_menu = new Gtk.Popover () {
                child = move_to_trash
            };
        }

        activate.connect (() => {
            checked = true;
        });

        overlay_event_controller.pressed.connect (show_context_menu);

        scale = get_style_context ().get_scale ();
        try {
            if (uri != null) {
                if (thumb_path != null && thumb_valid) {
                    update_thumb.begin ();
                } else {
                    generate_and_load_thumb ();
                }
            } else {
                image.set_pixbuf (new Gdk.Pixbuf (Gdk.Colorspace.RGB, false, 8, THUMB_WIDTH * scale, THUMB_HEIGHT * scale));
            }
        } catch (Error e) {
            critical ("Failed to load wallpaper thumbnail: %s", e.message);
            return;
        }
    }

    private void generate_and_load_thumb () {
        ThumbnailGenerator.get_default ().get_thumbnail (uri, THUMB_WIDTH * scale, () => {
            try {
                var file = File.new_for_uri (uri);
                var info = file.query_info (FileAttribute.THUMBNAIL_PATH + "," + FileAttribute.THUMBNAIL_IS_VALID, 0);
                thumb_path = info.get_attribute_as_string (FileAttribute.THUMBNAIL_PATH);
                update_thumb.begin ();
            } catch (Error e) {
                warning ("Error loading thumbnail for '%s': %s", uri, e.message);
            }
        });
    }

    private void load_artist_tooltip () {
        if (uri != null) {
            string path = "";
            GExiv2.Metadata metadata;
            try {
                path = Filename.from_uri (uri);
                metadata = new GExiv2.Metadata ();
                metadata.open_path (path);
            } catch (Error e) {
                warning ("Error parsing exif metadata of \"%s\": %s", path, e.message);
                return;
            }

            if (metadata.has_exif ()) {
                string? artist_name = null;
                try {
                    artist_name = metadata.try_get_tag_string ("Exif.Image.Artist");
                } catch (Error e) {
                    warning (e.message);
                }

                if (artist_name != null) {
                    set_tooltip_text (_("Artist: %s").printf (artist_name));
                }
            }
        }
    }

    private void show_context_menu (int n_press, double x, double y) {
        var evt = overlay_event_controller.get_current_event ();
        if (evt.get_event_type () == Gdk.EventType.BUTTON_PRESS && evt.get_modifier_state () == Gdk.ModifierType.BUTTON3_MASK) {
            context_menu.popup ();
            // return Gdk.EVENT_STOP;
        }
        // return Gdk.EVENT_PROPAGATE;
    }

    private async void update_thumb () {
        if (thumb_path == null) {
            return;
        }

        image.set_filename (thumb_path);

        load_artist_tooltip ();
    }
}
