#!/usr/bin/env python3

import sys
import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gio

# This would typically be its own file
# MENU_XML = """
# <?xml version="1.0" encoding="UTF-8"?>
# <interface>
#   <menu id="sys-menu">
#     <section>
#         <item>
#             <attribute name="label">About</attribute>
#             <attribute name="action">app.about</attribute>
#         </item>
#         <item>
#             <attribute name="label">Quit</attribute>
#             <attribute name="action">app.quit</attribute>
#         </item>
#     </section>
#   </menu>
# </interface>
# """

# class HeaderBarWindow(Gtk.Window):
#     def __init__(self):
#         super().__init__(title="HeaderBar Demo")
#         self.set_border_width(10)
#         self.set_default_size(800, 480)

#         hb = Gtk.HeaderBar()
#         hb.set_show_close_button(True)
#         hb.props.title = "HeaderBar example"
#         self.set_titlebar(hb)

#         builder = Gtk.Builder.new_from_string(MENU_XML, -1)
#         menu = builder.get_object("sys-menu")

#         button = Gtk.MenuButton(menu_model=menu)
#         # button = Gtk.Button()
#         # icon = Gio.ThemedIcon(name="mail-send-receive-symbolic")
#         icon = Gio.ThemedIcon(name="preferences-system-symbolic")
#         image = Gtk.Image.new_from_gicon(icon, Gtk.IconSize.BUTTON)
#         button.add(image)
#         hb.pack_end(button)

#         box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
#         Gtk.StyleContext.add_class(box.get_style_context(), "linked")

#         home_button = Gtk.Button.new_from_icon_name("go-home", Gtk.IconSize.MENU)
#         box.add(home_button)

#         left_button = Gtk.Button()
#         left_button.add(Gtk.Arrow(arrow_type=Gtk.ArrowType.LEFT, shadow_type=Gtk.ShadowType.NONE))
#         left_button.set_sensitive(False)
#         box.add(left_button)

#         right_button = Gtk.Button()
#         right_button.add(Gtk.Arrow(arrow_type=Gtk.ArrowType.RIGHT, shadow_type=Gtk.ShadowType.NONE))
#         right_button.set_sensitive(True)
#         box.add(right_button)

#         # button = Gtk.Button.new_from_icon_name("pan-end-symbolic", Gtk.IconSize.MENU)
#         # box.add(button)

#         hb.pack_start(box)

#         self.add(Gtk.TextView())

class Application(Gtk.Application):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, application_id="org.example.myapp", **kwargs)
        self.window = None

    def do_startup(self):
        Gtk.Application.do_startup(self)

        action = Gio.SimpleAction(name="about")
        action.connect("activate", self.on_about)
        self.add_action(action)

        action = Gio.SimpleAction(name="quit")
        action.connect("activate", self.on_quit)
        self.add_action(action)

    def do_activate(self):
        # We only allow a single window and raise any existing ones
        if not self.window:
            # Windows are associated with the application
            # when the last one is closed the application shuts down
            self.window = win(application=self, title="HeaderBar Demo")

        self.window.present()

    def on_about(self, action, param):
        about_dialog = Gtk.AboutDialog(transient_for=self.window, modal=True)
        about_dialog.present()

    def on_quit(self, action, param):
        self.quit()

# win = HeaderBarWindow()
# win.connect("destroy", Gtk.main_quit)
# win.show_all()
# Gtk.main()

if __name__ == "__main__":
    app = Application()
    app.run(sys.argv)