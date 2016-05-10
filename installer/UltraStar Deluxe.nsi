;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; NSIS installer script for     ;
; Ultrastar Deluxe WorldParty   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;
;      Libraries        ;
;;;;;;;;;;;;;;;;;;;;;;;;;

!include MUI2.nsh			;Used for create the interface
!include LogicLib.nsh		;Used for internal calculations
!include InstallOptions.nsh	;Used for components selections
!include nsDialogs.nsh		;Used for custom pages
!include UAC.nsh			;Used for get privileges to write on disk
!include FileFunc.nsh		;used for get size info at uninstaller

;;;;;;;;;;;;;;;;;;;;;;;;;
;      Variables        ;
;;;;;;;;;;;;;;;;;;;;;;;;;

; Product Information:
!define PRODUCT_NAME "Ultrastar Deluxe WorldParty"
!define PRODUCT_VERSION "16.10"
!define PRODUCT_PUBLISHER "Ultrastar Espa�a"
!define PRODUCT_WEB_SITE "http://ultrastar-es.org"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"
!define ARP "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"

; Paths:
!define path_settings ".\settings"
!define path_languages ".\languages"
!define path_dependencies ".\dependencies"
!define path_images ".\dependencies\images"
!define path_plugins ".\dependencies\plugins"

; Icons
!define MUI_ICON "install.ico"
!define MUI_UNICON "uninstall.ico"

; MultiLanguage - Show all languages:
!define MUI_LANGDLL_ALLLANGUAGES 

; Header and Side Images:
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "${path_images}\header.bmp"
!define MUI_HEADERIMAGE_UNBITMAP "${path_images}\header.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP "${path_images}\side.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "${path_images}\side.bmp"

; Abort Warnings:
!define MUI_ABORTWARNING
!define MUI_ABORTWARNING_TEXT "$(abort_install)"
!define MUI_ABORTWARNING_CANCEL_DEFAULT
!define MUI_UNABORTWARNING
!define MUI_UNABORTWARNING_TEXT "$(abort_uninstall)"
!define MUI_UNABORTWARNING_CANCEL_DEFAULT

;Program name
!define exe "WorldParty"

!addPluginDir "${path_plugins}\"

!include "${path_settings}\functions.nsh"


;;;;;;;;;;;;;;;;;;;;;;;;;
; General configuration ;
;;;;;;;;;;;;;;;;;;;;;;;;;

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
Brandingtext "${PRODUCT_NAME} ${PRODUCT_VERSION} Installation"
OutFile "${PRODUCT_NAME} ${PRODUCT_VERSION}.exe" 

InstallDir "$PROGRAMFILES\${PRODUCT_NAME}" ; Default install directory
InstallDirRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "InstallDir" 
RequestExecutionLevel user ; ask for admin privileges in windows vista, 7,8,10 or higher

SetCompressorDictSize 64 ;improves ratio compression

SetOverwrite ifnewer
CRCCheck on

  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;             Installer Pages              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Welcome Page:

!define MUI_WELCOMEPAGE_TITLE_3LINES
!define MUI_WELCOMEPAGE_TITLE "$(page_welcome_title)"

!define MUI_WELCOMEPAGE_TEXT "$(page_welcome_txt)"

; License Page:

!define MUI_LICENSEPAGE_RADIOBUTTONS

; Finish Pages:

!define MUI_FINISHPAGE_TITLE_3LINES

!define MUI_FINISHPAGE_TEXT_LARGE
!define MUI_FINISHPAGE_TEXT "$(page_finish_txt)"

; MUI_FINISHPAGE_RUN is executed as admin by default.
; To get the config.ini location right it must be executed with user 
; rights instead.
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_NOTCHECKED
!define MUI_FINISHPAGE_RUN_FUNCTION RunAppAsUser 

Function RunAppAsUser 
    UAC::ShellExec 'open' '' '$INSTDIR\${exe}.exe' '' '$INSTDIR'
FunctionEnd

!define MUI_FINISHPAGE_LINK "$(page_finish_linktxt)"
!define MUI_FINISHPAGE_LINK_LOCATION "${PRODUCT_WEB_SITE}"

!define MUI_FINISHPAGE_SHOWREADME
!define MUI_FINISHPAGE_SHOWREADME_TEXT $(page_finish_desktop)
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION CreateDesktopShortCuts

!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_UNFINISHPAGE_NOAUTOCLOSE

!define MUI_FINISHPAGE_NOREBOOTSUPPORT

; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~
; Pages Installation Routine
; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~


!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE ".\dependencies\documents\license.txt"
!insertmacro MUI_PAGE_DIRECTORY

; Start menu page

Var ICONS_GROUP
!define MUI_STARTMENUPAGE_NODISABLE
!define MUI_STARTMENUPAGE_DEFAULTFOLDER "${PRODUCT_NAME}"
!define MUI_STARTMENUPAGE_REGISTRY_ROOT "${PRODUCT_UNINST_ROOT_KEY}"
!define MUI_STARTMENUPAGE_REGISTRY_KEY "${PRODUCT_UNINST_KEY}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "${PRODUCT_NAME}"
!insertmacro MUI_PAGE_STARTMENU Application $ICONS_GROUP

!insertmacro MUI_PAGE_INSTFILES
; USDX Settings Page


Page custom Settings


; User data info

Var UseAppData    ; true if APPDATA is used for user data, false for INSTDIR
Var UserDataPath  ; Path to user data dir (e.g. $INSTDIR)
Var ConfigIniPath ; Path to config.ini (e.g. "$INSTDIR\config.ini")

; Checks for write permissions on $INSTDIR\config.ini.
; This function creates $INSTDIR\config.use as a marker file if
; the user has write permissions.
; Note: Must be run with user privileges
Function CheckInstDirUserPermissions
	ClearErrors
	; try to open the ini file.
	; Use "append" mode so an existing config.ini is not destroyed.
	FileOpen $0 "$INSTDIR\config.ini" a
	IfErrors end
	; we have write permissions -> create a marker file
	FileOpen $1 "$INSTDIR\config.use" a	
	FileClose $1
end:
	FileClose $0
FunctionEnd

; Determines the directory used for config.ini and other user
; settings and data.
; Sets $UseAppData, $UserDataPath and $ConfigIniPath
Function DetermineUserDataDir
	Delete "$INSTDIR\config.use"
	!insertmacro UAC.CallFunctionAsUser CheckInstDirUserPermissions
	IfFileExists "$INSTDIR\config.use" 0 notexists
	StrCpy $UseAppData false
	StrCpy $UserDataPath "$INSTDIR"
	Goto end
notexists:
	StrCpy $UseAppData true
	SetShellVarContext current
	StrCpy $UserDataPath "$APPDATA\ultrastardx"
	SetShellVarContext all
end:
	Delete "$INSTDIR\config.use"	
	StrCpy $ConfigIniPath "$UserDataPath\config.ini"
FunctionEnd

Function Settings

	!insertmacro INSTALLOPTIONS_WRITE "Settings-$LANGUAGE" "Field 18" "State" "$INSTDIR\songs"

	!insertmacro MUI_HEADER_TEXT " " "$(page_settings_subtitle)"   
	!insertmacro INSTALLOPTIONS_DISPLAY "Settings-$LANGUAGE"

	; Get all the variables:

	Var /GLOBAL LABEL_COMPONENTS

	Var /GLOBAL CHECKBOX_COVERS
	Var /GLOBAL CB_COVERS_State
	Var /GLOBAL CHECKBOX_SCORES
	Var /GLOBAL CB_SCORES_State
	Var /GLOBAL CHECKBOX_CONFIG
	Var /GLOBAL CB_CONFIG_State
	Var /GLOBAL CHECKBOX_SCREENSHOTS
	Var /GLOBAL CB_SCREENSHOTS_State
	Var /GLOBAL CHECKBOX_PLAYLISTS
	Var /GLOBAL CB_PLAYLISTS_State
	Var /GLOBAL CHECKBOX_SONGS 
	Var /GLOBAL CB_SONGS_State

	Var /GLOBAL fullscreen
	Var /GLOBAL language2
	Var /GLOBAL resolution
	Var /GLOBAL tabs
	Var /GLOBAL sorting
	Var /GLOBAL songdir

	!insertmacro INSTALLOPTIONS_READ $fullscreen "Settings-$LANGUAGE" "Field 5" "State"
	!insertmacro INSTALLOPTIONS_READ $language2 "Settings-$LANGUAGE" "Field 6" "State"
	!insertmacro INSTALLOPTIONS_READ $resolution "Settings-$LANGUAGE" "Field 7" "State"
	!insertmacro INSTALLOPTIONS_READ $tabs "Settings-$LANGUAGE" "Field 8" "State"
	!insertmacro INSTALLOPTIONS_READ $sorting "Settings-$LANGUAGE" "Field 15" "State"
	!insertmacro INSTALLOPTIONS_READ $songdir "Settings-$LANGUAGE" "Field 18" "State"

	WriteINIStr "$ConfigIniPath" "Game" "Language" "$language2"
	WriteINIStr "$ConfigIniPath" "Game" "Tabs" "$tabs"
	WriteINIStr "$ConfigIniPath" "Game" "Sorting" "$sorting"

	WriteINIStr "$ConfigIniPath" "Graphics" "FullScreen" "$fullscreen"
	WriteINIStr "$ConfigIniPath" "Graphics" "Resolution" "$resolution"

	${If} $songdir != "$INSTDIR\songs"
	WriteINIStr "$ConfigIniPath" "Directories" "SongDir1" "$songdir"
	${EndIf}
		
FunctionEnd ; Settings page End

!insertmacro MUI_PAGE_FINISH

; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~
; Pages UnInstallation Routine
; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~

!define MUI_WELCOMEPAGE_TITLE_3LINES
!define MUI_WELCOMEPAGE_TITLE "$(page_un_welcome_title)"

!define MUI_FINISHPAGE_TITLE_3LINES

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM

UninstPage custom un.AskDelete un.DeleteAll


Function un.AskDelete

	nsDialogs::Create /NOUNLOAD 1018

	${NSD_CreateLabel} 0 -195 100% 12u "$(delete_components)"
	Pop $LABEL_COMPONENTS

	${NSD_CreateCheckbox} 0 -175 100% 8u "$(delete_covers)"
	Pop $CHECKBOX_COVERS
	nsDialogs::OnClick /NOUNLOAD $CHECKBOX_COVERS $1

	${NSD_CreateCheckbox} 0 -155 100% 8u "$(delete_config)"
	Pop $CHECKBOX_CONFIG
	nsDialogs::OnClick /NOUNLOAD $CHECKBOX_CONFIG $2

	${NSD_CreateCheckbox} 0 -135 100% 8u "$(delete_highscores)"
	Pop $CHECKBOX_SCORES 
	nsDialogs::OnClick /NOUNLOAD $CHECKBOX_SCORES $3

	${NSD_CreateCheckbox} 0 -115 100% 8u "$(delete_screenshots)"
	Pop $CHECKBOX_SCREENSHOTS 
	nsDialogs::OnClick /NOUNLOAD $CHECKBOX_SCREENSHOTS $4

	${NSD_CreateCheckbox} 0 -95 100% 8u "$(delete_playlists)"
	Pop $CHECKBOX_PLAYLISTS
	nsDialogs::OnClick /NOUNLOAD $CHECKBOX_PLAYLISTS $5

	${NSD_CreateCheckbox} 0 -65 100% 18u "$(delete_songs)"
	Pop $CHECKBOX_SONGS 
	nsDialogs::OnClick /NOUNLOAD $CHECKBOX_SONGS $6


	nsDialogs::Show

FunctionEnd

Function un.DeleteAll

${NSD_GetState} $CHECKBOX_COVERS $CB_COVERS_State
${NSD_GetState} $CHECKBOX_CONFIG $CB_CONFIG_State
${NSD_GetState} $CHECKBOX_SCORES $CB_SCORES_State
${NSD_GetState} $CHECKBOX_SCORES $CB_SCREENSHOTS_State
${NSD_GetState} $CHECKBOX_SCORES $CB_PLAYLISTS_State
${NSD_GetState} $CHECKBOX_SONGS  $CB_SONGS_State

${If} $CB_COVERS_State == "1" ; Remove covers
	RMDir /r "$INSTDIR\covers"
	SetShellVarContext current	
	RMDir /r "$APPDATA\ultrastardx\covers"
	SetShellVarContext all
${EndIf}

${If} $CB_CONFIG_State == "1" ; Remove config
	SetShellVarContext current
	Delete "$APPDATA\ultrastardx\config.ini" 
	SetShellVarContext all
	Delete "$INSTDIR\config.ini"
${EndIf}

${If} $CB_SCORES_State == "1" ; Remove highscores
	SetShellVarContext current
	Delete "$APPDATA\ultrastardx\Ultrastar.db" 
	SetShellVarContext all
	Delete "$INSTDIR\Ultrastar.db"
${EndIf}

${If} $CB_SCREENSHOTS_State == "1" ; Remove screenshots
	RMDir /r "$INSTDIR\sreenshots"
	SetShellVarContext current
	RMDir /r "$APPDATA\ultrastardx\screenshots"
	SetShellVarContext all
${EndIf}

${If} $CB_SCREENSHOTS_State == "1" ; Remove playlists
	RMDir /r "$INSTDIR\playlists"
	SetShellVarContext current
	RMDir /r "$APPDATA\ultrastardx\playlists"
	SetShellVarContext all
${EndIf}

${If} $CB_SONGS_State == "1" ; Remove songs
	RMDir /r "$INSTDIR\songs"
	SetShellVarContext current
	RMDir /r "$APPDATA\ultrastardx\songs"
	SetShellVarContext all
${EndIf}


FunctionEnd

!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~
; Sections Installation Routine
; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~

;------------------------------------
; MAIN COMPONENTS 
;------------------------------------
Section "Install"

	
	SetOutPath $INSTDIR
	SetOverwrite try

	Call DetermineUserDataDir
	!include "${path_settings}\files_main_install.nsh"

	; Create Shortcuts:
	SetOutPath "$INSTDIR"

!insertmacro MUI_STARTMENU_WRITE_BEGIN Application
	SetShellVarContext all
	SetOutPath "$INSTDIR"

	;CreateDirectory "$INSTDIR\${PRODUCT_NAME} ${PRODUCT_VERSION}"
	CreateDirectory "$SMPROGRAMS\$ICONS_GROUP"
	CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\$(sm_shortcut).lnk" "$INSTDIR\${exe}.exe"
	CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\$(sm_website).lnk" "${PRODUCT_WEB_SITE}"
	CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\$(sm_songs).lnk" "$INSTDIR\songs"
	CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\$(sm_uninstall).lnk" "$INSTDIR\Uninstall.exe"
!insertmacro MUI_STARTMENU_WRITE_END


	; Create Uninstaller:
	WriteUninstaller "$INSTDIR\Uninstall.exe"

	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "${PRODUCT_NAME} ${PRODUCT_VERSION}"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\${exe}.exe"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "InstallDir" "$INSTDIR"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\Uninstall.exe"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"

	SetOutPath "$INSTDIR"

 ;-------------- calculate the total size of the program -----	
		${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
		IntFmt $0 "0x%08X" $0
		WriteRegDWORD HKLM "${ARP}" "EstimatedSize" "$0"
 
SectionEnd

 
;------------------------------------
; UNINSTALL 
;------------------------------------

Section Uninstall

	!insertmacro MUI_STARTMENU_GETFOLDER "Application" $ICONS_GROUP

	!include "${path_settings}\files_main_uninstall.nsh"

	DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"


SectionEnd


; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~
; Language Support
; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~

!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "German"
!insertmacro MUI_LANGUAGE "Hungarian"
!insertmacro MUI_LANGUAGE "Polish"
!insertmacro MUI_LANGUAGE "Portuguese"
!insertmacro MUI_LANGUAGE "Spanish"

!insertmacro MUI_RESERVEFILE_LANGDLL

!include "${path_languages}\*.nsh"

;!addPluginDir "${path_plugins}\"
 

Function .onGUIEnd
	BGImage::Sound /STOP
FunctionEnd

Function .onInit
	 

	${UAC.I.Elevate.AdminOnly}

	var /GLOBAL version
	StrCpy $version "WorldParty"


	System::Call 'kernel32::CreateMutexA(i 0, i 0, t "USdx Installer.exe") ?e'

	Pop $R0

	StrCmp $R0 0 +3
	MessageBox MB_OK|MB_ICONEXCLAMATION $(oninit_running)
	Abort

	ReadRegStr $R0  HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME} ${PRODUCT_VERSION}" 'DisplayVersion'

	${If} $R0 == $version
		MessageBox MB_YESNO|MB_ICONEXCLAMATION \
			"${PRODUCT_NAME} $R0 $(oninit_alreadyinstalled). $\n$\n $(oninit_installagain)" \
			IDYES continue
		Abort
	${EndIf}

	ReadRegStr $R1 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME} ${PRODUCT_VERSION}" 'UninstallString'
	StrCmp $R1 "" done
  

	${If} $R0 != $version
		MessageBox MB_YESNO|MB_ICONEXCLAMATION \
			"${PRODUCT_NAME} $R0 $(oninit_alreadyinstalled). $\n$\n $(oninit_updateusdx) $R0 -> ${PRODUCT_VERSION}" \
			IDYES continue
			Abort
	${EndIf}


continue:
	ReadRegStr $R2 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME} ${PRODUCT_VERSION}" 'UninstallString'
	MessageBox MB_YESNO|MB_ICONEXCLAMATION "$(oninit_uninstall)" IDNO done
	ExecWait '"$R2" _?=$INSTDIR'

done:
	!insertmacro MUI_LANGDLL_DISPLAY

	!insertmacro INSTALLOPTIONS_EXTRACT_AS ".\settings\settings-1031.ini" "Settings-1031"
	!insertmacro INSTALLOPTIONS_EXTRACT_AS ".\settings\settings-1033.ini" "Settings-1033"
	!insertmacro INSTALLOPTIONS_EXTRACT_AS ".\settings\settings-1038.ini" "Settings-1038"
	!insertmacro INSTALLOPTIONS_EXTRACT_AS ".\settings\settings-1045.ini" "Settings-1045"
	!insertmacro INSTALLOPTIONS_EXTRACT_AS ".\settings\settings-1034.ini" "Settings-1034"
	!insertmacro INSTALLOPTIONS_EXTRACT_AS ".\settings\settings-2070.ini" "Settings-2070"

;--------- Splash image
  InitPluginsDir
  File "/oname=${path_images}\logo.bmp" "${path_images}\logo.bmp"

  advsplash::show 200 700 900 -1 ${path_images}\logo

  Pop $0 ; $0 has '1' if the user closed the splash screen early,
         ; '0' if everything closed normally, and '-1' if some error occurred.
;-----------------------	
	
FunctionEnd

Function un.onInit

	${nsProcess::FindProcess} "USdx.exe" $R0
	StrCmp $R0 0 0 +2
	MessageBox MB_YESNO|MB_ICONEXCLAMATION '$(oninit_closeusdx)' IDYES closeit IDNO end

closeit:
	${nsProcess::KillProcess} "USdx.exe" $R0
	goto continue

	${nsProcess::FindProcess} "${exe}.exe" $R0
	StrCmp $R0 0 0 +2
	MessageBox MB_YESNO|MB_ICONEXCLAMATION '$(oninit_closeusdx)' IDYES closeusdx IDNO end

closeusdx:
	${nsProcess::KillProcess} "${exe}.exe" $R0
	goto continue

end:
	${nsProcess::Unload}
	Abort

continue:
	!insertmacro MUI_LANGDLL_DISPLAY

FunctionEnd

Function .onInstFailed
	${UAC.Unload}
FunctionEnd
 
Function .onInstSuccess
	${UAC.Unload}
FunctionEnd
