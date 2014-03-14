=======
Lecture
=======
---------------------------------------------------------
Comix (and ebooks) reader written (in one shot) with Luce
---------------------------------------------------------


``Lecture`` (French for *reading*) is a comic books and manga reader for ``cbz``, ``cbr``
ant ``cbt``.

It's been written in a very short delay (a few hours of a single day) so it's a
really simple reader with, depending on opinion, the bare minimum or just
enough features.

It's a *one shot* reader: it starts with a book and won't start without
one. No menu, no book list, no database, not even thumbnails, just the book and
a few `shortcuts`_ with an optional slider to ease browsing. That's it.

**This is an open source/open minded projet, feel free to contribute, fork,
fix, submit, ask, improve, suggest, criticise or build toasters with it as
much as you want.**

License
=======

``Lecture`` is licenced under the terms of the `GPLv3 license
<http://www.gnu.org/licenses/gpl-3.0.html>`_.

Some parts, like the OPDS server, are licensed under the terms of the `AGPLv3
license <http://www.gnu.org/licenses/agpl-3.0.html>`_

Supported platforms
===================

``Lecture``'s actually supported on ``Linux``, ``Windows`` and ``OS X``.

It'll soon be supported on ``iOS`` and most certainly ``Android`` but this
requires a bit of work as there's no filesystem (as they say) on these
architectures, meaning something like a bookshelf is required (which is going
against the *one shot* thing...)


How it works
============

On Linux and Windows, the reader needs a book to start, so you can

- associate your .cb{z,r,t} with ``Lecture`` and double-click on them or
- use the command line::

    ./Lecture path/to/your/book.cb{z,r,t}

- or drop the book on ``Lecture`` executable

On OS X, same thing but the application can be started without a book. However,
there's no menu on OS X either, so you'll have the same options as for Linux
and Windows to open a book.

.. _shortcuts:

Available shorcuts
------------------

    :space/right:        next page
    :backspace/left:     previous page
    :home:               1st page
    :end:                last page
    :f (+cmd for OS X):  toggle full screen
    :s:                  toggle slider
    :q (+cmd for OS X):  quit
    :cmd+w:              close window (quit on Linux and Windows)
    :i:                  show some info on current page


What's inside
=============

- `Luce <https://github.com/peersuasive/luce>`_
- `Luce/Embedded <https://github.com/peersuasive/luce_embeddable>`_
- `libarchive <https://github.com/libarchive/libarchive>`_
- a custom lua module for libarchive
- some bugs, most certainly

Lecture v0.1 - shot 1
=====================

alpha release, probably buggy on any other desktop than mine.

Downloads
---------

(built with `Luce/Embedded <https://github.com/peersuasive/luce_embeddable>`_)

- `Linux (x86_64/glibc 2.13, debian package)
  <https://github.com/peersuasive/lecture/releases/download/v0.1/Lecture-0.0.1-1.x86_64.deb>`_

- `Linux (x86_64/glibc 2.13)
  <https://github.com/peersuasive/lecture/releases/download/v0.1/Lecture.0.1.Linux64.zip>`_


- `Mac OS X (x86_64, 10.9, untested on previous releases)
  <https://github.com/peersuasive/lecture/releases/download/v0.1/Lecture.0.1.MasOSX64.zip>`_

- `Windows (x86)
  <https://github.com/peersuasive/lecture/releases/download/v0.1/Lecture.0.1.Win32.zip>`_

Installation
============

Linux
-----

For Debian-like distro, there's a debian package.

For others, put the executable somewhere in your ``PATH``.

There are also a .desktop and icons if you want to fully integrate with your
window manager:

- drop ``Lecture.desktop`` in 
  
  - ``/usr[/local]/share/applications/`` 
  - or in ``$HOME/.local/share/applications/``

- put ``Lecture.xpm`` and/or ``Lecture.png`` in 
  
  - ``/usr[/local]/share/pixmaps/`` 
  - or ``$HOME/.local/share/pixmaps/``

- you can also create a menu entry with the follwing content in ``/usr/share/menu/Lecture``

:: 
    
    ?package(Lecture): \
        needs="X11" \
        section="Applications/Graphics" \
        title="Lecture" \
        command="/usr/bin/Lecture" \
        icon="/usr/share/pixmaps/Lecture.xpm" \
        longtitle="Embedded Luce for Lecture"

- to associate with mime types, you can create the entry file

  -  ``/usr[/local]/lib/mime/packages/Lecture.xml`` or
  - ``$HOME/.local/share/mime/Lecture.xml`` 
    
  with the following contents::

    <?xml version="1.0" encoding="UTF-8"?>
    <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
        <mime-type type="application/x-cbz">
            <sub-class-of type="application/zip"/>
            <comment xml:lang="en">Comic Book Archive (Zip compressed)</comment>
            <glob pattern="*.cbz"/>
        </mime-type>
        <mime-type type="application/x-cbr">
            <sub-class-of type="application/x-rar"/>
            <comment xml:lang="en">Comic Book Archive (RAR compressed)</comment>
            <glob pattern="*.cbr"/> 
        </mime-type>
        <mime-type type="application/x-cbt">
            <sub-class-of type="application/x-compressed-tar"/>
            <sub-class-of type="application/x-bzip-compressed-tar"/>
            <sub-class-of type="application/x-tar"/>
            <comment xml:lang="en">Comic Book Archive (tar, possibly compressed)</comment>
            <glob pattern="*.cbt"/>
        </mime-type>
    </mime-info>


OS X
----

Drop ``Lecture.app`` in your ``/Applications`` folder.

Windows
-------

Drop ``Lecture.exe`` wherever you want and open a comic book with *Open
with...*, that should register the path.


Roadmap
=======

Desktop
-------

- add "Open..." in menu for OS X
- rotate image
- add on screen help

All platforms
-------------

- change reading way for manga (r -> l)
- re-open last open book
- open book on last read page
- bookmark pages
- show bookmarks on slider
- add support for epub

Small devices
-------------

- add a bookshelf to open books
- add support for OPDS (both client and server)
- change brightness with up and down dragging (à la Stanza)
- add button to go back to menu on iOS

bookshelf management
~~~~~~~~~~~~~~~~~~~~
- remove book
- add tags to books
- add books to a serie (just a special tag)
- access series from a combo (à la CloudReaders)
  

Building from sources
=====================

All the requirements are included as submodules or included in sources.

It's fully configured to be built on a Linux host.

It's prepared for cross-compilation with Linux as a host and Windows, OS
X and iOS as targets (see `Luce/Embedded <https://github.com/peersuasive/luce_embeddable>`_ for details on cross compilers).

To build natively on other platforms, please refer to your IDE/OS manuals.

1. to create all the required links between repositories, run the script
   ``recreate_config.sh`` from the root of the project.

2. step into ``src/``

3. run

   .. code:: bash

      make linux

   or

   .. code:: bash

       make all


   to build for all platforms (if you have followed the instructions from
   `Luce/Embedded <https://github.com/peersuasive/luce_embeddable>`_)


.. vim:syntax=rst:filetype=rst:spelllang=en
