; -- rakudo.iss --

; SEE THE DOCUMENTATION FOR DETAILS ON CREATING .ISS SCRIPT FILES!
; using ISC 5.4.2(a)


[Setup]
AppName=Rakudo Star
AppVersion=2011.04
DefaultDirName=c:\rakudo
; Currently the installation path needs to be hard-coded
DisableDirPage=yes
DefaultGroupName=Rakudo Star
; UninstallDisplayIcon={app}\MyProg.exe
Compression=lzma2
SolidCompression=yes
SourceDir=c:\rakudo
OutputDir=c:\output
OutputBaseFilename=rakudo-star
;AppComments=
AppContact=http://rakudo.org/
; AppCopyright=
AppId=Rakudo_Star
; AppMutex= TODO!
AppPublisherURL=http://rakudo.org/

; ChangesAssociations=yes
ChangesEnvironment=yes
;InfoAfterFile=README_FIRST.txt


[Registry]

Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; \
    ValueName: "Path"; ValueType: expandsz; ValueData: "{olddata};{code:getPath}"; \
     Check: NeedsAddPath('\rakudo\bin');
;    Check: NeedsAddPath('\rakudo\install\bin');
; TODO: don't add the leading semi-colon to the Path if there is already a trailing one

[Files]
; Excludes: "cpan_sqlite_log*,cpan/build/*,cpan/sources/*,cpan/Bundle/*"; 
Source: "*"; DestDir: "{app}"; Flags: "recursesubdirs"

[Icons]
Name: "{group}\Rakudo REPL"; Filename: "{app}\bin\perl6.exe"; WorkingDir: "{app}"
Name: "{group}\Uninstall"; Filename: "{app}\unins000.exe"
; Name: "{group}\Rakudo README"; Filename: "{app}\share\doc\rakudo\README"


[Code]
function getPath(Param: String): string;
begin
//  Result := ExpandConstant('{app}') + '\install\bin;'
  Result := ExpandConstant('{app}') + '\bin;'
end;

// From http://stackoverflow.com/questions/3304463/how-do-i-modify-the-path-environment-variable-when-running-an-inno-setup-installe
function NeedsAddPath(Param: string): boolean;
var
  OrigPath: string;
begin
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE,
    'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    'Path', OrigPath)
  then begin
    Result := True;
    exit;
  end;
  // look for the path with leading and trailing semicolon
  // Pos() returns 0 if not found
  //Result := Pos(';' + ExpandConstant('{app}') + Param + ';', OrigPath) = 0;
  Result := Pos(getPath(''), OrigPath) = 0;
end;

function RemovePath(): boolean;
var
  OrigPath: string;
  start_pos: Longint;
  end_pos: Longint;
  new_str: string;
begin
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE,
    'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    'Path', OrigPath)
  then begin
    Result := True;
    exit;
  end;
  start_pos  := Pos(getPath(''), OrigPath);
  end_pos    := start_pos + Length(getPath(''));
  new_str    := Copy(OrigPath, 0, start_pos-1) + Copy(OrigPath, end_pos, Length(OrigPath));
  RegWriteExpandStringValue(HKEY_LOCAL_MACHINE,
    'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    'Path', new_str);
  Result := True;
end;
function InitializeUninstall(): Boolean;
begin
  Result := True;
  RemovePath();  
end;


// Restrict the installation path to have no space 
function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result :=True;
  case CurPageID of
    wpSelectDir :
    begin
    if Pos(' ', ExpandConstant('{app}') ) <> 0 then
      begin
        MsgBox('You cannot install to a path containing spaces. Please select a different path.', mbError, mb_Ok);
        Result := False;
      end;
    end;
  end;
end;
