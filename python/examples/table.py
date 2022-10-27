#!/usr/bin/env python3

# Python program to create a table

from tkinter import *

class Table:
    def __init__(self,root):
        # code for creating table
        for i in range(total_rows):
            for j in range(total_columns):
                self.e = Entry(root, width=16)
                # self.e = Entry(root, width=20, fg='blue', font=('Arial',16,'bold'))
                self.e.grid(row=i, column=j)
                self.e.insert(END, lst[i][j])

# take the data
lst = [['sda','478GB','WD567F83042','b12_p1','/media/akis/test'],
    ['sdb','478GB','WD567F83042','b12_p2','/media/akis/test1'],
    ['sdc','478GB','WD567F83042','b12_p3','/media/akis/test2'],
    ['sdd','478GB','WD567F86042','b12_p4','/media/akis/test3'],
    ['sde','478GB','WD567F83042','b12_p5','/media/akis/test4']]

# print(lst[4])

# find total number of rows and columns in list
total_rows = len(lst)
total_columns = len(lst[0])

# create root window
root = Tk()
t = Table(root)
root.mainloop()