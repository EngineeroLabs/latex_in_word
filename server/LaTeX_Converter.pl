#!/usr/local/bin/perl
################################################################################
# Program Name: LaTeX_Converter.pl
# Description:  LaTeX Converter is part of a system that duplicates some of the
#                 functionality of the Microsoft Word equation editor.  A Word
#                 macro calls a PHP script on a web server that runs this file.
#                 This file converts its argument into a PNG image.
# Usage:        LaTeX_Converter.pl --URL_String="'font_size.data'" [--Dont_Del]
#                 Where font_size is the desired LaTeX font size (10, 11, or 12)
#                   and data is a LaTeX formula that has been percent-encoded.
#                 The single quotation marks are required for PHP security.
#                 The "Dont_Del" option prevents the temporary/$pid directory
#                   from being deleted after an error; this option would
#                   normally only be invoked for diagnostic purposes.
# Notes:        Stdout is ultimately displayed as a webpage by the PHP script.
#                 This is used for both normal output and for error messages.
#               The path names given below may have to be modified to match the
#                 locations on a given system.
#               The following variables must be changed to specify a new
#                 resolution for the PNG:
#                 $res
#                 $pHYs_chunk
#                 %Text_Heights
#               A number of temporary files are generated in the "temporary\PID"
#                 directory where "PID" is the current process ID.  These files
#                 can be deleted by calling "Delete_Temporary_Files.php" after
#                 the PNG has been used.
# Requirements: The following software needs to be installed on the system
#                 dvipng
#                 ImageMagick (includes "convert" and "identify")
#                 LaTeX (including the preview package)
#                 PERL
#               A directory called "temporary" must exist immediately below the
#                 directory that this script is called from; "temporary" must be
#                 group-writable so that this script has permission to create
#                 files.  In addition, the file "template.tex" should reside in
#                 this directory.
#               This script is assumed to be run under Unix or Linux
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

use strict;
use Getopt::Long;

$/ = undef; #treat multi-line files as a single line

#path names; see above note
my $Convert_Path = '/usr/local/bin';
my $Dvipng_Path = '/usr/local/bin';
my $Identify_Path = '/usr/local/bin';
my $LaTeX_Path = '/usr/local/bin';
#other globals
my $Max_LaTeX_String_Length = 3000; #limit string to this size for security
my $res = 600; #resolution for the generated PNG
#pHYs chunk is inserted into the generated PNG file and specifies the image
#resolution; this resolves a bug in dvipng; a cleaner solution would be to use
#the "-density" option in convert, but the version of convert on some servers
#doesn't support this option.  Refer to the official PNG documentation for more
#details on this chunk.
my $pHYs_chunk = join('', chr(0),   chr(0),   chr(0),   chr(9), chr(112),  chr(72),  chr(89), chr(115),
                          chr(0),   chr(0),  chr(92),  chr(70),   chr(0),   chr(0),  chr(92),  chr(70),
                          chr(1),  chr(20), chr(148),  chr(67),  chr(65));
my %Text_Heights = ('10', 57, '11', 62, '12', 68);
#%Text_Heights is a hash of the nominal text heights (in pixels) for each of
#the allowed font sizes (in pixels).  This information is used to calculate
#baseline offsets for display equations.
my $URL_String; #argument passed from PHP; represents a LaTeX command and font
                #size that has been passed via a URL
my $Dont_Delete_Directory = ''; #true when the command-line option "Dont_Del" is
                                #specified; prevents the temporary/$pid
                                #directory from being deleted after an error
my $Font_Size;
my $LaTeX_String;
my $pid = getppid(); #The pid is used to uniquely name a directory for temporary
                     #files; this avoids issues with file locking if this script
                     #is called multiple times.  Also see note above.

GetOptions ("URL=s" => \$URL_String, 'Dont_Del' => \$Dont_Delete_Directory);

#remove starting and ending single quotes added by PHP's escapeshellarg function
$URL_String =~ s/^'//;
chop($URL_String);
#font size is given at the beginning of the URL string (separated by a dot)
#note that LaTeX only recognizes font sizes of 10, 11, and 12; other values are
#treated as 10 and don't give a warning
$URL_String =~ m/\./;
$Font_Size = $`;
$URL_String = $';

#recover LaTeX_String from URL_String
$LaTeX_String = $URL_String;
#decode percent-encoded characters
$LaTeX_String =~ s/\+/ /g;
$LaTeX_String =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
#remove high-order and control bytes for security
#note that tab (0x07) and newline (0x0D) are allowed
$LaTeX_String =~ s/[\x00-\x06\x08-\x0C\x0E-\x1f\x7f-\xff]//g;

if (length($LaTeX_String) > $Max_LaTeX_String_Length)
  {print "Error: LaTeX string cannot be longer than $Max_LaTeX_String_Length characters."}
else
{
  #make a subdirectory called "temporary/$pid" and change to it
  umask(0002); #set write privileges for mkdir; this mask gives privileges of
               #777-002=775 (i.e. full permissions for user and group, but world
               #can only read and execute)
  if (!mkdir("temporary/$pid"))
  {
    print "Error: Unable to create directory \"temporary/$pid\".";
  }
  elsif (!chdir("temporary/$pid"))
  {
    print "Error: Unable to change to directory \"temporary/$pid\".";
    if (!$Dont_Delete_Directory)
      {system("rm -r $pid");} #remove the directory
  }
  else #actually create an image
  {
    if ( !Create_Image()
         && !$Dont_Delete_Directory )
    {
      #there was an error creating the image; remove the temporary directory
      chdir("..");
      system("rm -r $pid");
    }
  }
}

################################################################################
#Convert the Latex String into an image
#Calls latex to create a DVI, then dvipng to create a PNG, then convert to trim
#the PNG.  Returns 1 if the image was created and 0 if there was an error.
sub Create_Image
{
  #locals
  my $Baseline_Depth; #the distance from the baseline to the bottom of the image
                      #(in pixels)
  my $Already_Trimmed = 0; #flag used to prevent convert's "trim" command from
                           #being called twice
  my $Height; #the total height of the image (in pixels)
  my $Numb_Points_Shift; #the number of points that Word is suppossed to shift
                         #the image down by to compensate for the baseline
                         #location
  my $Numb_Padding_Pxls; #the number of pixels of padding to be added to the
                         #bottom of the image (see below)
  my $temp;

  #save the LaTeX string to file "equation.tex", which is referenced by the
  #latex template
  if (!open(EQN_FILE, ">equation.tex"))
  {  
    print "Error: Unable to open equation.tex for writing.";
    return(0);
  }
  print EQN_FILE $LaTeX_String;
  close(EQN_FILE);

  #save font size to file "fontsize.tex", which is referenced by the latex
  #template
  if (!open(FS_FILE, ">fontsize.tex"))
  {
    print "Error: Unable to open fontsize.tex for writing.";
    return(0);
  }
  print FS_FILE "\\documentclass\n[$Font_Size pt]\n{article}";
  close(FS_FILE);

  #call LaTeX (TEX -> DVI)
  #Note that despite the fact that template.tex is in the parent directory,
  #LaTeX will search for fontsize.tex and equation.tex in the current directory
  #first.
  $temp = system("$LaTeX_Path/latex ../../template.tex >/dev/null");

  if ($temp >> 8) #the return value of a system call represents the exit status
                  #of the call; non-zero values of the 9th bit mean the call
                  #failed
  {
    print "Error: Call to LaTeX failed.\n";
    if (!open(LOG_FILE, "template.log"))
      {print "Log file (template.log) unavailable.";}
    else
    {
      $temp = <LOG_FILE>;
      close LOG_FILE;
      $temp =~ s/(.|\n)*?\n!/!/; #remove extra information preceding error
      $temp =~ s/(\W|\n)*\nHere is how much of TeX's memory you used:(.|\n)*//; #
      print "Contents of log file:\n========================================\n";
      print "$temp";
      print "\n========================================";
    }
    return(0);
  }

  #call dvipng (DVI -> PNG)
  $temp = system("$Dvipng_Path/dvipng -D$res -Q 1 template.dvi -depth >dvipng_output.txt");
  if ($temp >> 8)
  {
    print "Error: Call to dvipng failed.";
    return(0);
  }
  
  #extract $Baseline_Depth from the dvipng_output file
  if (!open(DEPTH_FILE, "dvipng_output.txt"))
  {
    print "Error: Unable to open dvipng_output.txt for reading.";
    return(0);
  }
  $temp = <DEPTH_FILE>;
  close(DEPTH_FILE);
  if ($temp =~ m/depth=(\d*)/)
    {$Baseline_Depth = $1;}
  else
  {
    print "Error: Opened dvipng_output.txt, but couldn't find baseline depth information.";
    return(0);
  }

  #insert the pHYs chunk in the PNG file; dvipng doesn't add this optional
  #chunk, so the resolution normally wouldn't get specified
  if (!open(PNG_FILE, 'template1.png'))
  {
    print "Error: Unable to open template1.png for reading.";
    return(0);
  }
  binmode PNG_FILE;
  $temp = <PNG_FILE>;
  close(PNG_FILE);
  #insert pHYs chunk immediately before the (required) IDAT chunk
  $temp =~ m/....IDAT/s; #slash-s is required to allow "." to match a newline,
                         #since one of the 4 characters in the length field
                         #could be a \n
  $temp = $`.$pHYs_chunk.$&.$';
  if (!open(PNG_FILE, '>template1.png'))
  {
    print "Error: Unable to open template1.png for writing.";
    return(0);
  }
  binmode PNG_FILE;
  print PNG_FILE $temp;
  close(PNG_FILE);

  #Call ImageMagick's "convert" command to:
  #
  #* Trim whitespace from the image; this is necessary because dvips w/ the
  #  preview stylesheet adds extra whitespace to the left and top of certain
  #  LaTeX constructs; note that the removal of the 4-pixel-wide border is
  #  allowed for by adjusting $Baseline_Depth.
  #* Pad white lines onto the bottom of the image; Word can only shift an image
  #  by an integer number of points (where 1 point = (1/72)"); instruct word to
  #  shift the image down by the next-highest integer number of points and make-
  #  up the difference by appending the necessary number of pixels to the PNG.
  #* Note that the baselines for display equations are set differently than for
  #  inline text; display equation baselines are set so that text on either side
  #  of the PNG will be vertically centered.  This allows equation numbers
  #  written in Word to appear correctly.
  $Baseline_Depth = $Baseline_Depth-4;

  if ( ($LaTeX_String =~ m/\\begin\{displaymath\}/)
       || ($LaTeX_String =~ m/\\begin\{eqnarray\**\}/)
       || ($LaTeX_String =~ m/\\begin\{equation\**\}/)
       || ($LaTeX_String =~ m/\\begin\{multline\**\}/)
       || ($LaTeX_String =~ m/\\begin\{gather\**\}/)
       || ($LaTeX_String =~ m/\\begin\{align\**\}/)
       || ($LaTeX_String =~ m/\\begin\{flalign\**\}/)
       || ($LaTeX_String =~ m/\\\[/)
       || ($LaTeX_String =~ m/\$\$/) )
  {
    #A display equation has been specified.

    #trim the image
    $temp = system("$Convert_Path/convert -border 5 -bordercolor white -threshold 50% -trim template1.png template1.png");
    if ($temp >> 8)
    {
      print "Error: Call to convert failed.";
      return(0);
    }
    $Already_Trimmed = 1;

    #use "identify" to determine the height
    $temp = system("$Identify_Path/identify template1.png >identify_output.txt");
    if ($temp >> 8) 
    {
      print "Error: Call to identify failed.";
      return(0);
    }
    #extract $Height from the identify_output file
    if (!open(HEIGHT_FILE, "identify_output.txt"))
    {
      print "Error: Unable to open identify_output.txt for reading.";
      return(0);
    }
    $temp = <HEIGHT_FILE>;
    close(HEIGHT_FILE);
    if ($temp =~ m/x(\d*) /)
      {$Height = $1;}
    else
    {
      print "Error: Opened identify_output.txt, but couldn't find height information.";
      return(0);
    }
    
    #new $Baseline_Depth is equal to 0.5*($Height-x), where x is the nominal
    #  height of normal text, in pixels
    if (exists $Text_Heights{$Font_Size})
      {$Height = $Height - $Text_Heights{$Font_Size}}
    else
      {$Height = $Height - $Text_Heights{'10'}}
    if ($Height > 1) #ensure that $Baseline_Depth won't go negative
      {$Baseline_Depth = round($Height/2);}
  }

  #Word baseline appears to be about 1 pixel different from LaTeX baseline at
  #  600dpi
  $Baseline_Depth = $Baseline_Depth-1; 

  $Numb_Points_Shift = ceiling(72*$Baseline_Depth/$res);
  $Numb_Padding_Pxls = round($Numb_Points_Shift*($res/72)-$Baseline_Depth);
  #create the padding file, if it doesn't already exist
  if (!(-e "../pad$Numb_Padding_Pxls.png"))
  {
    $temp = system("$Convert_Path/convert -size 1x$Numb_Padding_Pxls xc:white ../pad$Numb_Padding_Pxls.png");
    if ($temp >> 8)
    {
      print "Error: Unable to create padding file pad$Numb_Padding_Pxls.png.";
      return(0);
    }
  }
  #call convert
  if ($Already_Trimmed) #don't trim again if the image was already trimmed; this
                        #check prevents non-whitespace from being removed
    {$temp = system("$Convert_Path/convert template1.png -background white ../pad$Numb_Padding_Pxls.png -append template1.png");}
  else
    {$temp = system("$Convert_Path/convert template1.png -border 5 -bordercolor white -threshold 50% -trim -background white ../pad$Numb_Padding_Pxls.png -append template1.png");}
  if ($temp >> 8)
  {
    print "Error: Call to convert failed.";
    return(0);
  }

  #the following is only reached if the conversion was completely successful
  print "equation stored as template1.png<br>\n";
  print "(directory name=$pid)<br>\n";
  print "(baseline depth=$Numb_Points_Shift)";
  return(1);
}

################################################################################
#Round a positive real number to the next highest integer
sub ceiling
{
  #locals
  my ($real_number) = @_; #argument
  my $rounded_down = int $real_number;

  if ($rounded_down == $real_number)
    {return($rounded_down);}
  else
    {return($rounded_down+1);}
}

################################################################################
#Round a positive real number to the nearest integer
sub round
{
  #locals
  my ($real_number) = @_; #argument
  my $rounded_down = int $real_number;
  
  if ($real_number < $rounded_down+0.5)
    {return($rounded_down);}
  else
    {return($rounded_down+1);}
}
