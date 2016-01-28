# LaTeX in Word

LaTeX in Word is a GPL-licensed tool that allows equations to be used in
Microsoft Word documents. The client-side of the program is implemented as VBA
macros in the document "latex_in_word_[year].[doc or docm]" depending on
version of Word. Different versions of this file are provided for different
versions of Microsoft Word. This Word document contains the source code,
implementation, and documentation for using LaTeX in Word.

## Installation for Windows

Simply clone the repository:

git clone https://github.com/Engineero/latex_in_word.git

and open the "latex_in_word_[year].[doc or docm]" file for your version of
Microsoft Word. This document contains the macros needed, as well as
instructions on how to use the service. You can delete any files other than
the Word document that matches your version of Word.

You can also set this document as a template in Word, thus enabling access
to the macros from any Word document that uses this template.

## Installation for Mac

Note: the Mac version is still a work in progress and could use some love.
In-line equations are not aligning with text very well, and the raw LaTeX
string is not saving with the equation image as it does for Windows.

To install for Mac, clone the repository as above, and navigate to
`latex_in_word/Mac_2011`. Copy the file `getURL.py` to `~/Documents/`. You may
now open the Word document `latex_in_word_mac_2011.docm` and review the
instructions to use LaTeX in Word.

The Python script is a work-around for Office 2011's heightened security, and
is needed to communicate with the LaTeX server. More information about the
process of porting LaTeX in Word to Mac can be found in my StackOverflow
questions:

<http://stackoverflow.com/questions/17109947/adding-image-from-url-in-word-2011-for-mac-osx-using-vba>

## Server

A default server is set up. If you wish to run your own server, see the
Process_LaTeX project repository at:

<https://github.com/Engineero/Process_LaTeX>

Complete license information can be found in the file "gpl.txt". Updates and
additional information can be found on the GitHub project page:

<https://github.com/Engineero/latex_in_word>

