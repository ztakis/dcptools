#!/usr/bin/env python3

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

class InputPage(Gtk.Box):

    def __init__(self):
        Gtk.Box.__init__(self)
        self.grid = Gtk.Grid()
        self.grid.set_column_homogeneous(True)
        self.grid.set_row_homogeneous(True)
        self.add(self.grid)
        #Creating the ListStore model
        self.software_liststore = Gtk.ListStore(str, str, int)
        # for software_ref in software_list:
        #     self.software_liststore.append(list(software_ref))

        #creating the treeview, making it use the filter as a model, and adding the columns
        self.treeview = Gtk.TreeView()
        for i, column_title in enumerate(["Name", "Frequency", "Amplitude"]):
            renderer = Gtk.CellRendererText()
            column = Gtk.TreeViewColumn(column_title, renderer, text=i)
            self.treeview.append_column(column)

        #button.connect("clicked", self.on_selection_button_clicked)

        #setting up the layout, putting the treeview in a scrollwindow, and the buttons in a row
        self.scrollable_treelist = Gtk.ScrolledWindow()
        self.scrollable_treelist.set_vexpand(True)
        self.grid.attach(self.scrollable_treelist, 0, 0, 10, 7)

        #Toolbar
        list_add = Gtk.Button()
        list_add.add(Gtk.Image(icon_name='list-add-symbolic', visible=True))
        list_insert_object = Gtk.Button()
        list_insert_object.add(Gtk.Image(icon_name='insert-object-symbolic', visible=True))
        list_remove = Gtk.Button()
        list_remove.add(Gtk.Image(icon_name='list-remove-symbolic', visible=True))
        self.toolbar = Gtk.ButtonBox(spacing=5)
        self.toolbar.get_style_context().add_class('inline-toolbar')
        self.toolbar.add(list_add)
        self.toolbar.add(list_remove)
        self.toolbar.add(list_insert_object)
        self.toolbar.set_hexpand(True)
        self.grid.attach(self.toolbar, 0,7,4,1)
        #self.grid.attach_next_to(self.toolbar, self.scrollable_treelist, Gtk.PositionType.BOTTOM, 1, 1)
        # for i, button in enumerate(self.buttons[1:]):
            #self.grid.attach_next_to(button, self.buttons[i], Gtk.PositionType.RIGHT, 1, 1)
        self.scrollable_treelist.add(self.treeview)
        self.show_all()

win = InputPage()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()