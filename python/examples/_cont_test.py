#!/usr/bin/env python3

# import gi

# gi.require_version("Gtk", "3.0")
# from gi.repository import Gtk, Gdk


# class MyWindow(Gtk.Window):
#     def __init__(self):
#         super().__init__(title="Hello World")

#         self.box = Gtk.Box(spacing=6)
#         self.add(self.box)

#         self.button1 = Gtk.Button(label="Hello")
#         self.button1.connect("clicked", self.on_button1_clicked)
#         # self.add(self.button1)
#         self.box.pack_start(self.button1, True, True, 0)

#         self.button2 = Gtk.Button(label="Goodbye")
#         self.button2.connect("clicked", self.on_button2_clicked)
#         # self.add(self.button2)
#         self.box.pack_start(self.button2, True, True, 0)

#     def on_button1_clicked(self, widget):
#         print("Hello")

#     def on_button2_clicked(self, widget):
#         print("Goodbye")

# win = MyWindow()
# win.connect("destroy", Gtk.main_quit)
# win.show_all()
# Gtk.main()

# class GridWindow(Gtk.Window):
#     def __init__(self):

#         super().__init__(title="Grid Example")

#         button1 = Gtk.Button(label="Button 1")
#         button2 = Gtk.Button(label="Button 2")
#         button3 = Gtk.Button(label="Button 3")
#         button4 = Gtk.Button(label="Button 4")
#         button5 = Gtk.Button(label="Button 5")
#         button6 = Gtk.Button(label="Button 6")

#         grid = Gtk.Grid()
#         grid.add(button1)
#         grid.attach(button2, 1, 0, 2, 1)
#         grid.attach_next_to(button3, button1, Gtk.PositionType.BOTTOM, 1, 2)
#         grid.attach_next_to(button4, button3, Gtk.PositionType.RIGHT, 2, 1)
#         grid.attach(button5, 1, 2, 1, 1)
#         grid.attach_next_to(button6, button5, Gtk.PositionType.RIGHT, 1, 1)

#         self.add(grid)


# win = GridWindow()
# win.connect("destroy", Gtk.main_quit)
# win.show_all()
# Gtk.main()


# class MyWindow(Gtk.Window):
#     def __init__(self):
#         super().__init__(title="Simple Notebook Example")
#         self.set_border_width(3)

#         self.notebook = Gtk.Notebook()
#         self.add(self.notebook)

#         self.page1 = Gtk.Box()
#         self.page1.set_border_width(10)
#         self.page1.add(Gtk.Label(label="Default Page!"))
#         self.notebook.append_page(self.page1, Gtk.Label(label="Plain Title"))

#         self.page2 = Gtk.Box()
#         self.page2.set_border_width(10)
#         self.page2.add(Gtk.Label(label="A page with an image for a Title."))
#         self.notebook.append_page(
#             self.page2, Gtk.Image.new_from_icon_name("help-about", Gtk.IconSize.MENU)
#         )


# win = MyWindow()
# win.connect("destroy", Gtk.main_quit)
# win.show_all()
# Gtk.main()

# class FlowBoxWindow(Gtk.Window):
#     def __init__(self):
#         super().__init__(title="FlowBox Demo")
#         self.set_border_width(10)
#         self.set_default_size(300, 250)

#         header = Gtk.HeaderBar(title="Flow Box")
#         header.set_subtitle("Sample FlowBox app")
#         header.props.show_close_button = True

#         self.set_titlebar(header)

#         scrolled = Gtk.ScrolledWindow()
#         scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)

#         flowbox = Gtk.FlowBox()
#         flowbox.set_valign(Gtk.Align.START)
#         flowbox.set_max_children_per_line(30)
#         flowbox.set_selection_mode(Gtk.SelectionMode.NONE)

#         self.create_flowbox(flowbox)

#         scrolled.add(flowbox)

#         self.add(scrolled)
#         self.show_all()

#     def on_draw(self, widget, cr, data):
#         context = widget.get_style_context()

#         width = widget.get_allocated_width()
#         height = widget.get_allocated_height()
#         Gtk.render_background(context, cr, 0, 0, width, height)

#         r, g, b, a = data["color"]
#         cr.set_source_rgba(r, g, b, a)
#         cr.rectangle(0, 0, width, height)
#         cr.fill()

#     def color_swatch_new(self, str_color):
#         rgba = Gdk.RGBA()
#         rgba.parse(str_color)

#         button = Gtk.Button()

#         area = Gtk.DrawingArea()
#         area.set_size_request(24, 24)
#         area.connect("draw", self.on_draw, {"color": rgba})

#         button.add(area)

#         return button

#     def create_flowbox(self, flowbox):
#         colors = [
#             "AliceBlue",
#             "AntiqueWhite",
#             "AntiqueWhite1",
#             "AntiqueWhite2",
#             "AntiqueWhite3",
#             "AntiqueWhite4",
#             "aqua",
#             "aquamarine",
#             "aquamarine1",
#             "aquamarine2",
#             "aquamarine3",
#             "aquamarine4",
#             "azure",
#             "azure1",
#             "azure2",
#             "azure3",
#             "azure4",
#             "beige",
#             "bisque",
#             "bisque1",
#             "bisque2",
#             "bisque3",
#             "bisque4",
#             "black",
#             "BlanchedAlmond",
#             "blue",
#             "blue1",
#             "blue2",
#             "blue3",
#             "blue4",
#             "BlueViolet",
#             "brown",
#             "brown1",
#             "brown2",
#             "brown3",
#             "brown4",
#             "burlywood",
#             "burlywood1",
#             "burlywood2",
#             "burlywood3",
#             "burlywood4",
#             "CadetBlue",
#             "CadetBlue1",
#             "CadetBlue2",
#             "CadetBlue3",
#             "CadetBlue4",
#             "chartreuse",
#             "chartreuse1",
#             "chartreuse2",
#             "chartreuse3",
#             "chartreuse4",
#             "chocolate",
#             "chocolate1",
#             "chocolate2",
#             "chocolate3",
#             "chocolate4",
#             "coral",
#             "coral1",
#             "coral2",
#             "coral3",
#             "coral4",
#         ]

#         for color in colors:
#             button = self.color_swatch_new(color)
#             flowbox.add(button)


# win = FlowBoxWindow()
# win.connect("destroy", Gtk.main_quit)
# win.show_all()
# Gtk.main()

import gi
# Since a system can have multiple versions
# of GTK + installed, we want to make 
# sure that we are importing GTK + 3.
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk
  
  
class StackWindow(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title ="Geeks for Geeks")
        self.set_border_width(10)
  
        # Creating a box vertically oriented with a space of 100 pixel.
        vbox = Gtk.Box(orientation = Gtk.Orientation.VERTICAL, spacing = 100)
        self.add(vbox)
  
        # Creating stack, transition type and transition duration.
        stack = Gtk.Stack()
        stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        stack.set_transition_duration(500)
  
        # Creating the check button.
        checkbutton = Gtk.CheckButton("Yes")
        stack.add_titled(checkbutton, "check", "Check Button")
  
        # Creating label .
        label = Gtk.Label()
        label.set_markup("<big>Hello World</big>")
        stack.add_titled(label, "label", "Label")
  
        # Implementation of stack switcher.
        stack_switcher = Gtk.StackSwitcher()
        stack_switcher.set_stack(stack)
        # vbox.pack_start(stack_switcher, True, True, 0)
        vbox.pack_start(stack, True, True, 0)
        vbox.pack_start(stack_switcher, True, True, 0)
  
  
win = StackWindow()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()