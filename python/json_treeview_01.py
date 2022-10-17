#!/usr/bin/env python3

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

import os
import json

import sys
sys.path.insert(0, '/opt/dcptools/common')
# sys.path.append('/opt/dcptools/common')
from local_trims import trim_start, trim_end


os.system('rm /opt/dcptools/temp/lsblk_all.json')
os.system('/bin/lsblk -O --json > /opt/dcptools/temp/lsblk_all.json')

with open('/opt/dcptools/temp/lsblk_all.json', 'r') as file:
    all_disks = json.load(file)

if len(all_disks['blockdevices']) -trim_start -trim_end == 0:
    print("No disks found. Exiting...")
    exit()


class dcp_disk:
    def __init__(self, name, path, hotplug, model, serial, size, part_name, part_path, fsavail, fssize, fstype, fsused, fsusepercent, mountpoint, label):
        self.name = name
        self.path = path
        self.hotplug = hotplug
        self.model = model
        self.serial = serial
        self.size = size
        self.part_name = part_name
        self.part_path = part_path
        self.fsavail = fsavail
        self.fssize = fssize
        self.fstype = fstype
        self.fsused = fsused
        self.fsusepercent = fsusepercent
        self.mountpoint = mountpoint
        self.label = label


disk_list = []

from itertools import islice
for i in islice(all_disks['blockdevices'], trim_start, len(all_disks['blockdevices'])-trim_end):
    pass
    disk = dcp_disk(i['name'],
    i['path'],
    i['hotplug'],
    i['model'],
    i['serial'],
    i['size'],
    i['children'][0]['name'],
    i['children'][0]['path'],
    i['children'][0]['fsavail'],
    i['children'][0]['fssize'],
    i['children'][0]['fstype'],
    i['children'][0]['fsused'],
    i['children'][0]['fsuse%'],
    i['children'][0]['mountpoint'],
    i['children'][0]['label'])
    disk_list.append([disk.name, disk.path,  disk.hotplug, disk.model, disk.serial, disk.size, disk.part_name,
    disk.part_path, disk.label, disk.fstype, disk.fssize, disk.fsavail, disk.fsused, disk.fsusepercent, disk.mountpoint])


class TreeViewFilterWindow(Gtk.Window):
    def __init__(self):
        super().__init__(title="DCP disk copy")
        self.set_border_width(10)

        # Setting up the self.grid in which the elements are to be positioned
        self.grid = Gtk.Grid()
        self.grid.set_column_homogeneous(True)
        self.grid.set_row_homogeneous(True)
        self.add(self.grid)

        # Creating the ListStore model
        self.disk_liststore = Gtk.ListStore(str, str, bool, str, str, str, str, str, str, str, str, str, str, str, str)
        for j in disk_list:
            self.disk_liststore.append(list(j))

        # creating the treeview and adding the columns
        self.treeview = Gtk.TreeView(model=self.disk_liststore)
        for k, column_title in enumerate(
            ["Name", "Path", "Hotplug", "Model", "Serial number", "Size", "Partition", "Partition path",
            "label", "fstype", "fssize", "fsavail", "fsused", "fsuse%", "mountpoint"]):
            renderer = Gtk.CellRendererText()
            column = Gtk.TreeViewColumn(column_title, renderer, text=k)
            self.treeview.append_column(column)

        # creating buttons to filter by programming language, and setting up their events
        self.buttons = list()
        for lbl in ["  1  ", "  2  ", "  3  ", "  4  "]:
            button = Gtk.Button(label=lbl)
            self.buttons.append(button)

        # setting up the layout, putting the treeview in a scrollwindow, and the buttons in a row
        self.scrollable_treelist = Gtk.ScrolledWindow()
        self.scrollable_treelist.set_vexpand(True)
        self.grid.attach(self.scrollable_treelist, 0, 0, 8, 10)
        self.grid.attach_next_to(self.buttons[0], self.scrollable_treelist, Gtk.PositionType.BOTTOM, 1, 1)
        for m, button in enumerate(self.buttons[1:]):
            self.grid.attach_next_to(button, self.buttons[m], Gtk.PositionType.RIGHT, 1, 1)
        self.scrollable_treelist.add(self.treeview)
        self.show_all()


win = TreeViewFilterWindow()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()