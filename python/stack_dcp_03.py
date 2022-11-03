#!/usr/bin/env python3

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

UI_FILE = "stack_dcp_03.glade"


class GUI:

    def __init__(self):
        self.builder = Gtk.Builder()
        self.builder.add_from_file(UI_FILE)
        self.builder.connect_signals(self)

        window = self.builder.get_object('window1')
        window.show_all()

    def onDestroy(self, window):
        Gtk.main_quit()

    def onButton0Clicked(self, button):
        stack = self.builder.get_object('stack1')
        pages = stack.get_children()
        current_page = stack.get_visible_child()
        i = pages.index(current_page)
        if i == 0: return
        stack.set_visible_child(pages[i-1])
        page = stack.get_visible_child_name()
        print(page)

    def onButton1Clicked(self, button):
        stack = self.builder.get_object('stack1')
        pages = stack.get_children()
        current_page = stack.get_visible_child()
        i = pages.index(current_page)
        if i == len(pages) - 1: return
        stack.set_visible_child(pages[i+1])
        page = stack.get_visible_child_name()
        print(page)

    def onButton2Clicked(self, button):
        Gtk.main_quit()


app = GUI()
Gtk.main()