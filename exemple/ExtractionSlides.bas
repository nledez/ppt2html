Attribute VB_Name = "Module1"
Public Sub extract_all_files()
    Dim thePath As String
    Dim src_ppt_file As String
    Dim dst_comment_file As String
    Dim PPT As PowerPoint.Application
    Dim p As PowerPoint.Presentation
    Dim s As Slide
    Dim sh As PowerPoint.Shape
    Dim i As Integer
    Dim f(10) As String
    
    f(1) = "Offre de service-DSI-PH -v1.4.ppt"
    f(2) = "Offre de service-DSI-PH -v1 4-light.ppt"
    f(3) = "Offre de service-DSI-PH -v1 4-extra-light.ppt"
    f(4) = "Offre de service-DSI-PH -v1 4-externe.ppt"
    
    thePath = "C:\Documents and Settings\nledez2\Mes documents\Pj\Priam\OffresDeServices\"
    
    For i = 1 To 4
        src_ppt_file = thePath & f(i)
        dst_png_path = thePath & Split(f(i), ".")(0) & "_slides"
        dst_comment_file = dst_png_path & "\commentaires.txt"
        'MsgBox (src_ppt_file & vbCrLf & dst_png_path & vbCrLf & dst_comment_file)
        extract_comments_and_slides src_ppt_file, (dst_png_path), dst_comment_file
    Next i
    Set PPT = Nothing
End Sub

Public Sub extract_current_file()
Dim thePath As String
    Dim src_ppt_file As String
    Dim dst_comment_file As String
    Dim PPT As PowerPoint.Application
    Dim p As PowerPoint.Presentation
    Dim s As Slide
    Dim sh As PowerPoint.Shape
    Dim i As Integer
    Dim f(10) As String
    
    thePath = ActivePresentation.Path
    src_ppt_file = ActivePresentation.FullName
    dst_png_path = thePath & "\" & Split(ActivePresentation.Name, ".")(0) & "_slides\images"
    dst_comment_file = thePath & "\" & Split(ActivePresentation.Name, ".")(0) & "_slides\commentaires.txt"
    'MsgBox (src_ppt_file & vbCrLf & dst_png_path & vbCrLf & dst_comment_file)
    If Not Dir(dst_png_path, vbDirectory) <> "" Then
        'MsgBox "dir exist: " & dst_png_path
    'Else
        MsgBox "dir is missing: " & dst_png_path
        MkDir dst_png_path
    End If
    'extract_comments_and_slides src_ppt_file, (dst_png_path), dst_comment_file
    Set PPT = Nothing
End Sub

Sub extract_comments_and_slides(src_ppt_file As String, dst_png_path As String, dst_comment_file As String)
    Dim strNotesText As String
    strNotesText = ""
    

    On Error Resume Next
    Kill dst_comment_file
    Set PPT = CreateObject("PowerPoint.Application")
    PPT.Activate
    PPT.Visible = True
    'PPT.WindowState = ppWindowMinimized
    PPT.Presentations.Open FileName:=src_ppt_file, ReadOnly:=True
    For Each Slide In PPT.ActivePresentation.Slides
        For Each Comment In Slide.NotesPage.Shapes
        If Comment.PlaceholderFormat.Type = ppPlaceholderBody Then
            If Comment.HasTextFrame Then
                If Comment.TextFrame.HasText Then
                    strNotesText = strNotesText & CStr(Slide.SlideIndex) & " " & Comment.TextFrame.TextRange.Text & vbCrLf
                End If
            End If
        End If
        Next Comment
    Next Slide

    Dim ap As Presentation: Set ap = ActivePresentation
    ap.SaveAs dst_png_path, ppSaveAsPNG

    PPT.ActivePresentation.Close

    intFileNum = FreeFile()

    Open dst_comment_file For Output As intFileNum
    Print #intFileNum, strNotesText
    Close #intFileNum

End Sub

