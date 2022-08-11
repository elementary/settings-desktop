/*
* Copyright (c) 2011–2018 elementary, Inc. (https://elementary.io)
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

public class PantheonShell.Plug : Switchboard.Plug {
    private Gtk.Stack stack;
    private Gtk.Grid main_grid;

    private Wallpaper wallpaper_view;

    public Plug () {
        GLib.Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");

        var settings = new Gee.TreeMap<string, string?> (null, null);
        settings.set ("desktop", null);
        settings.set ("desktop/appearance/wallpaper", "wallpaper");
        settings.set ("desktop/appearance", "appearance");
        settings.set ("desktop/dock", "dock");
        settings.set ("desktop/multitasking", "multitasking");
        settings.set ("desktop/text", "text");

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/io/elementary/switchboard/plug/pantheon-shell/plug.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        // DEPRECATED
        settings.set ("desktop/wallpaper", "wallpaper");
        settings.set ("desktop/hot-corners", "multitasking");

        Object (category: Category.PERSONAL,
                code_name: "io.elementary.switchboard.pantheon-shell",
                display_name: _("Desktop"),
                description: _("Configure the dock, hot corners, and change wallpaper"),
                icon: "preferences-desktop-wallpaper",
                supported_settings: settings);
    }

    public override Gtk.Widget get_widget () {
        if (main_grid == null) {
            main_grid = new Gtk.Grid ();

            wallpaper_view = new Wallpaper (this);

            var multitasking = new Multitasking ();
            var appearance = new Appearance ();
            var text = new Text ();

            stack = new Gtk.Stack ();
            stack.add_titled (wallpaper_view, "wallpaper", _("Wallpaper"));
            stack.add_titled (appearance, "appearance", _("Appearance"));
            stack.add_titled (text, "text", _("Text"));

            if (GLib.Environment.find_program_in_path ("plank") != null) {
                var dock = new Dock ();
                stack.add_titled (dock, "dock", _("Dock & Panel"));
            }

            stack.add_titled (multitasking, "multitasking", _("Multitasking"));

            var stack_switcher = new Gtk.StackSwitcher ();
            stack_switcher.stack = stack;
            stack_switcher.halign = Gtk.Align.CENTER;
            stack_switcher.homogeneous = true;
            stack_switcher.margin = 24;

            main_grid.attach (stack_switcher, 0, 0, 1, 1);
            main_grid.attach (stack, 0, 1, 1, 1);
            main_grid.show_all ();
        }

        return main_grid;
    }

    public override void shown () {
        wallpaper_view.update_wallpaper_folder ();
    }

    public override void hidden () {
        wallpaper_view.cancel_thumbnail_generation ();
    }

    public override void search_callback (string location) {
        switch (location) {
            case "wallpaper":
                stack.set_visible_child_name ("wallpaper");
                break;
            case "appearance":
                stack.set_visible_child_name ("appearance");
                break;
            case "dock":
                stack.set_visible_child_name ("dock");
                break;
            case "text":
                stack.set_visible_child_name ("text");
                break;
            case "multitasking":
                stack.set_visible_child_name ("multitasking");
                break;
        }
    }

    // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
    public override async Gee.TreeMap<string, string> search (string search) {
        var search_results = new Gee.TreeMap<string, string> ();
        search_results.set ("%s → %s".printf (display_name, _("Wallpaper")), "wallpaper");
        search_results.set ("%s → %s".printf (display_name, _("Dock & Panel")), "dock");
        search_results.set ("%s → %s → %s".printf (display_name, _("Dock & Panel"), _("Hide Mode")), "dock");
        search_results.set ("%s → %s → %s".printf (display_name, _("Dock & Panel"), _("Icon Size")), "dock");
        search_results.set ("%s → %s → %s".printf (display_name, _("Dock & Panel"), _("Pressure reveal")), "dock");
        search_results.set ("%s → %s → %s".printf (display_name, _("Dock & Panel"), _("Display")), "dock");
        search_results.set ("%s → %s → %s".printf (display_name, _("Dock & Panel"), _("Panel translucency")), "dock");
        search_results.set ("%s → %s".printf (display_name, _("Appearance")), "appearance");
        search_results.set ("%s → %s → %s".printf (display_name, _("Appearance"), _("Dark style")), "appearance");
        search_results.set ("%s → %s → %s".printf (display_name, _("Appearance"), _("Accent color")), "appearance");
        search_results.set ("%s → %s".printf (display_name, _("Text")), "text");
        search_results.set ("%s → %s → %s".printf (display_name, _("Text"), _("Size")), "text");
        search_results.set ("%s → %s → %s".printf (display_name, _("Text"), _("Dyslexia-friendly")), "text");
        search_results.set ("%s → %s".printf (display_name, _("Multitasking")), "multitasking");
        search_results.set ("%s → %s → %s".printf (display_name, _("Multitasking"), _("Hot Corners")), "multitasking");
        search_results.set ("%s → %s → %s".printf (display_name, _("Multitasking"), _("Move windows to a new workspace")), "multitasking");
        search_results.set ("%s → %s → %s".printf (display_name, _("Multitasking"), _("Window animations")), "multitasking");
        return search_results;
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Desktop plug");
    var plug = new PantheonShell.Plug ();
    return plug;
}
