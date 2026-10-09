; ===========================================================================
;  Inno Setup 5.5.0 (u) - Unicode edition
;  Installer that extracts FreeArc (.arc) archives compressed with lolz.
;  Keep this file ASCII, or save it as UTF-8 with BOM if you add accents.
; ===========================================================================

; ---- Application info (edit these) ----------------------------------------
#define MyAppName "My Game"
#define MyAppVersion "1.0"
#define MyAppPublisher "Your Name"
; Name of the game executable, relative to the install folder
#define MyAppExe "Game.exe"

; ---- Archive settings ------------------------------------------------------
; Archive password. Leave empty ("") if the archive is not encrypted.
#define ArcPassword ""

; Size of the game ALREADY extracted, in MB (e.g. 27800 = 27.8 GB).
#define GameSizeMB 1000

; Number of active ARC files: 1 = only fg-01.arc
; When you enable more files (see the comments in [Components] and in [Code]),
; raise this number: 2 = fg-01 and fg-02, 3 = up to fg-03, 4 = up to fg-04.
#define ArcCount 1

; ---- Optional assets (detected automatically) ------------------------------
; Missing files are simply skipped, so the script compiles without them.
#if FileExists(AddBackslash(SourcePath) + "images\music.mp3")
  #define UseMusic
#endif
#if FileExists(AddBackslash(SourcePath) + "images\WizardImage0.bmp")
  #define UseWizardImage
#endif
#if FileExists(AddBackslash(SourcePath) + "images\WizardSmallImage0.bmp")
  #define UseWizardSmallImage
#endif

; Remove the semicolon on the next line to show music error messages
;#define DebugMusic

[Setup]
; Generate your own GUID for every project (Tools > Generate GUID in the
; Inno Setup IDE). Keep the two opening braces.
AppId={{4D8A415A-2B24-448F-8FAB-2384DE0393DF}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName=C:\Games\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=Output
OutputBaseFilename=setup
Compression=lzma2
SolidCompression=yes
AllowNoIcons=yes
DisableWelcomePage=no
DisableProgramGroupPage=no
CreateAppDir=yes
UsePreviousAppDir=no
UsePreviousGroup=no
PrivilegesRequired=admin
ExtraDiskSpaceRequired={#GameSizeMB}000000
; The install folder is fixed to DefaultDirName. The uninstaller deletes the
; whole folder, so users must not be able to pick a shared one like C:\Games.
DisableDirPage=yes
#ifdef UseWizardImage
WizardImageFile=images\WizardImage0.bmp
#endif
#ifdef UseWizardSmallImage
WizardSmallImageFile=images\WizardSmallImage0.bmp
#endif

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
; Texts written in this script are English only. If you translate them, add
; the language here, for example:
;Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Types]
Name: "full"; Description: "Full installation"
Name: "compact"; Description: "Minimal installation"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Components]
Name: "main"; Description: "Main files (fg-01.arc)"; Types: full compact custom; Flags: fixed
; Uncomment (remove the leading ;) the components you add:
;Name: "extras"; Description: "Extra files (fg-02.arc)"; Types: full custom
;Name: "docs"; Description: "Documentation (fg-03.arc)"; Types: full custom
;Name: "others"; Description: "Other files (fg-04.arc)"; Types: full compact custom

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"
Name: "startmenuicon"; Description: "Create a Start menu shortcut"; GroupDescription: "Shortcuts:"

[Files]
; Extraction tools: bundled in the installer and copied to {tmp} during the
; install step. They are used in ssPostInstall (see [Code]).
; Only tools\unpack is needed; the compressor in tools\ is NOT bundled.
Source: "tools\unpack\*"; DestDir: "{tmp}\tools\unpack"; Flags: recursesubdirs ignoreversion
; To bundle the whole tools folder instead, use this line (and comment the one above):
;Source: "tools\*"; DestDir: "{tmp}\tools"; Flags: recursesubdirs ignoreversion
#ifdef UseMusic
; Music: only extracted on demand with ExtractTemporaryFile
Source: "images\music.mp3"; DestDir: "{tmp}"; Flags: dontcopy
#endif

[Icons]
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExe}"; Tasks: desktopicon
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExe}"; Tasks: startmenuicon

[Run]
Filename: "{app}\{#MyAppExe}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Everything extracted by arc.exe is unknown to the uninstaller, so remove the whole folder.
Type: filesandordirs; Name: "{app}"

[Code]

type
  TMsg = record
    hwnd: HWND;
    message: Cardinal;
    wParam: LongInt;
    lParam: LongInt;
    time: DWORD;
    pt: TPoint;
  end;

function mciSendString(lpstrCommand: String; lpstrReturnString: String;
  uReturnLength: UINT; hwndCallback: HWND): Integer;
external 'mciSendStringW@winmm.dll stdcall';

function PeekMessage(var Msg: TMsg; hWnd: HWND; wMsgFilterMin: UINT;
  wMsgFilterMax: UINT; wRemoveMsg: UINT): Boolean;
external 'PeekMessageW@user32.dll stdcall';

function TranslateMessage(var Msg: TMsg): Boolean;
external 'TranslateMessage@user32.dll stdcall';

function DispatchMessage(var Msg: TMsg): LongInt;
external 'DispatchMessageW@user32.dll stdcall';

var
  SrcPage: TInputDirWizardPage;
  MusicButton: TNewButton;
  MusicEnabled: Boolean;
  RemainingLabel: TNewStaticText;

{ ---------- Windows messages (keeps the window responsive while extracting) ---------- }

procedure AppProcessMessage;
var
  Msg: TMsg;
begin
  while PeekMessage(Msg, 0, 0, 0, 1) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;

{ ---------- Music ---------- }

procedure StopMusic;
begin
  mciSendString('stop mp3', '', 0, 0);
  mciSendString('close mp3', '', 0, 0);
end;

procedure StartMusic;
var
  MusicPath: String;
  ResultCode: Integer;
begin
  MusicPath := ExpandConstant('{tmp}\music.mp3');

  if not FileExists(MusicPath) then
  begin
#ifdef DebugMusic
    MsgBox('File not found: ' + MusicPath, mbError, MB_OK);
#endif
    Exit;
  end;

  StopMusic;

  // First attempt: force the mpegvideo type
  ResultCode := mciSendString(
    'open "' + MusicPath + '" type mpegvideo alias mp3', '', 0, 0);

  // Second attempt: let Windows detect the type
  if ResultCode <> 0 then
    ResultCode := mciSendString(
      'open "' + MusicPath + '" alias mp3', '', 0, 0);

  if ResultCode = 0 then
    mciSendString('play mp3 repeat', '', 0, 0)
  else
  begin
#ifdef DebugMusic
    MsgBox('MCI error while opening the music: ' + IntToStr(ResultCode), mbError, MB_OK);
#endif
  end;
end;

procedure ToggleMusic(Sender: TObject);
begin
  MusicEnabled := not MusicEnabled;

  if MusicEnabled then
  begin
    StartMusic;
    MusicButton.Caption := 'Music: ON';
  end
  else
  begin
    StopMusic;
    MusicButton.Caption := 'Music: OFF';
  end;
end;

procedure CreateMusicButton;
begin
  MusicButton := TNewButton.Create(WizardForm);
  MusicButton.Parent := WizardForm;
  MusicButton.Left := ScaleX(8);
  MusicButton.Top := WizardForm.ClientHeight - ScaleY(35);
  MusicButton.Width := ScaleX(110);
  MusicButton.Height := ScaleY(25);
  MusicButton.Caption := 'Music: ON';
  MusicButton.OnClick := @ToggleMusic;
end;

{ ---------- Pages and labels ---------- }

procedure CreateSourcePage;
begin
  // Placed AFTER the tasks page, so the components are already selected
  SrcPage := CreateInputDirPage(
    wpSelectTasks,
    'Location of the data files',
    'Where is the ARC file?',
    // With more files: 'Where are the ARC files?',
    'Select the folder that contains the file:' + #13#10 +
    'fg-01.arc.',
    // With more files, use this text instead:
    // 'Select the folder that contains the files:' + #13#10 +
    // 'fg-01.arc, fg-02.arc, fg-03.arc and fg-04.arc.',
    False,
    '');

  SrcPage.Add('ARC file folder:');
  SrcPage.Values[0] := ExpandConstant('{src}');
end;

procedure CreateInstallExtraLabels;
begin
  RemainingLabel := TNewStaticText.Create(WizardForm);
  RemainingLabel.Parent := WizardForm.ProgressGauge.Parent;
  RemainingLabel.Left := WizardForm.ProgressGauge.Left;
  RemainingLabel.Top := WizardForm.ProgressGauge.Top +
    WizardForm.ProgressGauge.Height + ScaleY(8);
  RemainingLabel.Width := WizardForm.ProgressGauge.Width;
  RemainingLabel.Height := ScaleY(15);
  RemainingLabel.AutoSize := False;
  RemainingLabel.Caption := '';
end;

{ ---------- ARC files ---------- }

function ArcFileFor(Index: Integer): String;
begin
  Result := '';
  case Index of
    0: Result := 'fg-01.arc';
    // Uncomment the following ones when you add more ARC files:
    // 1: Result := 'fg-02.arc';
    // 2: Result := 'fg-03.arc';
    // 3: Result := 'fg-04.arc';
  end;
end;

function ArcIsSelected(Index: Integer): Boolean;
begin
  Result := False;
  case Index of
    0: Result := IsComponentSelected('main');
    // Uncomment the following ones together with their components in [Components]:
    // 1: Result := IsComponentSelected('extras');
    // 2: Result := IsComponentSelected('docs');
    // 3: Result := IsComponentSelected('others');
  end;
end;

// Returns the last percentage (0-100) found in arc.exe's output, or -1
function LastPercent(S: String): Integer;
var
  i, j, Value, Multiplier: Integer;
begin
  Result := -1;

  for i := Length(S) downto 1 do
  begin
    if S[i] = '%' then
    begin
      Value := 0;
      Multiplier := 1;
      j := i - 1;

      while (j >= 1) and (S[j] >= '0') and (S[j] <= '9') do
      begin
        Value := Value + (Ord(S[j]) - 48) * Multiplier;
        Multiplier := Multiplier * 10;
        j := j - 1;
      end;

      if Multiplier > 1 then
      begin
        if Value > 100 then
          Value := 100;
        Result := Value;
        Exit;
      end;
    end;
  end;
end;

// Extracts one ARC file with arc.exe and returns its exit code (-1 on failure)
function RunArc(ArcPath, Tag, Caption: String; Base, Span: Integer): Integer;
var
  ToolsDir, CmdFile, LogFile, DoneFile: String;
  PwdOpt, Script: String;
  DoneStr: AnsiString;
  Log: AnsiString;
  ExecResult, Percent: Integer;
begin
  // Extraction build of arc.exe (arc + lolz): tools\unpack, as in unpack.bat
  ToolsDir := ExpandConstant('{tmp}\tools\unpack');
  CmdFile  := ExpandConstant('{tmp}\unpack_' + Tag + '.cmd');
  LogFile  := ExpandConstant('{tmp}\unpack_' + Tag + '.log');
  DoneFile := ExpandConstant('{tmp}\unpack_' + Tag + '.done');

  DeleteFile(LogFile);
  DeleteFile(DoneFile);

  if '{#ArcPassword}' <> '' then
    PwdOpt := '-p"{#ArcPassword}" '
  else
    PwdOpt := '-p- ';

  Script :=
    '@echo off' + #13#10 +
    'cd /d "' + ToolsDir + '"' + #13#10 +
    '"' + ToolsDir + '\arc.exe" x -y -o+ ' + PwdOpt +
    '-dp"' + ExpandConstant('{app}') + '" "' + ArcPath + '" > "' +
    LogFile + '" 2>&1' + #13#10 +
    'echo %errorlevel% > "' + DoneFile + '"' + #13#10;

  SaveStringToFile(CmdFile, Script, False);

  WizardForm.StatusLabel.Caption := Caption;
  WizardForm.FilenameLabel.Caption := 'Starting...';
  WizardForm.ProgressGauge.Position := Base;

  if not Exec(ExpandConstant('{cmd}'), '/C ""' + CmdFile + '""',
    ToolsDir, SW_HIDE, ewNoWait, ExecResult) then
  begin
    Result := -1;
    Exit;
  end;

  // Poll the log for progress until the .done file appears
  repeat
    Sleep(300);
    AppProcessMessage;

    if LoadStringFromFile(LogFile, Log) then
    begin
      Percent := LastPercent(Log);

      if Percent >= 0 then
      begin
        WizardForm.ProgressGauge.Position := Base + (Percent * Span) div 100;
        WizardForm.FilenameLabel.Caption := IntToStr(Percent) + '%';
      end;
    end;
  until FileExists(DoneFile);

  Result := -1;

  if LoadStringFromFile(DoneFile, DoneStr) then
    Result := StrToIntDef(Trim(DoneStr), -1);
end;

// Returns True if all selected ARC files exist; otherwise warns and returns False
function ValidateArcFiles: Boolean;
var
  i: Integer;
  FileName, Missing: String;
begin
  Missing := '';

  for i := 0 to {#ArcCount} - 1 do
  begin
    if ArcIsSelected(i) then
    begin
      FileName := AddBackslash(SrcPage.Values[0]) + ArcFileFor(i);

      if not FileExists(FileName) then
        Missing := Missing + #13#10 + ' - ' + ArcFileFor(i);
    end;
  end;

  Result := (Missing = '');

  if not Result then
    MsgBox('The following ARC files are missing:' + Missing, mbError, MB_OK);
end;

procedure ExtractAll;
var
  i, Total, Done, Err, Base, Span: Integer;
  ArcPath: String;
begin
  Total := 0;

  for i := 0 to {#ArcCount} - 1 do
    if ArcIsSelected(i) then
      Total := Total + 1;

  if Total = 0 then
    Exit;

  WizardForm.ProgressGauge.Min := 0;
  WizardForm.ProgressGauge.Max := 100;
  WizardForm.ProgressGauge.Position := 0;
  WizardForm.CancelButton.Enabled := False;

  Done := 0;

  for i := 0 to {#ArcCount} - 1 do
  begin
    if ArcIsSelected(i) then
    begin
      ArcPath := AddBackslash(SrcPage.Values[0]) + ArcFileFor(i);

      Base := (Done * 100) div Total;
      Span := 100 div Total;

      Err := RunArc(
        ArcPath,
        IntToStr(i),
        'Extracting ' + ArcFileFor(i) + ' (' + IntToStr(Done + 1) +
        ' of ' + IntToStr(Total) + ')...',
        Base,
        Span);

      if Err <> 0 then
      begin
        WizardForm.CancelButton.Enabled := True;

        MsgBox(
          'Failed to extract ' + ArcFileFor(i) + '.' + #13#10 + #13#10 +
          'Exit code: ' + IntToStr(Err) + #13#10 + #13#10 +
          'Check that the ARC file is not corrupted ' +
          'and that the password is correct.',
          mbError, MB_OK);

        Exit;
      end;

      Done := Done + 1;
    end;
  end;

  WizardForm.ProgressGauge.Position := 100;
  WizardForm.StatusLabel.Caption := 'Installation completed';
  WizardForm.FilenameLabel.Caption := '';

  if Assigned(RemainingLabel) then
    RemainingLabel.Caption := '';

  WizardForm.CancelButton.Enabled := True;
end;

{ ---------- Wizard events ---------- }

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;

  if CurPageID = SrcPage.ID then
    Result := ValidateArcFiles;
end;

procedure InitializeWizard;
begin
  MusicEnabled := True;

#ifdef UseMusic
  ExtractTemporaryFile('music.mp3');
  CreateMusicButton;
#endif

  CreateInstallExtraLabels;
  CreateSourcePage;

#ifdef UseMusic
  StartMusic;
#endif
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if Assigned(MusicButton) then
    MusicButton.Top := WizardForm.ClientHeight - ScaleY(35);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  // ssPostInstall: the tools are already copied to tmp\tools\unpack
  // and the application folder already exists
  if CurStep = ssPostInstall then
    ExtractAll;
end;

procedure DeinitializeSetup;
begin
  StopMusic;
end;
