#!/usr/bin/env python3

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk


UI_FILE = "stack_dcp_02.glade"

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
        label = self .builder.get_object('label0')
        stack.set_visible_child(label)
        page = stack.get_visible_child_name()
        print(page)

    def onButton1Clicked(self, button):
        stack = self.builder.get_object('stack1')
        label = self.builder.get_object('label1')
        stack.set_visible_child(label)
        page = stack.get_visible_child_name()
        print(page)

    def onButton2Clicked(self, button):
        stack = self.builder.get_object('stack1')
        label = self.builder.get_object('label2')
        stack.set_visible_child(label)
        page = stack.get_visible_child_name()
        print(page)

app = GUI()
Gtk.main()





# builder = Gtk.Builder()
# builder.add_from_file("stack_dcp_02.glade")

# class Handler:
#     def onDestroy(self, *args):
#         Gtk.main_quit()
    
#     def onButton0Clicked(self, button):
#         stack = builder.builder.get_object('stack1')
#         label0 = builder .builder.get_object('label0')
#         stack.set_visible_child(label0)

#     def onButton1Clicked(self, button):
#         stack = builder.builder.get_object('stack1')
#         label1 = builder.builder.get_object('label1')
#         stack.set_visible_child(label1)

#     def onButton2Clicked(self, button):
#         print("Hello!")


# # builder = Gtk.Builder()
# # builder.add_from_file("stack_dcp_02.glade")
# builder.connect_signals(Handler())

# window = builder.get_object("window1")
# window.show_all()

# Gtk.main()