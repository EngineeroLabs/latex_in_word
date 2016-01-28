VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} EqnBookmark 
   Caption         =   "LaTeX Equation Label (Bookmark)"
   ClientHeight    =   1035
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   4665
   OleObjectBlob   =   "EqnBookmark.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "EqnBookmark"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'Copyright (C) 2007 Tyler A. Davis
'Copyright (C) 2007 Philip Stevenson
'
'This program is free software; you can redistribute it and/or
'modify it under the terms of the GNU General Public License
'as published by the Free Software Foundation; either version 2
'of the License, or (at your option) any later version.
'
'This program is distributed in the hope that it will be useful,
'but WITHOUT ANY WARRANTY; without even the implied warranty of
'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
'GNU General Public License for more details.
'
'You should have received a copy of the GNU General Public License
'along with this program; if not, write to the Free Software
'Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

Private Sub ButtonCancel_Click()
    ' Close the dialog box
    Unload Me
End Sub

Private Sub ButtonInsert_Click()
    Dim response As Integer ' Dummy response value
    Dim ascii_code As Integer
    Dim indx As Integer ' Index into the bookmark name
    Dim illegal_char_found As Boolean
    
    If (ActiveDocument.Bookmarks.Exists(EqnBookmark.labelText.Text)) Then
        ' Bookmark name has already been used
        response = MsgBox("A bookmark with that name already exists.", , "Equation Number Error")
    ElseIf (Len(EqnBookmark.labelText.Text) < 1) Then
        ' zero-length bookmark name
        response = MsgBox("Please enter a bookmark name.", , "Equation Number Error")
    Else
        ' Check characters of bookmark name; only alphanumeric plus underscore allowed
        illegal_char_found = False
        For indx = 1 To Len(EqnBookmark.labelText.Text)
            ascii_code = Asc(Mid(EqnBookmark.labelText.Text, indx, 1))
            illegal_char_found = (((ascii_code < 48) Or (ascii_code > 57)) _
                                   And ((ascii_code < 65) Or (ascii_code > 90)) _
                                   And ((ascii_code < 97) Or (ascii_code > 122)) _
                                   And (ascii_code <> 95))
            If (illegal_char_found) Then
                Exit For
            End If
        Next

        ' Also check if the first character is a number or an underscore
        ascii_code = Asc(EqnBookmark.labelText.Text) ' Asc returns ascii value of first character
        illegal_char_found = (illegal_char_found _
                              Or ((ascii_code >= 48) And (ascii_code <= 57)) _
                              Or (ascii_code = 95))
            
        If (illegal_char_found) Then
            ' Bookmark name is invalid
            response = MsgBox("Bookmark names must begin with a letter and can only contain letters, numbers, and underscores.", , "Equation Number Error")
        Else
            ' Add the number
            Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, Text:= _
            "SEQ EqNum", PreserveFormatting:=True
    
            ' Select the newly added number to add the bookmark
            Selection.MoveLeft Unit:=wdCharacter, Count:=1, Extend:=wdExtend

            ' Add the bookmark
            ActiveDocument.Bookmarks.Add Range:=Selection.Range, Name:=EqnBookmark.labelText.Text
            Selection.MoveRight
    
            ' Close the dialog box
            Unload Me
        End If
    End If
End Sub
