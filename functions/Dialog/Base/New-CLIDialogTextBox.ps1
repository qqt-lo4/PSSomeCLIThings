function New-CLIDialogTextBox {
    <#
    .SYNOPSIS
        Creates an editable text input field for CLI dialog interfaces.

    .DESCRIPTION
        This function creates an interactive text box control for user input in CLI dialogs.
        It provides a full-featured text editing experience with cursor positioning, keyboard
        navigation (arrows, Home, End, Backspace, Delete), validation (regex or scriptblock),
        password masking, secure string support, custom value conversion, and visual feedback
        for invalid input. The control displays a header label and an editable text field.

    .PARAMETER Header
        The label text displayed before the input field. This parameter is mandatory and can
        be used at position 0. Example: "Username", "Password", "Email Address".

    .PARAMETER HeaderAlign
        The alignment of the header label. Valid values are "Left" or "Right". Default is "Left".
        Right alignment is useful for creating form-like layouts with aligned colons.

    .PARAMETER HeaderSeparator
        The separator text between the header and input field. Default is " : ".
        Example: " = ", " -> ", " >> ".

    .PARAMETER TextForegroundColor
        The foreground color of the input text when not focused. Default is the current
        console foreground color.

    .PARAMETER TextBackgroundColor
        The background color of the input text when not focused. Default is the current
        console background color.

    .PARAMETER HeaderForegroundColor
        The foreground color of the header label when not focused. Default is Green.

    .PARAMETER HeaderBackgroundColor
        The background color of the header label when not focused. Default is the current
        console background color.

    .PARAMETER FocusedTextForegroundColor
        The foreground color of the input text when focused. Default is the current console
        foreground color.

    .PARAMETER FocusedTextBackgroundColor
        The background color of the input text when focused. Default is the current console
        background color.

    .PARAMETER FocusedHeaderForegroundColor
        The foreground color of the header label when focused. Default is Blue.

    .PARAMETER FocusedHeaderBackgroundColor
        The background color of the header label when focused. Default is the current console
        background color.

    .PARAMETER SeparatorLocation
        The column position where the separator should be located. Used for aligning multiple
        text boxes in a form layout. If not specified, uses the header length.

    .PARAMETER Text
        The initial text value. Can be a string, int, or SecureString. Default is empty string.
        - String/Int: Displayed as plain text (or masked if PasswordChar is set)
        - SecureString: Automatically converted to plain text internally and masked with "*"

    .PARAMETER Prefix
        The prefix string displayed before the header when not focused. Used for indentation
        or visual hierarchy.

    .PARAMETER FocusedPrefix
        The prefix string displayed before the header when focused. Typically used to indicate
        focus (e.g., "> " to show current field).

    .PARAMETER Regex
        A regular expression pattern for validation. The input text must match this pattern
        to be considered valid. Invalid input displays the header in ValidationErrorColor.

    .PARAMETER ValidationScript
        A scriptblock for custom validation. Receives the text as parameter and must return
        $true for valid or $false for invalid. Takes precedence over Regex if both are specified.

    .PARAMETER ValidationErrorColor
        The color used for the header when validation fails. Default is Red.

    .PARAMETER ValidationErrorReason
        A custom error message to display when validation fails. Used for user feedback.

    .PARAMETER FieldNameInErrorReason
        The field name to use in error messages. Useful for identifying which field failed
        validation in forms with multiple text boxes.

    .PARAMETER SelectionForegroundColor
        The foreground color of selected text. Default is the current console background color.

    .PARAMETER SelectionBackgroundColor
        The background color of selected text. Default is DarkCyan.

    .PARAMETER PasswordChar
        The character to use for masking input (e.g., '*' or '•'). When set, all characters
        are displayed as this character, but the actual text is preserved internally.

    .PARAMETER Name
        A unique identifier for the text box. If not specified, generates a name based on
        the header (e.g., "textboxUsername"). Used for identification and retrieval.

    .PARAMETER ValueConvertFunction
        A scriptblock to convert the text value when GetValue() is called. Useful for parsing
        numbers, dates, or custom types from string input.

    .OUTPUTS
        Returns a hashtable object with the following members:
        - Properties: Type, Header, HeaderAlign, HeaderSeparator, Colors, SeparatorLocation, Text,
                     OriginalText, Prefix, FocusedPrefix, CursorPosition, Regex, ValidationScript,
                     ValidationErrorColor, FieldNameInErrorReason, ValidationErrorReason, LastValidation,
                     PasswordChar, Name, ValueConvertFunction
        - Methods: IsValidText(), Draw(), DrawFocused(), PressLeft(), PressRight(), PressBackspace(),
                   PressDelete(), PressHome(), PressEnd(), PressUp(), PressDown(), PressKey(),
                   SetCursorPosition(), GetTextHeight(), GetTextWidth(), Reset(), GetValue(),
                   IsDynamicObject()

    .EXAMPLE
        $nameBox = New-CLIDialogTextBox -Header "Name" -Text "John Doe"
        $nameBox.DrawFocused()

        Creates a text box for name input with initial value "John Doe".

    .EXAMPLE
        $emailBox = New-CLIDialogTextBox -Header "Email" -Regex "^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$"
        # Invalid email will show header in red

        Creates a text box with email validation using regex pattern.

    .EXAMPLE
        $passwordBox = New-CLIDialogTextBox -Header "Password" -PasswordChar '*'
        $securePassword = $passwordBox.GetValue()  # Returns SecureString

        Creates a password text box with asterisk masking.

    .EXAMPLE
        $ageBox = New-CLIDialogTextBox -Header "Age" -ValidationScript {
            param($text)
            [int]$age = 0
            return [int]::TryParse($text, [ref]$age) -and $age -ge 18 -and $age -le 120
        } -ValueConvertFunction { param($text) [int]$text }
        $age = $ageBox.GetValue()  # Returns integer

        Creates a text box for age with custom validation and type conversion.

    .EXAMPLE
        $formFields = @(
            New-CLIDialogTextBox -Header "Username" -SeparatorLocation 15 -Prefix "  " -FocusedPrefix "> "
            New-CLIDialogTextBox -Header "Email" -SeparatorLocation 15 -Prefix "  " -FocusedPrefix "> "
            New-CLIDialogTextBox -Header "Phone" -SeparatorLocation 15 -Prefix "  " -FocusedPrefix "> "
        )

        Creates aligned form fields with consistent separator location and focus indicators.

    .EXAMPLE
        $secureBox = New-CLIDialogTextBox -Header "API Key" -Text (ConvertTo-SecureString "secret" -AsPlainText -Force)
        # Automatically displays as "******"

        Creates a text box initialized with a SecureString value.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-20
        Version: 2.0.0
        Dependencies: None

        This function is part of the CLI Dialog framework. Text boxes are the primary control
        for text input in forms and interactive dialogs.

        KEYBOARD NAVIGATION:
        - Left/Right Arrow: Move cursor within text
        - Shift+Left/Right Arrow: Extend selection
        - Home: Jump to beginning of text
        - End: Jump to end of text
        - Shift+Home/End: Extend selection to start/end
        - Ctrl+A: Select all text
        - Ctrl+C: Copy selected text to clipboard (disabled for password fields)
        - Ctrl+X: Cut selected text to clipboard (disabled for password fields)
        - Ctrl+V: Paste from clipboard (replaces selection if any)
        - Backspace: Delete character before cursor (or delete selection)
        - Delete: Delete character at cursor (or delete selection)
        - Up/Down Arrow: Navigate between text boxes (returns control to dialog)
        - Regular characters: Insert at cursor position (replaces selection if any)

        VALIDATION:
        - Validation is performed on-demand via IsValidText() method
        - Results are cached until text changes
        - Invalid text displays header in ValidationErrorColor
        - Both Regex and ValidationScript are supported (ValidationScript takes precedence)

        PASSWORD HANDLING:
        - PasswordChar masks all characters during display
        - Internal Text property stores actual unmasked text
        - GetValue() returns SecureString when PasswordChar is set
        - SecureString input is automatically detected and masked

        CURSOR DISPLAY:
        - Focused text box shows cursor as inverted colors at current position
        - Cursor at end of text shows as white space block
        - Cursor within text shows as inverted character

        METHODS:
        - IsValidText(): Returns true if text passes validation (cached)
        - Draw(): Renders text box in normal state
        - DrawFocused(): Renders with focus, shows cursor at CursorPosition
        - PressLeft/Right/Home/End(): Cursor movement methods
        - PressBackspace/Delete(): Text editing methods
        - PressUp/Down(): Returns navigation object to move between fields
        - PressKey([ConsoleKeyInfo]): Main keyboard handler, dispatches to specific methods
        - SetCursorPosition([int]): Programmatically set cursor position (with bounds checking)
        - GetTextHeight(): Returns number of lines (always 1 for textbox)
        - GetTextWidth(): Returns total width (prefix + header + separator + text)
        - Reset(): Restores to OriginalText value
        - GetValue(): Returns value (SecureString for passwords, converted value if function set, or plain text)
        - IsDynamicObject(): Returns $true (textbox is interactive)

        CHANGELOG:

        Version 2.0.0 - 2026-04-02 - Loïc Ade
            - Added sliding window for text longer than available width
            - Left/right arrow indicators (◄/►) for overflow direction
            - Cursor-centered viewport with smooth scrolling
            - Overflow indicator in unfocused Draw() method
            - Added text selection support (Shift+Left/Right/Home/End, Ctrl+A)
            - Added clipboard support (Ctrl+C copy, Ctrl+V paste, Ctrl+X cut)
            - Ctrl+C/X disabled for password fields (security)
            - Selection-aware rendering in DrawFocused (fits and overflow modes)
            - Selection-aware editing: typing, Backspace, Delete replace selection
            - New properties: SelectionAnchor, SelectionForegroundColor,
              SelectionBackgroundColor, SelectionCursorBackgroundColor
            - New methods: HasSelection, GetSelectionStart, GetSelectionEnd,
              GetSelectedText, ClearSelection, DeleteSelection, PressSelectAll,
              PressCopy, PressPaste, PressCut

        Version 1.0.0 - 2025-10-20 - Loïc Ade
            - Initial release
            - Full keyboard navigation and text editing
            - Regex and scriptblock validation with visual feedback
            - Password masking with character replacement
            - SecureString input and output support
            - Custom value conversion via scriptblock
            - Aligned form layouts with SeparatorLocation
            - Focus state with color customization
            - Cursor position display with inverted colors
            - Validation result caching for performance
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Header,
        [ValidateSet("Left", "Right")]
        [string]$HeaderAlign = "Left",
        [string]$HeaderSeparator = " : ",
        [System.ConsoleColor]$TextForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$TextBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$HeaderForegroundColor = [System.ConsoleColor]::Green,
        [System.ConsoleColor]$HeaderBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$FocusedTextForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$FocusedTextBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$FocusedHeaderForegroundColor = [System.ConsoleColor]::Blue,
        [System.ConsoleColor]$FocusedHeaderBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [int]$SeparatorLocation,
        [object]$Text = "",
        [string]$Prefix,
        [string]$FocusedPrefix,
        [string]$Regex,
        [object]$ValidationScript,
        [System.ConsoleColor]$SelectionForegroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$SelectionBackgroundColor = [System.ConsoleColor]::DarkCyan,
        [System.ConsoleColor]$SelectionCursorBackgroundColor = [System.ConsoleColor]::Blue,
        [System.ConsoleColor]$ValidationErrorColor = [System.ConsoleColor]::Red,
        [string]$ValidationErrorReason,
        [string]$FieldNameInErrorReason,
        [char]$PasswordChar,
        [string]$Name,
        [object]$ValueConvertFunction
    )
    $sText, $sPasswordChar = if (($Text -is [string]) -or ($Text -is [int])) {
        $sTextResult = $Text.ToString()
        $sPasswordCharResult = if ($PasswordChar) { $PasswordChar } else { $null }
        $sTextResult, $sPasswordCharResult
    } elseif ($Text -is [securestring]) {
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Text)
        $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR) | Out-Null
        $sPasswordCharResult = if ($PasswordChar) { $PasswordChar } else { "*" }
        $UnsecurePassword, $sPasswordCharResult
    } else {
        throw [System.ArgumentException] "Unsupported `$Text type"
    }
    $hResult = @{
        Type = "textbox"
        Header = $Header
        HeaderAlign = $HeaderAlign
        HeaderSeparator = $HeaderSeparator
        TextBackgroundColor = $TextBackgroundColor
        TextForegroundColor = $TextForegroundColor
        HeaderBackgroundColor = $HeaderBackgroundColor
        HeaderForegroundColor = $HeaderForegroundColor
        FocusedTextBackgroundColor = $FocusedTextBackgroundColor
        FocusedTextForegroundColor = $FocusedTextForegroundColor
        FocusedHeaderBackgroundColor = $FocusedHeaderBackgroundColor
        FocusedHeaderForegroundColor = $FocusedHeaderForegroundColor
        SeparatorLocation = $SeparatorLocation
        Text = $sText
        OriginalText = $sText
        Prefix = $Prefix
        FocusedPrefix = $FocusedPrefix
        CursorPosition = if ($sText) { $sText.Length } else { 0 }
        SelectionAnchor = $null
        SelectionForegroundColor = $SelectionForegroundColor
        SelectionBackgroundColor = $SelectionBackgroundColor
        SelectionCursorBackgroundColor = $SelectionCursorBackgroundColor
        Regex = $Regex
        ValidationScript = $ValidationScript
        ValidationErrorColor = $ValidationErrorColor
        FieldNameInErrorReason = $FieldNameInErrorReason
        ValidationErrorReason = $ValidationErrorReason
        LastValidation = $true
        PasswordChar = $sPasswordChar
        Name = if ($Name) { $Name } else { "textbox" + $Header.Replace("$([char]27)[4m", "").Replace("$([char]27)[24m", "").Replace(" ", "") }
        ValueConvertFunction = $ValueConvertFunction
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "IsValidText" -Value {
        if ($this.Regex -or $this.ValidationScript) {
            if ($this.LastTestedText -eq $this.Text) {
                return $this.LastValidation
            } else {
                $this.LastValidation, $this.LastValidationDetails = if ($this.Regex) {
                    $bValidationResult = Select-String -InputObject $this.Text -Pattern $this.Regex -AllMatches
                    $bValidationResult -ne $null
                    $bValidationResult
                } else {
                    $bValidationResult = Invoke-Command -ScriptBlock $this.ValidationScript -ArgumentList $this.Text
                    if ($bValidationResult) {
                        $true, $bValidationResult
                    } else {
                        $false, $false
                    }
                }
                $this.LastTestedText = $this.Text
                return $this.LastValidation
            }
        } else {
            return $true
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "HasSelection" -Value {
        return ($null -ne $this.SelectionAnchor -and $this.SelectionAnchor -ne $this.CursorPosition)
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetSelectionStart" -Value {
        if ($null -eq $this.SelectionAnchor) { return $this.CursorPosition }
        if ($this.SelectionAnchor -lt $this.CursorPosition) {
            return $this.SelectionAnchor
        } else {
            return $this.CursorPosition
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetSelectionEnd" -Value {
        if ($null -eq $this.SelectionAnchor) { return $this.CursorPosition }
        if ($this.SelectionAnchor -gt $this.CursorPosition) {
            return $this.SelectionAnchor
        } else {
            return $this.CursorPosition
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetSelectedText" -Value {
        if (-not $this.HasSelection()) { return "" }
        $iStart = $this.GetSelectionStart()
        $iEnd = $this.GetSelectionEnd()
        return $this.Text.Substring($iStart, $iEnd - $iStart)
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "ClearSelection" -Value {
        $this.SelectionAnchor = $null
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "DeleteSelection" -Value {
        if (-not $this.HasSelection()) { return $false }
        $iStart = $this.GetSelectionStart()
        $iEnd = $this.GetSelectionEnd()
        $sPrefix = if ($iStart -gt 0) { $this.Text.Substring(0, $iStart) } else { "" }
        $sSuffix = if ($iEnd -lt $this.Text.Length) { $this.Text.Substring($iEnd) } else { "" }
        $this.Text = $sPrefix + $sSuffix
        $this.CursorPosition = $iStart
        $this.SelectionAnchor = $null
        return $true
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "Draw" -Value {
        $iAlign = if ($this.HeaderAlign -eq "Left") { -1 } else { 1 }
        $sHeader = ("" + $this.Prefix + ("{0,$($this.SeparatorLocation * $iAlign)}" -f $this.Header) + $this.HeaderSeparator)
        $oHeaderColor = if ($this.IsValidText()) {
            $this.HeaderForegroundColor
        } else {
            $this.ValidationErrorColor
        }
        Write-Host $sHeader -ForegroundColor $oHeaderColor -BackgroundColor $this.HeaderBackgroundColor -NoNewline
        $sPrintedText = if ($this.PasswordChar) { $this.PasswordChar.ToString() * $this.Text.Length } else { $this.Text }

        $iAvailableWidth = $host.ui.RawUI.WindowSize.Width - $sHeader.Length
        if ($sPrintedText.Length -gt $iAvailableWidth -and $iAvailableWidth -gt 2) {
            # Text overflows: show the beginning with ► at the end
            $sVisible = $sPrintedText.Substring(0, $iAvailableWidth - 1)
            Write-Host $sVisible -ForegroundColor $this.TextForegroundColor -BackgroundColor $this.TextBackgroundColor -NoNewline
            Write-Host ([char]0x25BA) -ForegroundColor DarkYellow -BackgroundColor $this.TextBackgroundColor
        } else {
            Write-Host $sPrintedText -ForegroundColor $this.TextForegroundColor -BackgroundColor $this.TextBackgroundColor -NoNewline
            $iRemaining = [Math]::Max(0, $iAvailableWidth - $sPrintedText.Length)
            Write-Host (" " * $iRemaining)
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "DrawFocused" -Value {
        # Write Header
        $iAlign = if ($this.HeaderAlign -eq "Left") { -1 } else { 1 }
        $sPropertyToScreen = ("" + $this.FocusedPrefix + ("{0,$($this.SeparatorLocation * $iAlign)}" -f $this.Header) + $this.HeaderSeparator)
        $oHeaderColor = if ($this.IsValidText()) {
            $this.FocusedHeaderForegroundColor
        } else {
            $this.ValidationErrorColor
        }
        Write-Host $sPropertyToScreen -NoNewline -ForegroundColor $oHeaderColor -BackgroundColor $this.FocusedHeaderBackgroundColor

        # Clamp cursor position
        if ($this.CursorPosition -lt 0) { $this.CursorPosition = 0 }
        elseif ($this.CursorPosition -gt $this.Text.Length) { $this.CursorPosition = $this.Text.Length }

        # Prepare display text (with password masking)
        $sFullText = if ($this.PasswordChar) { $this.PasswordChar.ToString() * $this.Text.Length } else { $this.Text }

        # Available width for text area (1 extra for cursor block at end)
        $iAvailableWidth = $host.ui.RawUI.WindowSize.Width - $sPropertyToScreen.Length
        $bCursorAtEnd = ($this.CursorPosition -eq $this.Text.Length)
        $iCursorExtra = if ($bCursorAtEnd) { 1 } else { 0 }

        # Selection bounds
        $bHasSelection = $this.HasSelection()
        $iSelStart = $this.GetSelectionStart()
        $iSelEnd = $this.GetSelectionEnd()

        if (($sFullText.Length + $iCursorExtra) -le $iAvailableWidth) {
            # === Text fits entirely ===
            if ($bHasSelection) {
                $sBeforeSel = if ($iSelStart -gt 0) { $sFullText.Substring(0, $iSelStart) } else { "" }
                $sSelected = $sFullText.Substring($iSelStart, $iSelEnd - $iSelStart)
                $sAfterSel = if ($iSelEnd -lt $sFullText.Length) { $sFullText.Substring($iSelEnd) } else { "" }

                # Before selection (normal colors)
                if ($sBeforeSel.Length -gt 0) {
                    Write-Host $sBeforeSel -NoNewline -ForegroundColor $this.FocusedTextForegroundColor -BackgroundColor $this.FocusedTextBackgroundColor
                }

                if ($this.CursorPosition -eq $iSelStart) {
                    # Cursor at start of selection: [cursor-char][rest-of-selection]
                    Write-Host $sSelected[0] -NoNewline -ForegroundColor $this.SelectionForegroundColor -BackgroundColor $this.SelectionCursorBackgroundColor
                    if ($sSelected.Length -gt 1) {
                        Write-Host ($sSelected.Substring(1)) -NoNewline -ForegroundColor $this.SelectionForegroundColor -BackgroundColor $this.SelectionBackgroundColor
                    }
                    # After selection (normal colors)
                    if ($sAfterSel.Length -gt 0) {
                        Write-Host $sAfterSel -NoNewline -ForegroundColor $this.FocusedTextForegroundColor -BackgroundColor $this.FocusedTextBackgroundColor
                    }
                } else {
                    # Cursor at end of selection: [selection][cursor]
                    if ($sSelected.Length -gt 1) {
                        Write-Host ($sSelected.Substring(0, $sSelected.Length - 1)) -NoNewline -ForegroundColor $this.SelectionForegroundColor -BackgroundColor $this.SelectionBackgroundColor
                    }
                    # Last selected char has cursor highlight
                    Write-Host $sSelected[$sSelected.Length - 1] -NoNewline -ForegroundColor $this.SelectionForegroundColor -BackgroundColor $this.SelectionCursorBackgroundColor
                    # After selection (normal colors)
                    if ($sAfterSel.Length -gt 0) {
                        Write-Host $sAfterSel -NoNewline -ForegroundColor $this.FocusedTextForegroundColor -BackgroundColor $this.FocusedTextBackgroundColor
                    }
                }

                $iRemaining = [Math]::Max(0, $iAvailableWidth - $sFullText.Length)
                Write-Host (" " * $iRemaining)
            } else {
                # No selection - original rendering logic
                if ($sFullText.Length -gt 0) {
                    if (($this.CursorPosition - 1) -ge 0) {
                        Write-Host ($sFullText.Substring(0, $this.CursorPosition)) -NoNewline -ForegroundColor $this.FocusedTextForegroundColor -BackgroundColor $this.FocusedTextBackgroundColor
                    }
                    if (-not $bCursorAtEnd) {
                        Write-Host $sFullText[$this.CursorPosition] -NoNewline -ForegroundColor $this.FocusedTextBackgroundColor -BackgroundColor $this.FocusedTextForegroundColor
                    }
                    if ($this.CursorPosition + 1 -lt $sFullText.Length) {
                        Write-Host ($sFullText.Substring($this.CursorPosition + 1)) -NoNewline -ForegroundColor $this.FocusedTextForegroundColor -BackgroundColor $this.FocusedTextBackgroundColor
                    }
                }
                if ($bCursorAtEnd) {
                    Write-Host " " -ForegroundColor Black -BackgroundColor White -NoNewline
                    $iRemaining = [Math]::Max(0, $iAvailableWidth - $sFullText.Length - 1)
                } else {
                    $iRemaining = [Math]::Max(0, $iAvailableWidth - $sFullText.Length)
                }
                Write-Host (" " * $iRemaining)
            }
        } else {
            # === Text overflows: sliding window centered on cursor ===
            # Position cursor roughly in center of window
            $iViewStart = $this.CursorPosition - [Math]::Floor($iAvailableWidth / 2)
            # Clamp
            if ($iViewStart -lt 0) { $iViewStart = 0 }
            $iViewEnd = $iViewStart + $iAvailableWidth - $iCursorExtra

            if ($iViewEnd -gt $sFullText.Length) {
                $iViewEnd = $sFullText.Length
                $iViewStart = [Math]::Max(0, $iViewEnd - $iAvailableWidth + $iCursorExtra)
            }

            $bShowLeftArrow = ($iViewStart -gt 0)
            $bShowRightArrow = ($iViewEnd -lt $sFullText.Length)

            # Adjust for arrow characters
            if ($bShowLeftArrow) { $iViewStart++ }
            if ($bShowRightArrow) { $iViewEnd-- }

            # Extract visible portion
            $sVisibleText = $sFullText.Substring($iViewStart, $iViewEnd - $iViewStart)
            $iCursorInWindow = $this.CursorPosition - $iViewStart

            # Draw left arrow
            if ($bShowLeftArrow) {
                Write-Host ([char]0x25C4) -NoNewline -ForegroundColor DarkYellow -BackgroundColor $this.FocusedTextBackgroundColor
            }

            # Map selection to window coordinates
            $iWinSelStart = [Math]::Max(0, $iSelStart - $iViewStart)
            $iWinSelEnd = [Math]::Min($sVisibleText.Length, $iSelEnd - $iViewStart)
            $bHasVisibleSelection = $bHasSelection -and ($iWinSelEnd -gt $iWinSelStart)

            if ($bHasVisibleSelection) {
                # Before selection
                if ($iWinSelStart -gt 0) {
                    Write-Host ($sVisibleText.Substring(0, $iWinSelStart)) -NoNewline -ForegroundColor $this.FocusedTextForegroundColor -BackgroundColor $this.FocusedTextBackgroundColor
                }

                $sWinSelected = $sVisibleText.Substring($iWinSelStart, $iWinSelEnd - $iWinSelStart)

                if ($iCursorInWindow -eq $iWinSelStart) {
                    # Cursor at start of visible selection
                    Write-Host $sWinSelected[0] -NoNewline -ForegroundColor $this.SelectionForegroundColor -BackgroundColor $this.SelectionCursorBackgroundColor
                    if ($sWinSelected.Length -gt 1) {
                        Write-Host ($sWinSelected.Substring(1)) -NoNewline -ForegroundColor $this.SelectionForegroundColor -BackgroundColor $this.SelectionBackgroundColor
                    }
                    # After selection
                    if ($iWinSelEnd -lt $sVisibleText.Length) {
                        Write-Host ($sVisibleText.Substring($iWinSelEnd)) -NoNewline -ForegroundColor $this.FocusedTextForegroundColor -BackgroundColor $this.FocusedTextBackgroundColor
                    }
                } else {
                    # Cursor at end of selection
                    if ($sWinSelected.Length -gt 1) {
                        Write-Host ($sWinSelected.Substring(0, $sWinSelected.Length - 1)) -NoNewline -ForegroundColor $this.SelectionForegroundColor -BackgroundColor $this.SelectionBackgroundColor
                    }
                    Write-Host $sWinSelected[$sWinSelected.Length - 1] -NoNewline -ForegroundColor $this.SelectionForegroundColor -BackgroundColor $this.SelectionCursorBackgroundColor
                    # After selection
                    if ($iWinSelEnd -lt $sVisibleText.Length) {
                        Write-Host ($sVisibleText.Substring($iWinSelEnd)) -NoNewline -ForegroundColor $this.FocusedTextForegroundColor -BackgroundColor $this.FocusedTextBackgroundColor
                    }
                }
            } else {
                # No visible selection - original rendering
                if ($sVisibleText.Length -gt 0) {
                    if ($iCursorInWindow -gt 0) {
                        Write-Host ($sVisibleText.Substring(0, $iCursorInWindow)) -NoNewline -ForegroundColor $this.FocusedTextForegroundColor -BackgroundColor $this.FocusedTextBackgroundColor
                    }
                    if ($iCursorInWindow -ge 0 -and $iCursorInWindow -lt $sVisibleText.Length) {
                        Write-Host $sVisibleText[$iCursorInWindow] -NoNewline -ForegroundColor $this.FocusedTextBackgroundColor -BackgroundColor $this.FocusedTextForegroundColor
                    }
                    if ($iCursorInWindow + 1 -lt $sVisibleText.Length) {
                        Write-Host ($sVisibleText.Substring($iCursorInWindow + 1)) -NoNewline -ForegroundColor $this.FocusedTextForegroundColor -BackgroundColor $this.FocusedTextBackgroundColor
                    }
                }
            }

            # Cursor at end of text
            if ($bCursorAtEnd -and -not $bShowRightArrow) {
                Write-Host " " -ForegroundColor Black -BackgroundColor White -NoNewline
            }

            # Draw right arrow
            if ($bShowRightArrow) {
                Write-Host ([char]0x25BA) -NoNewline -ForegroundColor DarkYellow -BackgroundColor $this.FocusedTextBackgroundColor
            }

            Write-Host ""
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressLeft" -Value {
        Param([bool]$Shift = $false)
        if ($Shift) {
            if ($null -eq $this.SelectionAnchor) { $this.SelectionAnchor = $this.CursorPosition }
            if ($this.CursorPosition -gt 0) { $this.CursorPosition-- }
        } else {
            if ($this.HasSelection()) {
                $this.CursorPosition = $this.GetSelectionStart()
                $this.ClearSelection()
            } elseif ($this.CursorPosition -eq 0) {
                return [System.ConsoleKeyInfo]::LeftArrow
            } else {
                $this.CursorPosition--
                $this.ClearSelection()
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressRight" -Value {
        Param([bool]$Shift = $false)
        if ($Shift) {
            if ($null -eq $this.SelectionAnchor) { $this.SelectionAnchor = $this.CursorPosition }
            if ($this.CursorPosition -lt $this.Text.Length) { $this.CursorPosition++ }
        } else {
            if ($this.HasSelection()) {
                $this.CursorPosition = $this.GetSelectionEnd()
                $this.ClearSelection()
            } elseif ($this.CursorPosition -eq $this.Text.Length) {
                return [System.ConsoleKeyInfo]::RightArrow
            } else {
                $this.CursorPosition++
                $this.ClearSelection()
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressBackspace" -Value {
        if ($this.HasSelection()) {
            $this.DeleteSelection() | Out-Null
            return
        }
        if ($this.CursorPosition -gt 0) {
            $sPrefix = if ($this.CursorPosition -le 1) {
                ""
            } else {
                $this.Text.Substring(0, $this.CursorPosition - 1)
            }
            $sSuffix = if ($this.CursorPosition -lt $this.Text.Length) {
                $this.Text.Substring($this.CursorPosition)
            } else {
                ""
            }
            $this.Text = $sPrefix + $sSuffix
            $this.CursorPosition--
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressDelete" -Value {
        if ($this.HasSelection()) {
            $this.DeleteSelection() | Out-Null
            return
        }
        if ($this.CursorPosition -lt $this.Text.Length) {
            $sPrefix = if ($this.CursorPosition -gt 0) {
                $this.Text.Substring(0, $this.CursorPosition)
            } else {
                ""
            }
            $sSuffix = if ($this.CursorPosition + 1 -lt $this.Text.Length) {
                $this.Text.Substring($this.CursorPosition + 1)
            } else {
                ""
            }
            $this.Text = $sPrefix + $sSuffix
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressHome" -Value {
        Param([bool]$Shift = $false)
        if ($Shift) {
            if ($null -eq $this.SelectionAnchor) { $this.SelectionAnchor = $this.CursorPosition }
        } else {
            $this.ClearSelection()
        }
        $this.CursorPosition = 0
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressEnd" -Value {
        Param([bool]$Shift = $false)
        if ($Shift) {
            if ($null -eq $this.SelectionAnchor) { $this.SelectionAnchor = $this.CursorPosition }
        } else {
            $this.ClearSelection()
        }
        $this.CursorPosition = $this.Text.Length
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressSelectAll" -Value {
        $this.SelectionAnchor = 0
        $this.CursorPosition = $this.Text.Length
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressCopy" -Value {
        if ($this.PasswordChar) { return }
        if (-not $this.HasSelection()) { return }
        Set-Clipboard -Value $this.GetSelectedText()
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressPaste" -Value {
        $sClipboard = Get-Clipboard -ErrorAction SilentlyContinue
        if (-not $sClipboard) { return }
        # Flatten to single line
        $sClipboard = ($sClipboard -join "").Replace("`r", "").Replace("`n", "")
        # Delete selection first if any
        $this.DeleteSelection() | Out-Null
        # Insert at cursor
        $sPrefix = if ($this.CursorPosition -gt 0) { $this.Text.Substring(0, $this.CursorPosition) } else { "" }
        $sSuffix = if ($this.CursorPosition -lt $this.Text.Length) { $this.Text.Substring($this.CursorPosition) } else { "" }
        $this.Text = $sPrefix + $sClipboard + $sSuffix
        $this.CursorPosition += $sClipboard.Length
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressCut" -Value {
        if ($this.PasswordChar) { return }
        if (-not $this.HasSelection()) { return }
        $this.PressCopy()
        $this.DeleteSelection() | Out-Null
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressUp" -Value {
        $hResult = @{
            Key = [System.ConsoleKeyInfo]::new(0, [System.ConsoleKey]::UpArrow, $false, $false, $false)
            Options = $this.CursorPosition
        }
        return $hResult
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressDown" -Value {
        $hResult = @{
            Key = [System.ConsoleKeyInfo]::new(0, [System.ConsoleKey]::DownArrow, $false, $false, $false)
            Options = $this.CursorPosition
        }
        return $hResult
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressKey" -Value {
        Param(
            [System.ConsoleKeyInfo]$KeyInfo
        )
        $this.LastTestedText = $this.Text
        $bShift = ($KeyInfo.Modifiers -band [System.ConsoleModifiers]::Shift) -eq [System.ConsoleModifiers]::Shift
        $bCtrl = ($KeyInfo.Modifiers -band [System.ConsoleModifiers]::Control) -eq [System.ConsoleModifiers]::Control

        if ([System.Char]::IsControl($KeyInfo.KeyChar)) {
            # Handle Ctrl+key combinations
            if ($bCtrl) {
                switch ($KeyInfo.Key) {
                    ([System.ConsoleKey]::A) { return $this.PressSelectAll() }
                    ([System.ConsoleKey]::C) { return $this.PressCopy() }
                    ([System.ConsoleKey]::V) { return $this.PressPaste() }
                    ([System.ConsoleKey]::X) { return $this.PressCut() }
                }
            }

            switch ($KeyInfo.Key) {
                ([System.ConsoleKey]::LeftArrow) { return $this.PressLeft($bShift) }
                ([System.ConsoleKey]::RightArrow) { return $this.PressRight($bShift) }
                ([System.ConsoleKey]::UpArrow) { return $this.PressUp() }
                ([System.ConsoleKey]::DownArrow) { return $this.PressDown() }
                ([System.ConsoleKey]::Home) { return $this.PressHome($bShift) }
                ([System.ConsoleKey]::End) { return $this.PressEnd($bShift) }
                ([System.ConsoleKey]::Backspace) { return $this.PressBackspace() }
                ([System.ConsoleKey]::Delete) { return $this.PressDelete() }
                default {
                    return $KeyInfo
                }
            }
        } else {
            # Regular character input: replace selection if any, then insert
            $this.DeleteSelection() | Out-Null

            if ($this.CursorPosition -eq $this.Text.ToString().Length) {
                $this.Text += $KeyInfo.KeyChar
                $this.CursorPosition++
            } else {
                $sPrefix = if ($this.CursorPosition -eq 0) {
                    ""
                } else {
                    $this.Text.Substring(0, $this.CursorPosition)
                }
                $sSuffix = if ($this.CursorPosition -lt $this.Text.Length) {
                    $this.Text.Substring($this.CursorPosition)
                } else {
                    ""
                }
                $this.Text = $sPrefix + $KeyInfo.KeyChar + $sSuffix
                $this.CursorPosition++
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "SetCursorPosition" -Value {
        Param(
            [int]$Position
        )
        $this.ClearSelection()
        if ($Position -lt 0) {
            $this.CursorPosition = 0
        } elseif ($Position -gt $this.Text.Length) {
            $this.CursorPosition = $this.Text.Length
        } else {
            $this.CursorPosition = $Position
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextHeight" -Value {
        return $this.Text.Split("`n").Count
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextWidth" -Value {
        return $this.Prefix.Length + $this.Header.Length + $this.HeaderSeparator.Length + $this.Text.Length
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "Reset" -Value {
        $this.Text = $this.OriginalText
        $this.ClearSelection()
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetValue" -Value {
        if ($this.PasswordChar) {
            return $this.Text | ConvertTo-SecureString -AsPlainText -Force
        } else {
            if ($this.ValueConvertFunction) {
                return . $this.ValueConvertFunction $this.Text
            } else {
                return $this.Text
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "IsDynamicObject" -Value {
        return $true
    }

    return $hResult
}
