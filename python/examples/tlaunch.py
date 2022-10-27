#!/usr/bin/env python3

# tlaunch.py (tkinter version of plaunch.py)
# By Mike Leidel 2018
# use: python3 tlaunch.py 125 592 1770 20 '#ffc443' &


from tkinter import *
from tkinter import font
import csv, webbrowser, subprocess, sys
from functools import partial

class Application(Frame):
    pgm = ['X'] * 32  # the "action" for each button

    def __init__(self, master=None):
        super().__init__(master)
        self.pack(pady=4)
        self.create_widgets()

    def create_widgets(self):
        myfont = font.Font(family="DejaVu Sans", size=9, weight='bold')
        # read settings file load arrays lbl and pgm
        n = 1
        with open('plaunch.dat') as csvfile:
            datreader = csv.reader(csvfile, delimiter='|')
            for item in datreader:
                self.pgm[n] = item[1]
                action_with_arg = partial(self.but_clicked, n)
                Button(self, command=action_with_arg, text=item[0],
                        font=myfont).grid(row=n, column=1, sticky=E+W)
                n += 1
            Button(self, command=exit, text='Close', font=myfont).grid(row=n, column=1, sticky=E+W)


    def but_clicked(self,n):
        surl = str(self.pgm[n])
        if not surl.startswith('http'):
          print(surl)
          if surl.startswith("--app-id="):
            surl = ["/opt/google/chrome/google-chrome", "--profile-directory=Default", surl]
          subprocess.Popen(surl)
        else:
          webbrowser.open(surl)

# make geometry string WxH+left+top from argv
if len(sys.argv) < 5:
    print("\n\nmissing geometry values: W H left top ['color']\n")
    exit()

bgc = '#cccccc'

if len(sys.argv) > 5:   # background color
    bgc = sys.argv[5]

strgeo = str(sys.argv[1]) + "x" + str(sys.argv[2]) + "+" + str(sys.argv[3]) + "+" + str(sys.argv[4])

root = Tk()
root.geometry(strgeo) # "125x592+1770+20"
root.overrideredirect(True) # removed window decorations
root.resizable(0,0) # no resize & removes maximize button
root.configure(background = bgc)

app = Application(master=root)
app.mainloop()