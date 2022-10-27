#!/usr/bin/env python3

# plaunch.py(Gtk desktop launcher)
# By Mike Leidel (2017)

import gi, csv
import webbrowser
import subprocess

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk


class DialogCloser(Gtk.Dialog):
  def __init__(self, Parent):
    Gtk.Dialog.__init__(self, "Close or Reload", None, 0, (Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OK, Gtk.ResponseType.OK))
    self.set_default_size(150, 100)
    label = Gtk.Label("Cancel = Reload App\nOK = Exit")
    box = self.get_content_area()
    box.add(label)
    self.show_all()


class Mainclass(Gtk.Window):


    css = """
    .css_window1 {
    background: #333333;
    }
    """

    def applyCSSdata(self, csstext):
        provider = Gtk.CssProvider()
        provider.load_from_data(bytes(csstext.encode()))
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)


    lbl = ['X'] * 21  # holds button label description
    pgm = ['X'] * 21  # holds command for that button


    def on_window1_destroy(self, object, data=None): Gtk.main_quit()

    def on_btn_close_clicked(self, object, data=None):
        dialog = DialogCloser(self)
        response = dialog.run()
        if response == Gtk.ResponseType.CANCEL:
            subprocess.call("./run.sh")
        elif response == Gtk.ResponseType.OK:
            dialog.destroy()
            Gtk.main_quit()

    def __init__(self):
        self.gladefile = "plaunchXX.glade"
        self.builder = Gtk.Builder()
        self.builder.add_from_file(self.gladefile)
        self.builder.connect_signals(self)
        self.window = self.builder.get_object("window1")
        #self.window.resize(400, 100)
        self.window.move(1790,20)
        # read settings file load arrays lbl and pgm
        n = 1
        with open('plaunch.dat') as csvfile:
            datreader = csv.reader(csvfile, delimiter='|')
            for item in datreader:
                name = "b" + str(n)
                obj = self.builder.get_object(name)
                # obj.set_label(item[0])
                self.lbl[n] = item[0]
                self.pgm[n] = item[1]
                n += 1
        self.applyCSSdata(self.css)
        self.window.show()

    def but_clicked(self, widget):
        butn = widget.get_label()
        key = self.lbl.index(butn)
        surl = str(self.pgm[key])
        if not surl.startswith('http'):
            print(surl)
        if surl.startswith("--app-id="):
            surl = ["/opt/google/chrome/google-chrome", "--profile-directory=Default", surl]
            subprocess.Popen(surl)
        else:
            webbrowser.open(surl)


if __name__ == "__main__":
    main = Mainclass()
    Gtk.main()