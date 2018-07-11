#define MyAppName "password-turtle"
#define MyAppVersion "1.5.0"
#define MyAppPublisher "monsterkodi"
#define MyAppURL "https://github.com/monsterkodi/password-turtle"
#define MyAppExeName "password-turtle.exe"

[Setup]
AppId={{72175CD6-46FB-465A-9376-C31049D3A7F0}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=..\inno
OutputBaseFilename={#MyAppName}-{#MyAppVersion}-setup
SetupIconFile=..\img\app.ico
Compression=lzma
SolidCompression=yes
WizardImageFile=..\img\innolarge.bmp
WizardSmallImageFile=..\img\innosmall.bmp

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\{#MyAppName}-win32-x64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

