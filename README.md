# elmacho
A tool to work with PDF packing list data and flat files from hand scanners in order to facilitate product intake at a warehouse.

I'm witholding the packing lists and varer.dat file. I'll add file descriptions, though, 
for people who are interested in what the data looks like.

This code works, (I'd consider it proof of concept right now) but you'll want to adapt it to your own use.

The reason I wrote it was that we had hand scanners (barcode readers), but we were still counting items manually when
receiving shipments in the warehouse. I wondered why, asked around, and found out that 'it's just how we do things
around here.'

So this isn't perfect; it won't match every item we scan if the EAN => description file is too far off from the 
description in the packing list. But it should be a hell of a lot faster than counting hundreds of items by hand 
and cross-referencing multiple page printouts with a pen (ugh....)


Some challenges with this project:

Scraping data out of PDFs.

Lack of standardization when describing items. Makes you wonder what the databases looks like on the back end. 

Lack of common keys (EANs) across inventory and receiving documents.

Getting a sane dev environment set up on a windows box with restricted Internet access (no git or online rubygem
installs, for example). 

I ended up downloading RubyInstaller for windows, then manually downloading binaries of compiled gems and
their dependencies. It worked up to a point, until I needed to run RubyInline for fuzzy string matching, and then
even the Ruby Devkit for Windows was failing to give me the right object files. 

I ended up setting up an Ubuntu VM with everything I needed, and putting VMware Player on the Windows box. 

The next thing will be a simple internal web interface to make it easier for the other warehouse guys to use
this.

[And this is just a test commit from my Mac.]

-Jesse
