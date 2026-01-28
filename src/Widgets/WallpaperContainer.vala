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

public class PantheonShell.WallpaperContainer : Granite.Bin {
    public signal void trash ();

    // https://www.w3.org/WAI/WCAG21/Understanding/target-size.html
    private const int TOUCH_TARGET_WIDTH = 44;

    protected const int THUMB_WIDTH = 256;
    protected const int THUMB_HEIGHT = 144;
    protected Gtk.Picture image;

    private GLib.Menu menu_model;
    private GLib.SimpleAction remove_wallpaper_action;
    private Gtk.Revealer check_revealer;

    private Gtk.EventControllerKey menu_key_controller;
    private Gtk.GestureClick? click_controller;
    private Gtk.GestureLongPress? long_press_controller;
    private Gtk.PopoverMenu? context_menu;
    private string? thumb_path = null;

    public string? uri { get; set; default = null; }
    public uint64 creation_date = 0;

    public bool checked {
        get {
            return Gtk.StateFlags.CHECKED in get_state_flags ();
        } set {
            if (value) {
                parent.set_state_flags (Gtk.StateFlags.CHECKED, false);
                check_revealer.reveal_child = true;
            } else {
                parent.unset_state_flags (Gtk.StateFlags.CHECKED);
                check_revealer.reveal_child = false;
            }

            queue_draw ();
        }
    }

    construct {
        image = new Gtk.Picture () {
            content_fit = COVER,
            height_request = THUMB_HEIGHT
        };
        image.add_css_class (Granite.CssClass.CARD);

        var check = new Gtk.CheckButton () {
            active = true,
            halign = START,
            valign = START,
            can_focus = false,
            can_target = false
        };

        check_revealer = new Gtk.Revealer () {
            child = check,
            transition_type = CROSSFADE
        };

        var overlay = new Gtk.Overlay () {
            child = image
        };
        overlay.add_overlay (check_revealer);

        halign = CENTER;
        valign = CENTER;

        // So we can receive key events
        focusable = true;
        child = overlay;

        remove_wallpaper_action = new SimpleAction ("trash", null);
        remove_wallpaper_action.activate.connect (() => trash ());

        var action_group = new SimpleActionGroup ();
        action_group.add_action (remove_wallpaper_action);

        insert_action_group ("wallpaper", action_group);

        menu_model = new Menu ();
        menu_model.append (_("Remove"), "wallpaper.trash");

        notify["uri"].connect (construct_from_uri);
    }

    private void construct_from_uri () {
        if (uri == null) {
            remove_controller (click_controller);
            remove_controller (long_press_controller);
            remove_controller (menu_key_controller);

            click_controller = null;
            long_press_controller = null;
            menu_key_controller = null;

            context_menu.unparent ();
            context_menu = null;

            return;
        }

        var file = File.new_for_uri (uri);
        try {
            var info = file.query_info ("*", FileQueryInfoFlags.NONE);

            thumb_path = info.get_attribute_as_string (FileAttribute.THUMBNAIL_PATH);

            if (thumb_path != null && info.get_attribute_boolean (FileAttribute.THUMBNAIL_IS_VALID)) {
                update_thumb.begin ();
            } else {
                generate_and_load_thumb ();
            }

            creation_date = info.get_attribute_uint64 (GLib.FileAttribute.TIME_CREATED);
            remove_wallpaper_action.set_enabled (info.get_attribute_boolean (GLib.FileAttribute.ACCESS_CAN_DELETE));
        } catch (Error e) {
            critical (e.message);
        }

        context_menu = new Gtk.PopoverMenu.from_model (menu_model) {
            halign = START,
            has_arrow = false
        };
        context_menu.set_parent (this);

        click_controller = new Gtk.GestureClick () {
            button = 0,
            exclusive = true
        };
        click_controller.pressed.connect ((n_press, x, y) => {
            var sequence = click_controller.get_current_sequence ();
            var event = click_controller.get_last_event (sequence);

            if (event.triggers_context_menu ()) {
                context_menu.halign = START;
                menu_popup_at_pointer (context_menu, x, y);

                click_controller.set_state (CLAIMED);
                click_controller.reset ();
            }
        });

        long_press_controller = new Gtk.GestureLongPress () {
            touch_only = true
        };
        long_press_controller.pressed.connect ((x, y) => {
            // Try to keep menu from under your hand
            if (x > get_root ().get_width () / 2) {
                context_menu.halign = END;
                x -= TOUCH_TARGET_WIDTH;
            } else {
                context_menu.halign = START;
                x += TOUCH_TARGET_WIDTH;
            }

            menu_popup_at_pointer (context_menu, x, y - (TOUCH_TARGET_WIDTH * 0.75));
        });

        menu_key_controller = new Gtk.EventControllerKey ();
        menu_key_controller.key_released.connect ((keyval, keycode, state) => {
            var mods = state & Gtk.accelerator_get_default_mod_mask ();
            switch (keyval) {
                case Gdk.Key.F10:
                    if (mods == Gdk.ModifierType.SHIFT_MASK) {
                        menu_popup_on_keypress (context_menu);
                    }
                    break;
                case Gdk.Key.Menu:
                case Gdk.Key.MenuKB:
                    menu_popup_on_keypress (context_menu);
                    break;
                default:
                    return;
            }
        });

        add_controller (click_controller);
        add_controller (long_press_controller);
        add_controller (menu_key_controller);
    }

    private void menu_popup_on_keypress (Gtk.PopoverMenu popover) {
        popover.halign = END;
        popover.set_pointing_to (Gdk.Rectangle () {
            x = (int) get_width (),
            y = (int) get_height () / 2
        });
        popover.popup ();
    }

    private void menu_popup_at_pointer (Gtk.PopoverMenu popover, double x, double y) {
        var rect = Gdk.Rectangle () {
            x = (int) x,
            y = (int) y
        };
        popover.pointing_to = rect;
        popover.popup ();
    }

    private void generate_and_load_thumb () {
        ThumbnailGenerator.get_default ().get_thumbnail (uri, THUMB_WIDTH * scale_factor, () => {
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

    private async void update_thumb () {
        if (thumb_path == null) {
            return;
        }

        image.set_filename (thumb_path);

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
                try {
                    var artist_name = metadata.try_get_tag_string ("Exif.Image.Artist");
                    if (artist_name != null) {
                        tooltip_text = _("Artist: %s").printf (artist_name);
                    }
                } catch (Error e) {
                    critical ("Unable to set wallpaper artist name: %s", e.message);
                }
            }
        }
    }
}
