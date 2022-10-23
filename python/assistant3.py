#!/usr/bin/env python3

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

# import pygtk
# import gtk


def main():
    calendar = Gtk.Calendar()
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
    entry = Gtk.Entry()
    button = Gtk.Button.new_with_label("Click Me")
    text = Gtk.TextView()
    text2 = Gtk.TextView()

    box.pack_start(entry, True, True, 0)
    box.pack_start(text2, True, True, 0)
    box.pack_end(button, True, True, 0)
    entry.set_text("Hello World")

    text.set_editable(False)
    text.get_buffer().set_text("""You chose to:
    * Frobnicate the foo.
    * Reverse the glop.
    * Enable future auto-frobnication.""")

    text2.set_editable(False)
    text2.get_buffer().set_text("""You chose to:
    * Frobnicate the foo.
    * Reverse the glop.
    * Enable future auto-frobnication.""")

    assistant = Gtk.Assistant()

    assistant.append_page(calendar)
    # assistant.append_page(entry)
    assistant.append_page(box)
    assistant.append_page(text)

    # It's important to set the page type so that the widget knows
    # which buttons to display. In this case, the Intro page won't
    # show a "Back" button. Note that the "Forward" button isn't
    # enabled until the page is marked as complete -- see the
    # "day_selected" signal handler below. When the user selects a day
    # in the calendar widget, the "Forward" button is enabled.

    assistant.set_page_type(calendar, Gtk.AssistantPageType.INTRO)
    assistant.set_page_title(calendar, "This is an assistant.")

    # The Content page type is for "ordinary" pages. Note that this
    # page is marked as complete here, so the user can press Forward
    # without doing any real action on the page.

    # assistant.set_page_type(entry, Gtk.AssistantPageType.CONTENT)
    # assistant.set_page_title(entry, "Enter some information on this page.")
    # assistant.set_page_complete(entry, True)
    # assistant.set_page_type(button, Gtk.AssistantPageType.CONTENT)
    # assistant.set_page_title(button, "Enter some information on this page.")
    # assistant.set_page_complete(button, True)
    assistant.set_page_type(box, Gtk.AssistantPageType.CONTENT)
    assistant.set_page_title(box, "Enter some information on this page.")
    assistant.set_page_complete(box, True)

    # The Summary page type is for the final page of the Assistant.

    assistant.set_page_type(text, Gtk.AssistantPageType.SUMMARY)
    assistant.set_page_title(text, "Congratulations, you're done.")

    # Handle the cancel and close buttons.

    assistant.connect("cancel", done)
    assistant.connect("close", done)

    # Get a callback when a calendar day is selected -- we'll allow
    # the user to move "Forward" when this is done.

    calendar.connect("day_selected", calendar_day_selected, assistant)

    calendar.show()
    entry.show()
    button.show()
    box.show()
    text.show()
    text2.show()

    assistant.show()
    Gtk.main()

def done(assistant):
    # If the user presses Cancel, just quit the app.
    # If the user presses Close (at the end page), just quit the app.
    Gtk.main_quit()

def calendar_day_selected(calendar, assistant):
    # Setting the page as "complete" enables the Forward button.
    assistant.set_page_complete(calendar, True)

if __name__ == '__main__':
    main()