#!/usr/bin/env python3

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk


UI_FILE = "stack2.glade"

class GUI:
    def __init__(self):

        self.builder = Gtk.Builder()
        self.builder.add_from_file(UI_FILE)
        self.builder.connect_signals(self)

        window = self.builder.get_object('window')
        window.show_all()

    def on_window_destroy(self, window):
        Gtk.main_quit()

    def home_clicked (self, button):
        stack = self.builder.get_object('stack')
        home_button = self.builder.get_object('home_button')
        stack.set_visible_child(home_button)

    def button_clicked (self, button):
        stack = self.builder.get_object('stack')
        notebook_box = self.builder.get_object('notebook_box')
        stack.set_visible_child(notebook_box)

app = GUI()
Gtk.main()