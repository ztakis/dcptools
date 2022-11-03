#!/usr/bin/env python3

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

UI_FILE = "stack_dcp_05.glade"

class Handler:
    def onDestroy(self, window):
        Gtk.main_quit()

    def onButton0Clicked(self, button):
        current_page = stack.get_visible_child()
        i = pages.index(current_page)
        if i == 0: return
        stack.set_visible_child(pages[i-1])

    def onButton1Clicked(self, button):
        current_page = stack.get_visible_child()
        i = pages.index(current_page)
        if i == len(pages) - 1: return
        stack.set_visible_child(pages[i+1])

    def onButton2Clicked(self, button):
        Gtk.main_quit()

builder = Gtk.Builder()
builder.add_from_file(UI_FILE)
builder.connect_signals(Handler())

win = builder.get_object("window1")
win.show_all()

def print_page(stack, gparamstring):
    page = stack.get_visible_child_name()
    print(page)
    
stack = builder.get_object('stack1')
stack.connect("notify::visible-child", print_page)

pages = stack.get_children()

print_page(stack,any)

Gtk.main()