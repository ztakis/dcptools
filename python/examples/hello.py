#!/usr/bin/env python3

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

window = Gtk.Window(title="Hello World")
# window.show()
# window.connect("destroy", Gtk.main_quit)
# Gtk.main()

# this is very close to how it's done in C using get_*/set_* accessors.
# window = Gtk.Window(Gtk.WindowType.TOPLEVEL)
# window.set_title("Hello")

# setting properties as keyword arguments to the constructor
# window = Gtk.Window(type=Gtk.WindowType.TOPLEVEL, title="Hello")

# set_properties() can be used to set properties after construction
# window = Gtk.Window()
# window.set_properties(title="Hello")

window.show()
window.connect("destroy", Gtk.main_quit)
Gtk.main()