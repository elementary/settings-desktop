/*
* Copyright (c) 2017 elementary LLC. (https://elementary.io)
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
* Authored by: David Hewitt <davidmhewitt@gmail.com>
*/

[DBus (name = "org.freedesktop.thumbnails.Thumbnailer1")]
interface PantheonShell.Thumbnailer : Object {
    public signal void ready (uint32 handle, string[] uris);
    public signal void finished (uint32 handle);
    public abstract uint32 queue (string[] uris, string [] mime_types, string flavor, string scheduler, uint32 dequeue) throws GLib.Error;
    public abstract void dequeue (uint32 handle) throws GLib.Error;
}

public class PantheonShell.ThumbnailGenerator {
    private const string THUMBNAILER_DBUS_ID = "org.freedesktop.thumbnails.Thumbnailer1";
    private const string THUMBNAILER_DBUS_PATH = "/org/freedesktop/thumbnails/Thumbnailer1";

    public delegate void ThumbnailReady ();
    public class ThumbnailReadyWrapper {
        public unowned ThumbnailReady cb { get; set; }
    }

    private static ThumbnailGenerator? instance = null;
    private Thumbnailer? thumbnailer = null;
    private Gee.HashMap<uint32, Gee.HashMap<string, ThumbnailReadyWrapper>> queued_delegates = new Gee.HashMap<uint32, Gee.HashMap<string, ThumbnailReadyWrapper>> ();
    private Gee.ArrayList<uint32> handles = new Gee.ArrayList<uint32> ();
    private Gee.HashMap<string, ThumbnailReadyWrapper> pending_delegates = new Gee.HashMap<string, ThumbnailReadyWrapper> ();
    private string pending_thumb_size = "normal";

    public static ThumbnailGenerator get_default () {
        if (instance == null) {
            instance = new ThumbnailGenerator ();
        }

        return instance;
    }

    public ThumbnailGenerator () {
        try {
            thumbnailer = Bus.get_proxy_sync (BusType.SESSION, THUMBNAILER_DBUS_ID, THUMBNAILER_DBUS_PATH);
            thumbnailer.ready.connect ((handle, uris) => {
                if (queued_delegates.has_key (handle)) {
                    var delegates = queued_delegates[handle];
                    foreach (var uri in uris) {
                        if (delegates.has_key (uri)) {
                            delegates[uri].cb ();
                        }
                    }
                }
            });

            thumbnailer.finished.connect ((handle) => {
                queued_delegates.unset (handle);
                handles.remove (handle);
            });
        } catch (Error e) {
            warning ("Unable to connect to system thumbnailer: %s", e.message);
        }
    }

    public void dequeue_all () {
        pending_delegates.clear ();

        foreach (var handle in handles) {
            try {
                thumbnailer.dequeue (handle);
            } catch (GLib.Error e) {
                warning ("Unable to tell thumbnailer to stop creating thumbnails: %s", e.message);
            }
        }
    }

    public void get_thumbnail (string uri, uint size, ThumbnailReady callback) {
        if (size > 128) {
            pending_thumb_size = "large";
        }

        if (thumbnailer != null) {
            var wrapper = new ThumbnailReadyWrapper ();
            wrapper.cb = callback;
            pending_delegates.set (uri, wrapper);
        }
    }

    public void queue_thumbnails () {
        if (thumbnailer == null || pending_delegates.is_empty) {
            return;
        }

        var delegates = pending_delegates;
        pending_delegates = new Gee.HashMap<string, ThumbnailReadyWrapper> ();

        var uris = delegates.keys.to_array ();
        var mime_types = new string[uris.length];

        for (var i = 0; i < uris.length; i++) {
            mime_types[i] = get_mime_type (uris[i]);
        }

        try {
            var handle = thumbnailer.queue (uris, mime_types, pending_thumb_size, "default", 0);
            handles.add (handle);
            queued_delegates.set (handle, delegates);
        } catch (GLib.Error e) {
            warning ("Unable to queue thumbnail generation: %s", e.message);
        }
    }

    private string get_mime_type (string uri) {
        try {
            return ContentType.guess (Filename.from_uri (uri), null, null);
        } catch (ConvertError e) {
            warning ("Error converting filename '%s' while guessing mime type: %s", uri, e.message);
            return "";
        }
    }
}
