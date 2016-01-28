<?php
################################################################################
# Program Name: Delete_Temporary_Files.php
# Description:  Deletes temporary files created by LaTeX_Converter.pl.
# Usage:        Delete_Temporary_Files.php?dir=name
#                 Causes directory "/temporary/name" and all of its contents to
#                 be deleted.  
# History:      v.1.0 written in 12/9/06 by Philip Stevenson (initial version)
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
################################################################################

#Microsoft Word will not make the call to this PHP script if the URL has already
#been called since Word was started.  This shouldn't be a problem, since the
#directory name should be unique each time a PNG is generated, but Word appears
#to apply its URL-checking incorrectly.  The following line guarantees that this
#script will be called every time.
header("Cache-Control: no-cache, must-revalidate" );

#The name of the directory should only be a string of numbers.  Return an error
#if any other argument is used or if the string is too short or too long.
$Directory_Name = $_GET['dir'];

if ( (preg_match('/\D/', $Directory_Name))
     || (strlen($Directory_Name) > 10)
     || (strlen($Directory_Name) < 1) )
  {echo 'Invalid directory name.';}
else
  {system("rm -r temporary/$Directory_Name");}
?>
