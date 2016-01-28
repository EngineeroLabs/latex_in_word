VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} LaTeX_Entry 
   Caption         =   "LaTeX Entry"
   ClientHeight    =   5520
   ClientLeft      =   45
   ClientTop       =   330
   ClientWidth     =   7905
   OleObjectBlob   =   "LaTeX_Entry.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "LaTeX_Entry"
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

Private Sub Cancel_Button_Click()
    Unload Me
End Sub

Private Sub Convert_Button_Click()
    Dim indx, Font_Size, String_Start_Loc, String_Stop_Loc As Integer
    Dim Baseline_Depth, Directory_Name, File_Name, Latex_Str, Percent_Replacement, _
        Base_Web_Address As String
    Dim Encoded_Chars As Variant
    Dim WebAdd
  
    Base_Web_Address = "http://web.ics.purdue.edu/~davis152/Process_LaTeX/"
    
    ' Check for empty input strings (they make Word crash when inserted as image alt-text
    If (Entry_Box.TextLength = 0) Then
        MsgBox "LaTex input is empty!", vbInformation, "LaTeX in Word Information"
        Set WebAdd = Nothing
        Exit Sub
    End If
               
    ' Percentage-encode the LaTeX string so it can be used in a valid URL
    Encoded_Chars = Array(37, 33, 34, 35, 36, 38, 39, 40, 41, 42, 43, 44, 47, 58, _
        59, 60, 61, 62, 63, 64, 91, 92, 93, 94, 96, 123, 124, 125, 7, 13)
    ' Note that "%" (ASCII 37) is replaced first to avoid spurious replacements
    Latex_Str = Entry_Box.Text
    For indx = 0 To 29
        ' Allow for "Hex" function returning "1" instead of "01"
        If (Encoded_Chars(indx) <= 15) Then
            Percent_Replacement = "%0" & Hex(Encoded_Chars(indx))
        Else
            Percent_Replacement = "%" & Hex(Encoded_Chars(indx))
        End If
        Latex_Str = Replace(Latex_Str, Chr(Encoded_Chars(indx)), Percent_Replacement)
    Next
  
    ' Set web address
    WebAdd = Base_Web_Address & "Process_LaTeX.php"
    
    ' Turn off error handling to stop the xmlhttp object from
    ' displaying it own unreadable errors.
    On Error Resume Next
    
    ' Create an xmlhttp object.
    Set w_page = CreateObject("Microsoft.XMLHTTP")
    
    ' Open the connection to the remote server.
    w_page.Open "POST", WebAdd, False
      
    ' Indicate that the body of the request contains form data
    w_page.setRequestHeader "Content-Type", "application/x-www-form-urlencoded"
    
    ' Actually send the request and return the data:
    Font_Size = ComboFontSize.Value
    w_page.Send "formula=" & Font_Size & "." & Latex_Str
  
    ' Check for failure
    If (InStr(w_page.responseText, "Error") > 0) Then ' Bad LaTeX input
        Report_Error.Error_Text.Text = w_page.responseText
        Load Report_Error
        Report_Error.Show
        Set w_page = Nothing
        Set WebAdd = Nothing
    ElseIf (StrComp(w_page.StatusText, "OK") <> 0) Then ' Unable to find server
        MsgBox "Unable to reach LaTeX server at: " & Base_Web_Address & vbCrLf & _
               "Please ensure the correct server address is entered" & _
               " and that the server is operational.", vbCritical, _
               "LaTeX in Word Error"
    Else
        ' Extract the directory name
        String_Start_Loc = InStr(w_page.responseText, "(directory name=")
        String_Stop_Loc = InStr(String_Start_Loc, w_page.responseText, ")")
        Directory_Name = Mid(w_page.responseText, String_Start_Loc + 16, _
            String_Stop_Loc - String_Start_Loc - 16)
    
        ' Extract the baseline depth
        String_Start_Loc = InStr(w_page.responseText, "(baseline depth=")
        String_Stop_Loc = InStr(String_Start_Loc, w_page.responseText, ")")
        Baseline_Depth = Mid(w_page.responseText, String_Start_Loc + 16, _
            String_Stop_Loc - String_Start_Loc - 16)
  
        ' Insert the picture
        File_Name = Base_Web_Address & "temporary/" & Directory_Name & "/template1.png"
        Selection.InlineShapes.AddPicture FileName:=File_Name, _
            LinkToFile:=False, SaveWithDocument:=True
        
        ' Store LaTeX string
        Selection.MoveLeft Unit:=wdCharacter, Count:=1, Extend:=wdExtend
        Selection.InlineShapes(1).AlternativeText = Entry_Box.Text
        
        ' Set font size and position
        Selection.Font.Position = -Baseline_Depth
        Selection.Font.Size = Font_Size
        
        ' Instruct the server to delete the temporary files it generated
        WebAdd = Base_Web_Address & "Delete_Temporary_Files.php?dir=" & Directory_Name
        w_page.Open "GET", WebAdd, False
        w_page.Send
        
        ' Reset the font baseline so subsequent text will be normally positioned
        Selection.MoveRight
        Selection.Font.Position = 0
        
        Set w_page = Nothing
        Set WebAdd = Nothing
        
        Unload Me
    End If
End Sub


