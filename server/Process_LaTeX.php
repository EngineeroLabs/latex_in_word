<?php
################################################################################
# Program Name: Process_LaTeX.php
# Description:  Process_LaTeX is part of a system that duplicates some of the
#                 functionality of the Microsoft Word equation editor.  A Word
#                 macro calls this PHP script on a web server that subsequently
#                 calls a PERL script that converts its argument into a PNG
#                 image.  Refer to the PERL script for further documentation.
# Usage:        Process_LaTeX.php?formula=font_size.data[&dont_del=del_value]
#                 Where font_size is the desired LaTeX font size (10, 11, or
#                   12), data is a LaTeX formula that has been percent-encoded,
#                   and del_value is the boolean value (0 or 1) of dont_del.
#                 The dont_del option prevents the temporary files from being
#                   deleted after an error; this option defaults to 0 and would
#                   normally only be invoked for diagnostic purposes.
#
# Copyright (C) 2007 Tyler A. Davis
# Copyright (C) 2007 Philip Stevenson
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, 
# USA.
################################################################################

# Microsoft Word will not make the call to this PHP script if the URL (including
# the 'formula' argument) has already been called since Word was started.  This
# means that the correct PNG will not be (re)generated and the wrong image may 
# be loaded into Word.  This problem can be prevented by disabling caching with 
# the following line.
header("Cache-Control: no-cache, must-revalidate");

# Get the formula whether from POST (preferable) or GET (for backward 
# compatibility).
if($_POST)
    $formula = $_POST['formula'];
else
    $formula = $_GET['formula'];

# PHP versions < 6 have a feature called "magic quotes" inteded to make input 
# safe by escaping dangerous characters. If this feature is enabled, strip the 
# extra slashed it adds.
if(get_magic_quotes_gpc())
    $formula = stripslashes($formula);

# PHP tries to undo the percent encoding, but the following restores the
# encoding because it's also handy for passing a string as an argument.
# "escapeshellarg" is used for added security.
$LaTeX_String = escapeshellarg(urlencode($formula));

# Call PERL to generate the PNG and display the required baseline offset. If
# necessary, the PERL script will also display any error messages.
if ($_GET['dont_del'])
    system("/usr/local/bin/perl LaTeX_Converter.pl --URL=\"$LaTeX_String\" --Dont_Del");
else
    system("/usr/local/bin/perl LaTeX_Converter.pl --URL=\"$LaTeX_String\"");
?>
