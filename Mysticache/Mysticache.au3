#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Images\mysticache.ico
#AutoIt3Wrapper_res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
Opt("GUIOnEventMode", 1);Change to OnEvent mode
;--------------------------------------------------------
;AutoIt Version: v3.3.0.0
$Script_Author = 'Andrew Calcutt'
$Script_Name = 'Mysticache'
$Script_Website = 'http://www.techidiots.net'
$version = 'v3.0 Alpha 1'
$Script_Start_Date = '2009/10/22'
$last_modified = '2012/06/12'
$title = $Script_Name & ' ' & $version & ' - By ' & $Script_Author & ' - ' & $last_modified
;Includes------------------------------------------------
#include <Date.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GDIPlus.au3>
#include <GuiListView.au3>
#include <File.au3>
#include "UDFs\AccessCom.au3"
#include "UDFs\cfxUDF.au3"
#include "UDFs\CommMG.au3"
#include "UDFs\FileInUse.au3"
#include "UDFs\_XMLDomWrapper.au3"
#include "UDFs\WinGetPosEx.au3"
;Get Date/Time-------------------------------------------
$dt = StringSplit(_DateTimeUtcConvert(StringFormat("%04i", @YEAR) & '-' & StringFormat("%02i", @MON) & '-' & StringFormat("%02i", @MDAY), @HOUR & ':' & @MIN & ':' & @SEC & '.' & StringFormat("%03i", @MSEC), 1), ' ')
$datestamp = $dt[1]
$timestamp = $dt[2]
$ldatetimestamp = StringFormat("%04i", @YEAR) & '-' & StringFormat("%02i", @MON) & '-' & StringFormat("%02i", @MDAY) & ' ' & @HOUR & '-' & @MIN & '-' & @SEC
;If file is secified, set load file
Dim $Load = ''
For $loop = 1 To $CmdLine[0]
	If StringLower(StringTrimLeft($CmdLine[$loop], StringLen($CmdLine[$loop]) - 4)) = '.gpx' Then $Load = $CmdLine[$loop]
	If StringLower(StringTrimLeft($CmdLine[$loop], StringLen($CmdLine[$loop]) - 4)) = '.loc' Then $Load = $CmdLine[$loop]
Next
;Options-------------------------------------------------
Opt("TrayIconHide", 1);Hide icon in system tray
Opt("GUIOnEventMode", 1);Change to OnEvent mode
Opt("GUIResizeMode", 802)
;Variables-----------------------------------------------
Dim $WPID = 0
Dim $TRACKID = 0
Dim $TRACKSEGID = 0

Dim $UseGPS = 0
Dim $TurnOffGPS = 0
Dim $CompassOpen = 0
Dim $GpsDetailsOpen = 0
Dim $DestSet = 0
Dim $Debug = 0
Dim $Close = 0
Dim $SaveDbOnExit = 0
Dim $Recover = 0
Dim $ClearAllWps = 0
Dim $Redraw = 0
Dim $VMode = 1
Dim $RefreshLoopTime = 500
Dim $SortColumn = -1
Dim $ErrorFlag_sound = 'error.wav'
Dim $GpsDetailsGUI
Dim $GPGGA_Update
Dim $GPRMC_Update
Dim $disconnected_time
Dim $sErr
Dim $NetComm
Dim $DB_OBJ
Dim $OpenedPort

Dim $StartLat = 'N 0.0000'
Dim $StartLon = 'E 0.0000'
Dim $DestLat = 'N 0.0000'
Dim $DestLon = 'E 0.0000'
Dim $Latitude = 'N 0.0000'
Dim $Longitude = 'E 0.0000'
Dim $Latitude2 = 'N 0.0000'
Dim $Longitude2 = 'E 0.0000'
Dim $NumberOfSatalites = '00'
Dim $HorDilPitch = '0'
Dim $Alt = '0'
Dim $AltS = 'M'
Dim $Geo = '0'
Dim $GeoS = 'M'
Dim $SpeedInKnots = '0'
Dim $SpeedInMPH = '0'
Dim $SpeedInKmH = '0'
Dim $TrackAngle = '0'

Dim $AddWaypoingGuiOpen = 0
Dim $AddWaypoingGui, $Rad_DestGPS_LatLon, $Rad_DestGPS_BrngDist, $GUI_AddName, $GUI_AddDesc, $GUI_AddNotes, $GUI_AddAuthor, $GUI_AddLink, $GUI_AddType, $GUI_AddDifficulty, $GUI_AddTerrain, $dLat, $dLon, $dBrng, $dDist, $dWPID, $dListRow
Dim $EditWaypoingGui, $EditWaypoingGuiOpen

Dim $winpos_old, $winpos, $sizes, $sizes_old
Dim $FixTime, $FixTime2, $FixDate, $Quality
Dim $Temp_FixTime, $Temp_FixTime2, $Temp_FixDate, $Temp_Lat, $Temp_Lon, $Temp_Lat2, $Temp_Lon2, $Temp_Quality, $Temp_NumberOfSatalites, $Temp_HorDilPitch, $Temp_Alt, $Temp_AltS, $Temp_Geo, $Temp_GeoS, $Temp_Status, $Temp_SpeedInKnots, $Temp_SpeedInMPH, $Temp_SpeedInKmH, $Temp_TrackAngle
Dim $CompassGraphic, $CompassGUI, $CompassBack, $CompassHeight, $CircleX, $CircleY, $north, $south, $east, $west
Dim $GpsCurrentDataGUI, $GPGGA_Time, $GPGGA_Lat, $GPGGA_Lon, $GPGGA_Quality, $GPGGA_Satalites, $GPGGA_HorDilPitch, $GPGGA_Alt, $GPGGA_Geo, $GPRMC_Time, $GPRMC_Date, $GPRMC_Lat, $GPRMC_Lon, $GPRMC_Status, $GPRMC_SpeedKnots, $GPRMC_SpeedMPH, $GPRMC_SpeedKmh, $GPRMC_TrackAngle

Dim $settings = @ScriptDir & '\Settings.ini'
Dim $DateFormat = StringReplace(StringReplace(IniRead($settings, 'DateFormat', 'DateFormat', RegRead('HKCU\Control Panel\International\', 'sShortDate')), 'MM', 'M'), 'dd', 'd')
Dim $ComPort = IniRead($settings, 'GpsSettings', 'ComPort', '4')
Dim $BAUD = IniRead($settings, 'GpsSettings', 'Baud', '4800')
Dim $PARITY = IniRead($settings, 'GpsSettings', 'Parity', 'N')
Dim $DATABIT = IniRead($settings, 'GpsSettings', 'DataBit', '8')
Dim $STOPBIT = IniRead($settings, 'GpsSettings', 'StopBit', '1')
Dim $GpsType = IniRead($settings, 'GpsSettings', 'GpsType', '2')
Dim $GpsFormat = IniRead($settings, 'GpsSettings', 'GpsFormat', '3')
Dim $GpsTimeout = IniRead($settings, 'GpsSettings', 'GpsTimeout', 30000)

If $GpsType = 0 Then
	$DefGpsInt = "CommMG"
ElseIf $GpsType = 1 Then
	$DefGpsInt = "Netcomm OCX"
ElseIf $GpsType = 2 Then
	$DefGpsInt = "Kernel32"
EndIf

Dim $BackgroundColor = IniRead($settings, 'Colors', 'BackgroundColor', '0x99B4A1')
Dim $ControlBackgroundColor = IniRead($settings, 'Colors', 'ControlBackgroundColor', '0xD7E4C2')
Dim $TextColor = IniRead($settings, 'Colors', 'TextColor', '0x000000')


Dim $RadStartGpsCurPos = IniRead($settings, 'StartGPS', 'Rad_StartGPS_CurrentPos', '4')
Dim $RadStartGpsLatLon = IniRead($settings, 'StartGPS', 'Rad_StartGPS_LatLon', '1')
Dim $DcLat = IniRead($settings, 'StartGPS', 'cLat', '')
Dim $DcLon = IniRead($settings, 'StartGPS', 'cLon', '')

Dim $RadDestGPSLatLon = IniRead($settings, 'DestGPS', 'Rad_DestGPS_LatLon', '1')
Dim $RadDestGPSBrngDist = IniRead($settings, 'DestGPS', 'Rad_DestGPS_BrngDist', '4')
Dim $RadEditDestGPSLatLon = IniRead($settings, 'DestGPS', 'Rad_EditDestGPS_LatLon', '1')
Dim $RadEditDestGPSBrngDist = IniRead($settings, 'DestGPS', 'Rad_EditDestGPS_BrngDist', '4')
Dim $DdLat = IniRead($settings, 'DestGPS', 'dLat', '')
Dim $DdLon = IniRead($settings, 'DestGPS', 'dLon', '')
Dim $DdBrng = IniRead($settings, 'DestGPS', 'dBrng', '')
Dim $DdDist = IniRead($settings, 'DestGPS', 'dDist', '')

Dim $PhilsWdbURL = IniRead($settings, 'PhilsWifiTools', 'WiFiDB_URL', 'http://rihq.randomintervals.com/wifidb/')

Dim $CompassPosition = IniRead($settings, 'WindowPositions', 'CompassPosition', '')
Dim $GpsDetailsPosition = IniRead($settings, 'WindowPositions', 'GpsDetailsPosition', '')
Dim $SoundDir = @ScriptDir & '\Sounds\'
Dim $ImageDir = @ScriptDir & '\Images\'
Dim $TmpDir = @ScriptDir & '\temp\'
Dim $LanguageDir = @ScriptDir & '\Languages\'
Dim $SaveDir = @ScriptDir & '\Save\'
DirCreate($SoundDir)
DirCreate($ImageDir)
DirCreate($TmpDir)
DirCreate($LanguageDir)
DirCreate($SaveDir)

;Define Arrays
Dim $Direction[14];Direction array for sorting by clicking on the header. Needs to be 1 greatet (or more) than the amount of columns

;Cleanup Old Temp Files----------------------------------
_CleanupFiles($TmpDir, '*.tmp')
_CleanupFiles($TmpDir, '*.ldb')
_CleanupFiles($TmpDir, '*.ini')
_CleanupFiles($TmpDir, '*.kml')

Dim $AddDirection = IniRead($settings, 'Options', 'AddDirection', -1)
Dim $SaveGpsHistory = IniRead($settings, 'Options', 'SaveGpsHistory', 0)

Dim $DefaultLanguage = IniRead($settings, 'Language', 'Language', 'English')
Dim $DefaultLanguageFile = IniRead($settings, 'Language', 'LanguageFile', $DefaultLanguage & '.ini')
Dim $DefaultLanguagePath = $LanguageDir & $DefaultLanguageFile
If FileExists($DefaultLanguagePath) = 0 Then
	$DefaultLanguage = 'English'
	$DefaultLanguageFile = 'English.ini'
	$DefaultLanguagePath = $LanguageDir & $DefaultLanguageFile
EndIf

Dim $wp_column_Name_Line = IniRead($settings, 'Wp_Column_Names', 'Wp_Column_Line', "#")
Dim $wp_column_Name_Name = IniRead($settings, 'Wp_Column_Names', 'Wp_Column_Name', "Name")
Dim $wp_column_Name_Desc = IniRead($settings, 'Wp_Column_Names', 'Wp_Column_Desc', "Description")
Dim $wp_column_Name_Notes = IniRead($settings, 'Wp_Column_Names', 'Wp_Column_Notes', "Notes")
Dim $wp_column_Name_Latitude = IniRead($settings, 'Wp_Column_Names', 'Wp_Column_Latitude', "Latitude")
Dim $wp_column_Name_Longitude = IniRead($settings, 'Wp_Column_Names', 'Wp_Column_Longitude', "Longitude")
Dim $wp_column_Name_Bearing = IniRead($settings, 'Wp_Column_Names', 'Wp_Column_Bearing', "Bearing")
Dim $wp_column_Name_Distance = IniRead($settings, 'Wp_Column_Names', 'Wp_Column_Distance', "Distance")
Dim $wp_column_Name_Link = IniRead($settings, 'Wp_Column_Names', 'Wp_Column_Link', "Link")
Dim $wp_column_Name_Author = IniRead($settings, 'Wp_Column_Names', 'Wp_Column_Author', "Author")
Dim $wp_column_Name_Type = IniRead($settings, 'Wp_Column_Names', 'Wp_Column_Type', "Type")
Dim $wp_column_Name_Difficulty = IniRead($settings, 'Wp_Column_Names', 'Wp_Column_Difficulty', "Difficulty")
Dim $wp_column_Name_Terrain = IniRead($settings, 'Wp_Column_Names', 'Wp_Column_Terrain', "Terrain")

Dim $wp_column_Width_Line = IniRead($settings, 'Wp_Column_Width', 'Wp_Column_Line', 35)
Dim $wp_column_Width_Name = IniRead($settings, 'Wp_Column_Width', 'Wp_Column_Name', 100)
Dim $wp_column_Width_Desc = IniRead($settings, 'Wp_Column_Width', 'Wp_Column_Desc', 200)
Dim $wp_column_Width_Notes = IniRead($settings, 'Wp_Column_Width', 'Wp_Column_Notes', 250)
Dim $wp_column_Width_Latitude = IniRead($settings, 'Wp_Column_Width', 'Wp_Column_Latitude', 100)
Dim $wp_column_Width_Longitude = IniRead($settings, 'Wp_Column_Width', 'Wp_Column_Longitude', 100)
Dim $wp_column_Width_Bearing = IniRead($settings, 'Wp_Column_Width', 'Wp_Column_Bearing', 100)
Dim $wp_column_Width_Distance = IniRead($settings, 'Wp_Column_Width', 'Wp_Column_Distance', 100)
Dim $wp_column_Width_Link = IniRead($settings, 'Wp_Column_Width', 'Wp_Column_Link', 100)
Dim $wp_column_Width_Author = IniRead($settings, 'Wp_Column_Width', 'Wp_Column_Author', 100)
Dim $wp_column_Width_Type = IniRead($settings, 'Wp_Column_Width', 'Wp_Column_Type', 100)
Dim $wp_column_Width_Difficulty = IniRead($settings, 'Wp_Column_Width', 'Wp_Column_Difficulty', 100)
Dim $wp_column_Width_Terrain = IniRead($settings, 'Wp_Column_Width', 'Wp_Column_Terrain', 100)

Dim $trk_column_Name_Line = IniRead($settings, 'Trk_Column_Names', 'Trk_Column_Line', "#")
Dim $trk_column_Name_Name = IniRead($settings, 'Trk_Column_Names', 'Trk_Column_Name', "Name")
Dim $trk_column_Name_Desc = IniRead($settings, 'Trk_Column_Names', 'Trk_Column_Desc', "Description")
Dim $trk_column_Name_Comments = IniRead($settings, 'Trk_Column_Names', 'Trk_Column_Comments', "Comments")
Dim $trk_column_Name_Source = IniRead($settings, 'Trk_Column_Names', 'Trk_Column_Source', "Source")
Dim $trk_column_Name_Url = IniRead($settings, 'Trk_Column_Names', 'Trk_Column_Url', "Url")
Dim $trk_column_Name_UrlName = IniRead($settings, 'Trk_Column_Names', 'Trk_Column_UrlName', "Url Name")
Dim $trk_column_Name_Number = IniRead($settings, 'Trk_Column_Names', 'Trk_Column_Number', "Number")

Dim $trk_column_Width_Line = IniRead($settings, 'Trk_Column_Width', 'Trk_Column_Line', 35)
Dim $trk_column_Width_Name = IniRead($settings, 'Trk_Column_Width', 'Trk_Column_Name', 100)
Dim $trk_column_Width_Desc = IniRead($settings, 'Trk_Column_Width', 'Trk_Column_Desc', 200)
Dim $trk_column_Width_Comments = IniRead($settings, 'Trk_Column_Width', 'Trk_Column_Comments', 200)
Dim $trk_column_Width_Source = IniRead($settings, 'Trk_Column_Width', 'Trk_Column_Source', 200)
Dim $trk_column_Width_Url = IniRead($settings, 'Trk_Column_Width', 'Trk_Column_Url', 100)
Dim $trk_column_Width_UrlName = IniRead($settings, 'Trk_Column_Width', 'Trk_Column_UrlName', 100)
Dim $trk_column_Width_Number = IniRead($settings, 'Trk_Column_Width', 'Trk_Column_Number', 35)

Dim $Text_File = IniRead($DefaultLanguagePath, 'GuiText', 'File', '&File')
Dim $Text_SaveAsTXT = IniRead($DefaultLanguagePath, 'GuiText', 'SaveAsTXT', 'Save As TXT')
Dim $Text_SaveAsVS1 = IniRead($DefaultLanguagePath, 'GuiText', 'SaveAsVS1', 'Save As VS1')
Dim $Text_SaveAsVSZ = IniRead($DefaultLanguagePath, 'GuiText', 'SaveAsVSZ', 'Save As VSZ')
Dim $Text_ImportFromTXT = IniRead($DefaultLanguagePath, 'GuiText', 'ImportFromTXT', 'Import From TXT / VS1')
Dim $Text_ImportFromVSZ = IniRead($DefaultLanguagePath, 'GuiText', 'ImportFromVSZ', 'Import From VSZ')
Dim $Text_Exit = IniRead($DefaultLanguagePath, 'GuiText', 'Exit', 'E&xit')
Dim $Text_ExitSaveDb = IniRead($DefaultLanguagePath, 'GuiText', 'ExitSaveDb', 'Exit (Save DB)')

Dim $Text_Edit = IniRead($DefaultLanguagePath, 'GuiText', 'Edit', 'E&dit')
Dim $Text_ClearAll = IniRead($DefaultLanguagePath, 'GuiText', 'ClearAll', 'Clear All')
Dim $Text_Cut = IniRead($DefaultLanguagePath, 'GuiText', 'Cut', 'Cut')
Dim $Text_Copy = IniRead($DefaultLanguagePath, 'GuiText', 'Copy', 'Copy')
Dim $Text_Paste = IniRead($DefaultLanguagePath, 'GuiText', 'Paste', 'Paste')
Dim $Text_Delete = IniRead($DefaultLanguagePath, 'GuiText', 'Delete', 'Delete')
Dim $Text_Select = IniRead($DefaultLanguagePath, 'GuiText', 'Select', 'Select')
Dim $Text_SelectAll = IniRead($DefaultLanguagePath, 'GuiText', 'SelectAll', 'Select All')

Dim $Text_RecoverMsg = IniRead($DefaultLanguagePath, 'GuiText', 'RecoverMsg', 'Old DB Found. Would you like to recover it?')
Dim $Text_DeleteSelected = IniRead($DefaultLanguagePath, 'GuiText', 'DeleteSelected', 'Delete Selected')
Dim $Text_RecoverSelected = IniRead($DefaultLanguagePath, 'GuiText', 'RecoverSelected', 'Recover Selected')
Dim $Text_Exit = IniRead($DefaultLanguagePath, 'GuiText', 'Exit', 'E&xit')
Dim $Text_NewSession = IniRead($DefaultLanguagePath, 'GuiText', 'NewSession', 'New Session')
Dim $Text_Size = IniRead($DefaultLanguagePath, 'GuiText', 'Size', 'Size')
Dim $Text_Error = IniRead($DefaultLanguagePath, 'GuiText', 'Error', 'Error')
Dim $Text_NoMdbSelected = IniRead($DefaultLanguagePath, 'GuiText', 'NoMdbSelected', 'No MDB Selected')
Dim $Text_ImportFolder = IniRead($DefaultLanguagePath, 'GuiText', 'ImportFolder', 'Import Folder')

Dim $Text_Options = IniRead($DefaultLanguagePath, 'GuiText', 'Options', '&Options')

Dim $Text_Settings = IniRead($DefaultLanguagePath, 'GuiText', 'Settings', 'S&ettings')

Dim $Text_Export = IniRead($DefaultLanguagePath, 'GuiText', 'Export', 'Ex&port')
Dim $Text_ExportToKML = IniRead($DefaultLanguagePath, 'GuiText', 'ExportToKML', 'Export To KML')
Dim $Text_ExportToGPX = IniRead($DefaultLanguagePath, 'GuiText', 'ExportToGPX', 'Export To GPX')
Dim $Text_ExportToTXT = IniRead($DefaultLanguagePath, 'GuiText', 'ExportToTXT', 'Export To TXT')
Dim $Text_ExportToNS1 = IniRead($DefaultLanguagePath, 'GuiText', 'ExportToNS1', 'Export To NS1')
Dim $Text_ExportToVS1 = IniRead($DefaultLanguagePath, 'GuiText', 'ExportToVS1', 'Export To VS1')
Dim $Text_ExportToCSV = IniRead($DefaultLanguagePath, 'GuiText', 'ExportToCSV', 'Export To CSV')

Dim $Text_UseGPS = IniRead($DefaultLanguagePath, 'GuiText', 'UseGPS', 'Use &GPS')
Dim $Text_StopGPS = IniRead($DefaultLanguagePath, 'GuiText', 'StopGPS', 'Stop &GPS')

Dim $Text_ActualLoopTime = IniRead($DefaultLanguagePath, 'GuiText', 'ActualLoopTime', 'Loop time')
Dim $Text_Longitude = IniRead($DefaultLanguagePath, 'GuiText', 'Longitude', 'Longitude')
Dim $Text_Latitude = IniRead($DefaultLanguagePath, 'GuiText', 'Latitude', 'Latitude')



$MDBfiles = _FileListToArray($TmpDir, '*.MDB', 1);Find all files in the folder that end in .MDB
If IsArray($MDBfiles) Then
	Opt("GUIOnEventMode", 0)
	$FoundMdbFile = 0
	$RecoverMdbGui = GUICreate($Text_RecoverMsg, 461, 210, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPSIBLINGS))
	GUISetBkColor($BackgroundColor)
	$Recover_Del = GUICtrlCreateButton($Text_DeleteSelected, 10, 150, 215, 25)
	$Recover_Rec = GUICtrlCreateButton($Text_RecoverSelected, 235, 150, 215, 25)
	$Recover_Exit = GUICtrlCreateButton($Text_Exit, 10, 180, 215, 25)
	$Recover_New = GUICtrlCreateButton($Text_NewSession, 235, 180, 215, 25)
	$Recover_List = GUICtrlCreateListView(StringReplace($Text_File, '&', '') & "|" & $Text_Size, 10, 8, 440, 136, $LVS_REPORT + $LVS_SINGLESEL, $LVS_EX_HEADERDRAGDROP + $LVS_EX_GRIDLINES + $LVS_EX_FULLROWSELECT)
	_GUICtrlListView_SetColumnWidth($Recover_List, 0, 335)
	_GUICtrlListView_SetColumnWidth($Recover_List, 1, 100)
	GUICtrlSetBkColor(-1, $ControlBackgroundColor)
	For $FoundMDB = 1 To $MDBfiles[0]
		$mdbfile = $MDBfiles[$FoundMDB]
		If _FileInUse($TmpDir & $mdbfile) = 0 Then
			$FoundMdbFile = 1
			$mdbsize = (FileGetSize($TmpDir & $mdbfile) / 1024) & 'kb'
			$ListRow = _GUICtrlListView_InsertItem($Recover_List, "", 0)
			_GUICtrlListView_SetItemText($Recover_List, $ListRow, $mdbfile, 0)
			_GUICtrlListView_SetItemText($Recover_List, $ListRow, $mdbsize, 1)
		EndIf
	Next
	If $FoundMdbFile = 0 Then
		$MysticacheDB = $TmpDir & $ldatetimestamp & '.mdb'
		$MysticacheDBName = $ldatetimestamp & '.mdb'
	Else
		GUISetState(@SW_SHOW)
		While 1
			$nMsg = GUIGetMsg()
			Switch $nMsg
				Case $GUI_EVENT_CLOSE
					$MysticacheDB = $TmpDir & $ldatetimestamp & '.mdb'
					$MysticacheDBName = $ldatetimestamp & '.mdb'
					ExitLoop
				Case $Recover_New
					$MysticacheDB = $TmpDir & $ldatetimestamp & '.mdb'
					$MysticacheDBName = $ldatetimestamp & '.mdb'
					ExitLoop
				Case $Recover_Exit
					Exit
				Case $Recover_Rec
					$Selected = _GUICtrlListView_GetNextItem($Recover_List); find what AP is selected in the list. returns -1 is nothing is selected
					If $Selected = '-1' Then
						MsgBox(0, $Text_Error, $Text_NoMdbSelected)
					Else
						$mdbfilename = _GUICtrlListView_GetItemText($Recover_List, $Selected)
						$MysticacheDB = $TmpDir & $mdbfilename
						$MysticacheDBName = $mdbfilename
						ExitLoop
					EndIf
				Case $Recover_Del
					$Selected = _GUICtrlListView_GetNextItem($Recover_List); find what AP is selected in the list. returns -1 is nothing is selected
					If $Selected = '-1' Then
						MsgBox(0, $Text_Error, $Text_NoMdbSelected)
					Else
						$fn = _GUICtrlListView_GetItemText($Recover_List, $Selected)
						$fn_fullpath = $TmpDir & $fn
						FileDelete($fn_fullpath)
						_GUICtrlListView_DeleteItem(GUICtrlGetHandle($Recover_List), $Selected)
					EndIf
			EndSwitch
		WEnd
	EndIf
	GUIDelete($RecoverMdbGui)
	Opt("GUIOnEventMode", 1)
Else
	$MysticacheDB = $TmpDir & $ldatetimestamp & '.mdb'
	$MysticacheDBName = $ldatetimestamp & '.mdb'
EndIf

If FileExists($MysticacheDB) Then
	$Recover = 1
Else
	_SetUpDbTables($MysticacheDB)
EndIf

;Set Waypoint listview headers
Dim $UseDefaultWpHeaders = 0
Dim $wp_headers
$wpcnames = IniReadSection($settings, "Wp_Column_Names")
If @error Then
	$UseDefaultWpHeaders = 1
Else
	$var = IniReadSection($settings, "Wp_Columns")
	If @error Then
		$UseDefaultWpHeaders = 2
	Else
		Dim $wp_column_Line = IniRead($settings, 'Wp_Columns', 'Wp_Column_Line', 0)
		Dim $wp_column_Name = IniRead($settings, 'Wp_Columns', 'Wp_Column_Name', 1)
		Dim $wp_column_Desc = IniRead($settings, 'Wp_Columns', 'Wp_Column_Desc', 2)
		Dim $wp_column_Notes = IniRead($settings, 'Wp_Columns', 'Wp_Column_Notes', 3)
		Dim $wp_column_Latitude = IniRead($settings, 'Wp_Columns', 'Wp_Column_Latitude', 4)
		Dim $wp_column_Longitude = IniRead($settings, 'Wp_Columns', 'Wp_Column_Longitude', 5)
		Dim $wp_column_Bearing = IniRead($settings, 'Wp_Columns', 'Wp_Column_Bearing', 6)
		Dim $wp_column_Distance = IniRead($settings, 'Wp_Columns', 'Wp_Column_Distance', 7)
		Dim $wp_column_Link = IniRead($settings, 'Wp_Columns', 'Wp_Column_Link', 8)
		Dim $wp_column_Author = IniRead($settings, 'Wp_Columns', 'Wp_Column_Author', 9)
		Dim $wp_column_Type = IniRead($settings, 'Wp_Columns', 'Wp_Column_Type', 10)
		Dim $wp_column_Difficulty = IniRead($settings, 'Wp_Columns', 'Wp_Column_Difficulty', 11)
		Dim $wp_column_Terrain = IniRead($settings, 'Wp_Columns', 'Wp_Column_Terrain', 12)
		For $a = 0 To ($var[0][0] - 1)
			If $a <> 0 Then $wp_headers &= '|'
			For $b = 1 To $var[0][0]
				If $a = $var[$b][1] Then
					$wp_headers &= IniRead($settings, 'Wp_Column_Names', $var[$b][0], '')
					ExitLoop
				EndIf
			Next
		Next
	EndIf
EndIf

If $UseDefaultWpHeaders <> 0 Then
	Dim $wp_column_Line = 0
	Dim $wp_column_Name = 1
	Dim $wp_column_Desc = 2
	Dim $wp_column_Notes = 3
	Dim $wp_column_Latitude = 4
	Dim $wp_column_Longitude = 5
	Dim $wp_column_Bearing = 6
	Dim $wp_column_Distance = 7
	Dim $wp_column_Link = 8
	Dim $wp_column_Author = 9
	Dim $wp_column_Type = 10
	Dim $wp_column_Difficulty = 11
	Dim $wp_column_Terrain = 12
	$wp_headers = $wp_column_Name_Line & "|" & $wp_column_Name_Name & "|" & $wp_column_Name_Desc & "|" & $wp_column_Name_Notes & "|" & $wp_column_Name_Latitude & "|" & $wp_column_Name_Longitude & "|" & $wp_column_Name_Bearing & "|" & $wp_column_Name_Distance & "|" & $wp_column_Name_Link & "|" & $wp_column_Name_Author & "|" & $wp_column_Name_Type & "|" & $wp_column_Name_Difficulty & "|" & $wp_column_Name_Terrain
EndIf

;Set Track listview headers
Dim $UseDefaultTrkHeaders = 0
Dim $trk_headers
$trkcnames = IniReadSection($settings, "Trk_Column_Names")
If @error Then
	$UseDefaultTrkHeaders = 1
Else
	$var = IniReadSection($settings, "Trk_Columns")
	If @error Then
		$UseDefaultTrkHeaders = 2
	Else
		Dim $trk_column_Line = IniRead($settings, 'Trk_Columns', 'Trk_Column_Line', 0)
		Dim $trk_column_Name = IniRead($settings, 'Trk_Columns', 'Trk_Column_Name', 1)
		Dim $trk_column_Desc = IniRead($settings, 'Trk_Columns', 'Trk_Column_Desc', 2)
		Dim $trk_column_Comments = IniRead($settings, 'Trk_Columns', 'Trk_Column_Comments', 3)
		Dim $trk_column_Source = IniRead($settings, 'Trk_Columns', 'Trk_Column_Source', 4)
		Dim $trk_column_Url = IniRead($settings, 'Trk_Columns', 'Trk_Column_Url', 5)
		Dim $trk_column_UrlName = IniRead($settings, 'Trk_Columns', 'Trk_Column_UrlName', 6)
		Dim $trk_column_Number = IniRead($settings, 'Trk_Columns', 'Trk_Column_Number', 7)
		For $a = 0 To ($var[0][0] - 1)
			If $a <> 0 Then $trk_headers &= '|'
			For $b = 1 To $var[0][0]
				If $a = $var[$b][1] Then
					$trk_headers &= IniRead($settings, 'Trk_Column_Names', $var[$b][0], '')
					ExitLoop
				EndIf
			Next
		Next
	EndIf
EndIf

If $UseDefaultTrkHeaders <> 0 Then
	Dim $trk_column_Line = 0
	Dim $trk_column_Name = 1
	Dim $trk_column_Desc = 2
	Dim $trk_column_Comments = 3
	Dim $trk_column_Source = 4
	Dim $trk_column_Url = 5
	Dim $trk_column_UrlName = 6
	Dim $trk_column_Number = 7
	$trk_headers = $trk_column_Name_Line & '|' & $trk_column_Name_Name & '|' & $trk_column_Name_Desc & '|' & $trk_column_Name_Comments & '|' & $trk_column_Name_Source & '|' & $trk_column_Name_Url & '|' & $trk_column_Name_UrlName & '|' & $trk_column_Name_Name
EndIf

;-------------------------------------------------------------------------------------------------------------------------------
;                                                       GUI
;-------------------------------------------------------------------------------------------------------------------------------

Dim $title = $Script_Name & ' ' & $version & ' - By ' & $Script_Author & ' - ' & _DateLocalFormat($last_modified) & ' - (' & $MysticacheDBName & ')'
$MysticacheGUI = GUICreate($title, 980, 692, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPSIBLINGS))
GUISetBkColor($BackgroundColor)

$a = WinGetPos($MysticacheGUI);Get window current position
Dim $State = IniRead($settings, 'WindowPositions', 'MysticacheState', "Window");Get last window position from the ini file
Dim $Position = IniRead($settings, 'WindowPositions', 'MysticachePosition', $a[0] & ',' & $a[1] & ',' & $a[2] & ',' & $a[3])
$b = StringSplit($Position, ",") ;Split ini posion string

If $State = "Maximized" Then
	WinSetState($title, "", @SW_MAXIMIZE)
Else
	WinMove($title, "", $b[1], $b[2], $b[3], $b[4]);Resize window to ini value
EndIf
;File Menu
$file = GUICtrlCreateMenu($Text_File)
$NewSession = GUICtrlCreateMenuItem("New Session", $file)
;$SaveAsTXT = GUICtrlCreateMenuItem($Text_SaveAsTXT, $file)
;$SaveAsDetailedTXT = GUICtrlCreateMenuItem($Text_SaveAsVS1, $file)
;$ExportFromVSZ = GUICtrlCreateMenuItem($Text_SaveAsVSZ, $file)
;$ImportFromTXT = GUICtrlCreateMenuItem($Text_ImportFromTXT, $file)
$ImportFromGPX = GUICtrlCreateMenuItem("Import GPX", $file)
$ImportFromLoc = GUICtrlCreateMenuItem("Import LOC", $file)
;$ImportFromVSZ = GUICtrlCreateMenuItem($Text_ImportFromVSZ, $file)
;$ImportFolder = GUICtrlCreateMenuItem($Text_ImportFolder, $file)
$ExitSaveDB = GUICtrlCreateMenuItem($Text_ExitSaveDb, $file)
$ExitMysticache = GUICtrlCreateMenuItem($Text_Exit, $file)
;Edit Menu
$Edit = GUICtrlCreateMenu($Text_Edit)
;$Cut = GUICtrlCreateMenuitem("Cut", $Edit)
;$Copy = GUICtrlCreateMenuItem($Text_Copy, $Edit)
;$Delete = GUICtrlCreateMenuItem("Delete", $Edit)
;$SelectAll = GUICtrlCreateMenuItem("Select All", $Edit)
$ClearAll = GUICtrlCreateMenuItem($Text_ClearAll, $Edit)
$Options = GUICtrlCreateMenu($Text_Options)
$But_SaveGpsHistory = GUICtrlCreateMenuItem("Save GPS History", $Options)
If $SaveGpsHistory = 1 Then GUICtrlSetState($But_SaveGpsHistory, $GUI_CHECKED)
$But_AddWaypointsToTop = GUICtrlCreateMenuItem("Add new waypoints to top of list", $Options)
If $AddDirection = 0 Then GUICtrlSetState($But_AddWaypointsToTop, $GUI_CHECKED)

$View = GUICtrlCreateMenu("View")
$ViewWaypoints = GUICtrlCreateMenuItem("Waypoints", $View)
GUICtrlSetState($ViewWaypoints, $GUI_CHECKED)
$ViewTrack = GUICtrlCreateMenuItem("Tracks", $View)

$SettingsMenu = GUICtrlCreateMenu($Text_Settings)
$SetGPS = GUICtrlCreateMenuItem("GPS Settings", $SettingsMenu)

$Export = GUICtrlCreateMenu($Text_Export)
$ExportGpxMenu = GUICtrlCreateMenu($Text_ExportToGPX, $Export)
$ExportToGPX = GUICtrlCreateMenuItem("All Waypoints", $ExportGpxMenu)
$ExportLocMenu = GUICtrlCreateMenu("Export To LOC", $Export)
$ExportToLoc = GUICtrlCreateMenuItem("All Waypoints", $ExportLocMenu)
$ExportCsvMenu = GUICtrlCreateMenu($Text_ExportToCSV, $Export)
$ExportToCsv = GUICtrlCreateMenuItem("All Waypoints", $ExportCsvMenu)
$ExportKmlMenu = GUICtrlCreateMenu($Text_ExportToKML, $Export)
$ExportToKML = GUICtrlCreateMenuItem("All Waypoints", $ExportKmlMenu)

$Extra = GUICtrlCreateMenu("Extra")
$GpsDetails = GUICtrlCreateMenuItem("Gps Details", $Extra)
$GpsCompass = GUICtrlCreateMenuItem("Compass", $Extra)
$OpenSaveFolder = GUICtrlCreateMenuItem("Open Save Folder", $Extra)
$OpenWptLink = GUICtrlCreateMenuItem("Open Waypoint Link", $Extra)
$AddToMysticacheDB = GUICtrlCreateMenuItem("Upload Data to MysticacheDB", $Extra)

$But_UseGPS = GUICtrlCreateButton($Text_UseGPS, 15, 8, 120, 20, 0)
;Waypoint Controls
$AddWpButton = GUICtrlCreateButton("Add Waypoint", 15, 35, 120, 20, 0)
$EditWpButton = GUICtrlCreateButton("Edit Waypoint", 140, 35, 120, 20, 0)
$DelWpButton = GUICtrlCreateButton("Delete Waypoint", 265, 35, 120, 20, 0)
$SetDestButton = GUICtrlCreateButton("Use as Destination", 390, 35, 120, 20, 0)
$ListviewWPs = GUICtrlCreateListView($wp_headers, 2, 70, 978, 602, $LVS_REPORT + $LVS_SINGLESEL, $LVS_EX_HEADERDRAGDROP + $LVS_EX_GRIDLINES + $LVS_EX_FULLROWSELECT)
GUICtrlSetBkColor(-1, $ControlBackgroundColor)
;Track Controls
$AddTrkButton = GUICtrlCreateButton("Add Track", 15, 35, 120, 20, 0)
GUICtrlSetState($AddTrkButton, $GUI_HIDE)
$EditTrkButton = GUICtrlCreateButton("Edit Track", 140, 35, 120, 20, 0)
GUICtrlSetState($EditTrkButton, $GUI_HIDE)
$DelTrkButton = GUICtrlCreateButton("Delete Track", 265, 35, 120, 20, 0)
GUICtrlSetState($DelTrkButton, $GUI_HIDE)
$ListviewTrk = GUICtrlCreateListView($trk_headers, 2, 70, 978, 602, $LVS_REPORT + $LVS_SINGLESEL, $LVS_EX_HEADERDRAGDROP + $LVS_EX_GRIDLINES + $LVS_EX_FULLROWSELECT)
GUICtrlSetState($ListviewTrk, $GUI_HIDE)
GUICtrlSetBkColor(-1, $ControlBackgroundColor)

$Grp_StartGPS = GUICtrlCreateGroup("Start GPS Position", 520, 0, 440, 60)
$Rad_StartGPS_CurrentPos = GUICtrlCreateRadio("", 530, 15, 17, 17)
$Lab_Rad_CurrentPos = GUICtrlCreateLabel("Current GPS Position", 550, 17, 350, 17)
If $RadStartGpsCurPos = 1 Then GUICtrlSetState($Rad_StartGPS_CurrentPos, $GUI_CHECKED)
$Rad_StartGPS_LatLon = GUICtrlCreateRadio("", 530, 35, 17, 17)
If $RadStartGpsLatLon = 1 Then GUICtrlSetState($Rad_StartGPS_LatLon, $GUI_CHECKED)
GUICtrlCreateLabel("Latitude:", 550, 37, 45, 17)
$cLat = GUICtrlCreateInput($DcLat, 600, 35, 100, 21)
GUICtrlCreateLabel("Longitude:", 705, 37, 50, 17)
$cLon = GUICtrlCreateInput($DcLon, 760, 35, 100, 21)
$But_GetCurrentGps = GUICtrlCreateButton("Get Current GPS", 865, 35, 90, 21, $WS_GROUP)

$Lab_StartGPS = GUICtrlCreateLabel("", 140, 5, 380, 15)
GUICtrlSetColor(-1, $TextColor)
$Lab_DestGPS = GUICtrlCreateLabel("Dest GPS:     Not Set Yet", 140, 20, 380, 15)
GUICtrlSetColor(-1, $TextColor)

_SetControlSizes()
_SetListviewWidthsWp()
_SetListviewWidthsTrk()
GUISetState(@SW_SHOW)

;Button-Events-------------------------------------------
GUISetOnEvent($GUI_EVENT_CLOSE, '_Exit')
;GUISetOnEvent($GUI_EVENT_RESIZED, '_ResetSizes')
;GUISetOnEvent($GUI_EVENT_MINIMIZE, '_ResetSizes')
;GUISetOnEvent($GUI_EVENT_RESTORE, '_ResetSizes')
;GUISetOnEvent($GUI_EVENT_MAXIMIZE, '_ResetSizes')
;Buttons
GUICtrlSetOnEvent($But_UseGPS, '_GpsToggle')
GUICtrlSetOnEvent($AddWpButton, '_AddWaypointGUI')
GUICtrlSetOnEvent($EditWpButton, '_EditWaypointGUI')
GUICtrlSetOnEvent($DelWpButton, '_DeleteWaypoint')
GUICtrlSetOnEvent($SetDestButton, '_SetDestination')
GUICtrlSetOnEvent($But_GetCurrentGps, '_GetCurrentGps')
;File Menu
GUICtrlSetOnEvent($NewSession, '_NewSession')
;GUICtrlSetOnEvent($SaveAsTXT, '_ExportData')
;GUICtrlSetOnEvent($SaveAsDetailedTXT, '_ExportDetailedData')
;GUICtrlSetOnEvent($ImportFromTXT, 'LoadList')
GUICtrlSetOnEvent($ImportFromGPX, '_ImportGPX')
GUICtrlSetOnEvent($ImportFromLoc, '_ImportLoc')
;GUICtrlSetOnEvent($ImportFromVSZ, '_ImportVSZ')
;GUICtrlSetOnEvent($ExportFromVSZ, '_ExportVSZ')
;GUICtrlSetOnEvent($ImportFolder, '_LoadFolder')
GUICtrlSetOnEvent($ExitSaveDB, '_ExitSaveDB')
GUICtrlSetOnEvent($ExitMysticache, '_Exit')

;Edit Menu
GUICtrlSetOnEvent($ClearAll, '_ClearAll')
;GUICtrlSetOnEvent($Copy, '_CopyAP')

;View Menu
GUICtrlSetOnEvent($ViewWaypoints, '_ToggleWaypointView')
GUICtrlSetOnEvent($ViewTrack, '_ToggleTrackView')

;Optons Menu
GUICtrlSetOnEvent($But_SaveGpsHistory, '_SaveGpsHistoryToggle')
GUICtrlSetOnEvent($But_AddWaypointsToTop, '_AddWpPosToggle')

;Export Menu
GUICtrlSetOnEvent($ExportToGPX, '_ExportAllToGPX')
GUICtrlSetOnEvent($ExportToLoc, '_ExportAllToLOC')
;GUICtrlSetOnEvent($ExportToTXT, '_ExportData')
;GUICtrlSetOnEvent($ExportToVS1, '_ExportDetailedData')
GUICtrlSetOnEvent($ExportToCsv, '_ExportCsvData')
GUICtrlSetOnEvent($ExportToKML, '_ExportAllToKml')
;GUICtrlSetOnEvent($CreateApSignalMap, '_KmlSignalMapSelectedAP')

;Settings Menu
GUICtrlSetOnEvent($SetGPS, '_GPSOptions')
;Extra
GUICtrlSetOnEvent($GpsCompass, '_CompassGUI')
GUICtrlSetOnEvent($GpsDetails, '_OpenGpsDetailsGUI')
GUICtrlSetOnEvent($OpenSaveFolder, '_OpenSaveFolder')
GUICtrlSetOnEvent($OpenWptLink, '_OpenWptLink')
GUICtrlSetOnEvent($AddToMysticacheDB, '_AddToMysticacheDB')

;Other
GUICtrlSetOnEvent($ListviewWPs, '_SortColumnToggleWp')

;Set Listview Widths
_SetListviewWidthsWp()

If $Recover = 1 Then _RecoverMDB()

;If $Load <> '' Then AutoLoadList($Load)
$UpdatedGPS = 0
$UdatedStartGPS = 0
$UpdatedWpListData = 0
$UpdatedCompass = 0
$begin = TimerInit() ;Start $begin timer, used to measure loop time
While 1
	;Set TimeStamps (UTC Values)
	$dt = StringSplit(_DateTimeUtcConvert(StringFormat("%04i", @YEAR) & '-' & StringFormat("%02i", @MON) & '-' & StringFormat("%02i", @MDAY), @HOUR & ':' & @MIN & ':' & @SEC & '.' & StringFormat("%03i", @MSEC), 1), ' ') ;UTC Time
	$datestamp = $dt[1]
	$timestamp = $dt[2]
	$ldatetimestamp = StringFormat("%04i", @YEAR) & '-' & StringFormat("%02i", @MON) & '-' & StringFormat("%02i", @MDAY) & ' ' & @HOUR & '-' & @MIN & '-' & @SEC ;Local Time

	If $UseGPS = 1 And $UpdatedGPS = 0 Then
		$GetGpsSuccess = _GetGPS();Scan for GPS if GPS enabled
		If $GetGpsSuccess = 1 And $SaveGpsHistory = 1 Then
			$TRACKSEGID += 1
			_AddRecord($MysticacheDB, "TRACKSEG", $DB_OBJ, $TRACKSEGID & '|0|' & $Latitude & '|' & $Longitude & '|' & $Alt & '|' & $datestamp & 'T' & $timestamp & 'Z' & '||' & $TrackAngle & '|' & $Geo & '||' & $NumberOfSatalites & '|' & $HorDilPitch & '|||||' & $SpeedInKmH & '||||' & $Script_Name & '||||')
		EndIf
		If $GetGpsSuccess = 1 Then $UpdatedGPS = 1
	EndIf

	If $UdatedStartGPS = 0 Then
		If GUICtrlRead($Rad_StartGPS_CurrentPos) = 1 Then
			$StartLat = $Latitude
			$StartLon = $Longitude
		ElseIf GUICtrlRead($Rad_StartGPS_LatLon) = 1 Then
			$StartLat = _Format_GPS_All_to_DMM(GUICtrlRead($cLat), "N", "S")
			$StartLon = _Format_GPS_All_to_DMM(GUICtrlRead($cLon), "E", "W")
		EndIf
		GUICtrlSetData($Lab_Rad_CurrentPos, "Current GPS Position: Lat: " & _GpsFormat($Latitude) & " Lon: " & _GpsFormat($Longitude))
		GUICtrlSetData($Lab_StartGPS, 'Start GPS:     Latitude: ' & _GpsFormat($StartLat) & '     Longitude: ' & _GpsFormat($StartLon))
		$UdatedStartGPS = 1
	EndIf

	If $UpdatedWpListData = 0 Then
		_UpdateDestBrng()
		$UpdatedWpListData = 1
	EndIf

	If $UpdatedCompass = 0 Then
		;Compass Window and Drawing
		$DestBrng = _BearingBetweenPoints($StartLat, $StartLon, $DestLat, $DestLon)
		$DestDist = _DistanceBetweenPoints($StartLat, $StartLon, $DestLat, $DestLon)
		_SetCompassSizes()
		If $UseGPS = 1 And GUICtrlRead($Rad_StartGPS_CurrentPos) = 1 Then
			If $DestSet = 1 Then _DrawCompassLine($DestBrng, "0xFFFF3333")
			_DrawCompassLine($TrackAngle, "0xFF000000")
		EndIf

		If $DestSet = 1 Then
			_DrawCompassLine($DestBrng, "0xFFFF3333")
			$RoundedDestDist = Round($DestDist)
			If $RoundedDestDist <= 25 Then
				_DrawCompassCircle(90, "0xFF228b22")
			ElseIf $RoundedDestDist <= 50 Then
				_DrawCompassCircle(75, "0xFFadff2f")
			ElseIf $RoundedDestDist <= 100 Then
				_DrawCompassCircle(60, "0xFFffff00")
			ElseIf $RoundedDestDist <= 200 Then
				_DrawCompassCircle(45, "0xFFdaa520")
			ElseIf $RoundedDestDist <= 400 Then
				_DrawCompassCircle(30, "0xFFff4500")
			ElseIf $RoundedDestDist <= 600 Then
				_DrawCompassCircle(15, "0xFFff0000")
			EndIf
		EndIf
		$UpdatedCompass = 1
	EndIf

	;Check Mysticache Window Position
	If _WinMoved() Then _SetControlSizes()

	;Check Compass Windows Position
	If WinActive($CompassGUI) And $CompassOpen = 1 Then
		$c = WinGetPos($CompassGUI)
		If $c[0] & ',' & $c[1] & ',' & $c[2] & ',' & $c[3] <> $CompassPosition Then $CompassPosition = $c[0] & ',' & $c[1] & ',' & $c[2] & ',' & $c[3] ;If the $CompassGUI has moved or resized, set $CompassPosition to current window size
	EndIf

	;Check GPS Details Windows Position
	If WinActive($GpsDetailsGUI) And $GpsDetailsOpen = 1 Then
		$g = WinGetPos($GpsDetailsGUI)
		If $g[0] & ',' & $g[1] & ',' & $g[2] & ',' & $g[3] <> $GpsDetailsPosition Then $GpsDetailsPosition = $g[0] & ',' & $g[1] & ',' & $g[2] & ',' & $g[3] ;If the $GpsDetails has moved or resized, set $GpsDetailsPosition to current window size
	EndIf

	If $TurnOffGPS = 1 Then _TurnOffGPS()
	If $Close = 1 Then _ExitMysticache($SaveDbOnExit) ;If the close flag has been set, exit visumbler
	If $SortColumn <> -1 Then _HeaderSortWp($SortColumn);Sort clicked listview column
	If $ClearAllWps = 1 Then _ClearAllWp();Clear all Waypoint

	If TimerDiff($begin) >= $RefreshLoopTime Then
		$UpdatedGPS = 0
		$UdatedStartGPS = 0
		$UpdatedWpListData = 0
		$UpdatedCompass = 0
		$begin = TimerInit()
	Else
		Sleep(10)
	EndIf
WEnd

;-------------------------------------------------------------------------------------------------------------------------------
;WINDOW FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------

Func _WinMoved();Checks if window has moved. Returns 1 if it has
	$a = WinGetPos($MysticacheGUI)
	$winpos_old = $winpos
	$winpos = $a[0] & $a[1] & $a[2] & $a[3] & WinGetState($title, "")

	If $winpos_old <> $winpos Then
		;Set window state and position
		$winstate = WinGetState($title, "")
		If BitAND($winstate, 32) Then;Set
			$State = "Maximized"
		Else
			$State = "Window"
			$Position = $a[0] & ',' & $a[1] & ',' & $a[2] & ',' & $a[3]
		EndIf
		Return 1 ;Set Flag that window moved
	Else
		Return 0 ;Set Flag that window did not move
	EndIf
EndFunc   ;==>_WinMoved

Func _SetControlSizes();Sets control positions in GUI based on the windows current size
	$a = _WinGetPosEx($MysticacheGUI) ;get mysticache window size
	$AeroOn = @extended
	$sizes = $a[0] & '-' & $a[1] & '-' & $a[2] & '-' & $a[3]
	If $sizes <> $sizes_old Or $Redraw = 1 Then
		$DataChild_Left = 2
		$DataChild_Width = $a[2]
		$DataChild_Top = 70
		$DataChild_Height = $a[3] - $DataChild_Top
		If $AeroOn = 1 Then ;Fix Widths for Aero
			$DataChild_Width -= 16
			$DataChild_Height -= 58
		Else
			$DataChild_Width -= 9
			$DataChild_Height -= 48
		EndIf

		$Redraw = 0
		$ListviewWPs_left = $DataChild_Left
		$ListviewWPs_width = $DataChild_Width - $ListviewWPs_left
		$ListviewWPs_top = $DataChild_Top
		$ListviewWPs_height = $DataChild_Height

		GUICtrlSetPos($ListviewWPs, $ListviewWPs_left, $ListviewWPs_top, $ListviewWPs_width, $ListviewWPs_height)
		GUICtrlSetState($ListviewWPs, $GUI_FOCUS)
	EndIf
	$sizes_old = $sizes
EndFunc   ;==>_SetControlSizes

Func _Exit()
	$Close = 1
	$SaveDbOnExit = 0
EndFunc   ;==>_Exit

Func _ExitSaveDB()
	$Close = 1
	$SaveDbOnExit = 1
EndFunc   ;==>_ExitSaveDB

Func _ExitMysticache($SaveDB = 0)
	_AccessCloseConn($DB_OBJ)
	_SaveSettings()
	If $SaveDB <> 1 Then FileDelete($MysticacheDB)
	If $UseGPS = 1 Then ;If GPS is active, stop it so the COM port does not stay open
		_TurnOffGPS()
		Exit
	Else
		Exit
	EndIf
EndFunc   ;==>_ExitMysticache

Func _SaveSettings()

	IniWrite($settings, "Options", "AddDirection", $AddDirection)
	IniWrite($settings, "Options", "SaveGpsHistory", $SaveGpsHistory)

	IniWrite($settings, "Language", "Language", $DefaultLanguage)
	IniWrite($settings, "Language", "LanguageFile", $DefaultLanguageFile)

	$currentwpcolumn = StringSplit(_GUICtrlListView_GetColumnOrder($ListviewWPs), '|')
	For $c = 1 To $currentwpcolumn[0]
		If $wp_column_Line = $currentwpcolumn[$c] Then $save_wp_column_Line = $c - 1
		If $wp_column_Name = $currentwpcolumn[$c] Then $save_wp_column_Name = $c - 1
		If $wp_column_Desc = $currentwpcolumn[$c] Then $save_wp_column_Desc = $c - 1
		If $wp_column_Notes = $currentwpcolumn[$c] Then $save_wp_column_Notes = $c - 1
		If $wp_column_Latitude = $currentwpcolumn[$c] Then $save_wp_column_Latitude = $c - 1
		If $wp_column_Longitude = $currentwpcolumn[$c] Then $save_wp_column_Longitude = $c - 1
		If $wp_column_Bearing = $currentwpcolumn[$c] Then $save_wp_column_Bearing = $c - 1
		If $wp_column_Distance = $currentwpcolumn[$c] Then $save_wp_column_Distance = $c - 1
		If $wp_column_Link = $currentwpcolumn[$c] Then $save_wp_column_Link = $c - 1
		If $wp_column_Author = $currentwpcolumn[$c] Then $save_wp_column_Author = $c - 1
		If $wp_column_Type = $currentwpcolumn[$c] Then $save_wp_column_Type = $c - 1
		If $wp_column_Difficulty = $currentwpcolumn[$c] Then $save_wp_column_Difficulty = $c - 1
		If $wp_column_Terrain = $currentwpcolumn[$c] Then $save_wp_column_Terrain = $c - 1
	Next

	IniWrite($settings, "Wp_Columns", "Wp_Column_Line", $save_wp_column_Line)
	IniWrite($settings, "Wp_Columns", "Wp_Column_Name", $save_wp_column_Name)
	IniWrite($settings, "Wp_Columns", "Wp_Column_Desc", $save_wp_column_Desc)
	IniWrite($settings, "Wp_Columns", "Wp_Column_Notes", $save_wp_column_Notes)
	IniWrite($settings, "Wp_Columns", "Wp_Column_Latitude", $save_wp_column_Latitude)
	IniWrite($settings, "Wp_Columns", "Wp_Column_Longitude", $save_wp_column_Longitude)
	IniWrite($settings, "Wp_Columns", "Wp_Column_Bearing", $save_wp_column_Bearing)
	IniWrite($settings, "Wp_Columns", "Wp_Column_Distance", $save_wp_column_Distance)
	IniWrite($settings, "Wp_Columns", "Wp_Column_Link", $save_wp_column_Link)
	IniWrite($settings, "Wp_Columns", "Wp_Column_Author", $save_wp_column_Author)
	IniWrite($settings, "Wp_Columns", "Wp_Column_Type", $save_wp_column_Type)
	IniWrite($settings, "Wp_Columns", "Wp_Column_Difficulty", $save_wp_column_Difficulty)
	IniWrite($settings, "Wp_Columns", "Wp_Column_Terrain", $save_wp_column_Terrain)

	_GetListviewWidthsWp()
	IniWrite($settings, "Wp_Column_Width", "Wp_Column_Line", $wp_column_Width_Line)
	IniWrite($settings, "Wp_Column_Width", "Wp_Column_Name", $wp_column_Width_Name)
	IniWrite($settings, "Wp_Column_Width", "Wp_Column_Desc", $wp_column_Width_Desc)
	IniWrite($settings, "Wp_Column_Width", "Wp_Column_Notes", $wp_column_Width_Notes)
	IniWrite($settings, "Wp_Column_Width", "Wp_Column_Latitude", $wp_column_Width_Latitude)
	IniWrite($settings, "Wp_Column_Width", "Wp_Column_Longitude", $wp_column_Width_Longitude)
	IniWrite($settings, "Wp_Column_Width", "Wp_Column_Bearing", $wp_column_Width_Bearing)
	IniWrite($settings, "Wp_Column_Width", "Wp_Column_Distance", $wp_column_Width_Distance)
	IniWrite($settings, "Wp_Column_Width", "Wp_Column_Link", $wp_column_Width_Link)
	IniWrite($settings, "Wp_Column_Width", "Wp_Column_Author", $wp_column_Width_Author)
	IniWrite($settings, "Wp_Column_Width", "Wp_Column_Type", $wp_column_Width_Type)
	IniWrite($settings, "Wp_Column_Width", "Wp_Column_Difficulty", $wp_column_Width_Difficulty)
	IniWrite($settings, "Wp_Column_Width", "Wp_Column_Terrain", $wp_column_Width_Terrain)

	IniWrite($settings, "Wp_Column_Names", "Wp_Column_Line", $wp_column_Name_Line)
	IniWrite($settings, "Wp_Column_Names", "Wp_Column_Name", $wp_column_Name_Name)
	IniWrite($settings, "Wp_Column_Names", "Wp_Column_Desc", $wp_column_Name_Desc)
	IniWrite($settings, "Wp_Column_Names", "Wp_Column_Notes", $wp_column_Name_Notes)
	IniWrite($settings, "Wp_Column_Names", "Wp_Column_Latitude", $wp_column_Name_Latitude)
	IniWrite($settings, "Wp_Column_Names", "Wp_Column_Longitude", $wp_column_Name_Longitude)
	IniWrite($settings, "Wp_Column_Names", "Wp_Column_Bearing", $wp_column_Name_Bearing)
	IniWrite($settings, "Wp_Column_Names", "Wp_Column_Distance", $wp_column_Name_Distance)
	IniWrite($settings, "Wp_Column_Names", "Wp_Column_Link", $wp_column_Name_Link)
	IniWrite($settings, "Wp_Column_Names", "Wp_Column_Author", $wp_column_Name_Author)
	IniWrite($settings, "Wp_Column_Names", "Wp_Column_Type", $wp_column_Name_Type)
	IniWrite($settings, "Wp_Column_Names", "Wp_Column_Difficulty", $wp_column_Name_Difficulty)
	IniWrite($settings, "Wp_Column_Names", "Wp_Column_Terrain", $wp_column_Name_Terrain)

	$currenttrkcolumn = StringSplit(_GUICtrlListView_GetColumnOrder($ListviewTrk), '|')
	For $c = 1 To $currenttrkcolumn[0]
		If $trk_column_Line = $currenttrkcolumn[$c] Then $save_trk_column_Line = $c - 1
		If $trk_column_Name = $currenttrkcolumn[$c] Then $save_trk_column_Name = $c - 1
		If $trk_column_Desc = $currenttrkcolumn[$c] Then $save_trk_column_Desc = $c - 1
		If $trk_column_Comments = $currenttrkcolumn[$c] Then $save_trk_column_Comments = $c - 1
		If $trk_column_Source = $currenttrkcolumn[$c] Then $save_trk_column_Source = $c - 1
		If $trk_column_Url = $currenttrkcolumn[$c] Then $save_trk_column_Url = $c - 1
		If $trk_column_UrlName = $currenttrkcolumn[$c] Then $save_trk_column_UrlName = $c - 1
		If $trk_column_Number = $currenttrkcolumn[$c] Then $save_trk_column_Number = $c - 1
	Next

	IniWrite($settings, "Trk_Columns", "Trk_Column_Line", $save_trk_column_Line)
	IniWrite($settings, "Trk_Columns", "Trk_Column_Name", $save_trk_column_Name)
	IniWrite($settings, "Trk_Columns", "Trk_Column_Desc", $save_trk_column_Desc)
	IniWrite($settings, "Trk_Columns", "Trk_Column_Comments", $save_trk_column_Comments)
	IniWrite($settings, "Trk_Columns", "Trk_Column_Source", $save_trk_column_Source)
	IniWrite($settings, "Trk_Columns", "Trk_Column_Url", $save_trk_column_Url)
	IniWrite($settings, "Trk_Columns", "Trk_Column_UrlName", $save_trk_column_UrlName)
	IniWrite($settings, "Trk_Columns", "Trk_Column_Number", $save_trk_column_Number)

	_GetListviewWidthsTrk()
	IniWrite($settings, "Trk_Column_Width", "Trk_Column_Line", $trk_column_Width_Line)
	IniWrite($settings, "Trk_Column_Width", "Trk_Column_Name", $trk_column_Width_Name)
	IniWrite($settings, "Trk_Column_Width", "Trk_Column_Desc", $trk_column_Width_Desc)
	IniWrite($settings, "Trk_Column_Width", "Trk_Column_Comments", $trk_column_Width_Comments)
	IniWrite($settings, "Trk_Column_Width", "Trk_Column_Source", $trk_column_Width_Source)
	IniWrite($settings, "Trk_Column_Width", "Trk_Column_Url", $trk_column_Width_Url)
	IniWrite($settings, "Trk_Column_Width", "Trk_Column_UrlName", $trk_column_Width_UrlName)
	IniWrite($settings, "Trk_Column_Width", "Trk_Column_Number", $trk_column_Width_Number)

	IniWrite($settings, "Trk_Column_Names", "Trk_Column_Line", $trk_column_Name_Line)
	IniWrite($settings, "Trk_Column_Names", "Trk_Column_Name", $trk_column_Name_Name)
	IniWrite($settings, "Trk_Column_Names", "Trk_Column_Desc", $trk_column_Name_Desc)
	IniWrite($settings, "Trk_Column_Names", "Trk_Column_Comments", $trk_column_Name_Comments)
	IniWrite($settings, "Trk_Column_Names", "Trk_Column_Source", $trk_column_Name_Source)
	IniWrite($settings, "Trk_Column_Names", "Trk_Column_Url", $trk_column_Name_Url)
	IniWrite($settings, "Trk_Column_Names", "Trk_Column_UrlName", $trk_column_Name_UrlName)
	IniWrite($settings, "Trk_Column_Names", "Trk_Column_Number", $trk_column_Name_Number)

	IniWrite($settings, 'WindowPositions', 'State', $State)
	IniWrite($settings, 'WindowPositions', 'Position', $Position)
	IniWrite($settings, 'WindowPositions', 'CompassPosition', $CompassPosition)
	IniWrite($settings, 'WindowPositions', 'GpsDetailsPosition', $GpsDetailsPosition)

	IniWrite($settings, 'Colors', 'BackgroundColor', $BackgroundColor)
	IniWrite($settings, 'Colors', 'ControlBackgroundColor', $ControlBackgroundColor)
	IniWrite($settings, 'Colors', 'TextColor', $TextColor)

	IniWrite($settings, 'GpsSettings', 'ComPort', $ComPort)
	IniWrite($settings, 'GpsSettings', 'Baud', $BAUD)
	IniWrite($settings, 'GpsSettings', 'Parity', $PARITY)
	IniWrite($settings, 'GpsSettings', 'DataBit', $DATABIT)
	IniWrite($settings, 'GpsSettings', 'StopBit', $STOPBIT)
	IniWrite($settings, 'GpsSettings', 'GpsTimeout', $GpsTimeout)
	IniWrite($settings, 'GpsSettings', 'GpsType', $GpsType)
	IniWrite($settings, 'GpsSettings', 'GpsFormat', $GpsFormat)

	IniWrite($settings, 'StartGPS', 'Rad_StartGPS_CurrentPos', GUICtrlRead($Rad_StartGPS_CurrentPos))
	IniWrite($settings, 'StartGPS', 'Rad_StartGPS_LatLon', GUICtrlRead($Rad_StartGPS_LatLon))
	IniWrite($settings, 'StartGPS', 'cLat', GUICtrlRead($cLat))
	IniWrite($settings, 'StartGPS', 'cLon', GUICtrlRead($cLon))

	IniWrite($settings, 'DestGPS', 'Rad_DestGPS_LatLon', $RadDestGPSLatLon)
	IniWrite($settings, 'DestGPS', 'Rad_DestGPS_BrngDist', $RadDestGPSBrngDist)
	IniWrite($settings, 'DestGPS', 'Rad_EditDestGPS_LatLon', $RadEditDestGPSLatLon)
	IniWrite($settings, 'DestGPS', 'Rad_EditDestGPS_BrngDist', $RadEditDestGPSBrngDist)

EndFunc   ;==>_SaveSettings

Func _UpdateDestBrng()
	$query = "SELECT WPID, ListRow, Latitude, Longitude, Bearing, Distance FROM WP"
	$WpMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
	$FoundWpMatch = UBound($WpMatchArray) - 1
	If $FoundWpMatch <> 0 Then ;If WP was found
		For $udb = 1 To $FoundWpMatch
			$DB_WPID = $WpMatchArray[$udb][1]
			$DB_ListRow = $WpMatchArray[$udb][2]
			$DB_Latitude = $WpMatchArray[$udb][3]
			$DB_Longitude = $WpMatchArray[$udb][4]
			$DB_Bearing = $WpMatchArray[$udb][5]
			$DB_Distance = $WpMatchArray[$udb][6]

			$New_Brng = StringFormat('%0.1f', _BearingBetweenPoints($StartLat, $StartLon, $DB_Latitude, $DB_Longitude))
			$New_Dist = StringFormat('%0.1f', _DistanceBetweenPoints($StartLat, $StartLon, $DB_Latitude, $DB_Longitude))

			If $DB_Bearing <> $New_Brng Then
				$UpdBrng = $New_Brng
				$query = "UPDATE WP SET Bearing='" & $New_Brng & "' WHERE WPID='" & $DB_WPID & "'"
				_ExecuteMDB($MysticacheDB, $DB_OBJ, $query)
			Else
				$UpdBrng = ''
			EndIf

			If $DB_Distance <> $New_Dist Then
				$UpdDist = $New_Dist
				$query = "UPDATE WP SET Distance='" & $New_Dist & "' WHERE WPID='" & $DB_WPID & "'"
				_ExecuteMDB($MysticacheDB, $DB_OBJ, $query)
			Else
				$UpdDist = ''
			EndIf

			_ListViewAddWp($DB_ListRow, '', '', '', '', '', '', $UpdBrng, $UpdDist, '', '', '', '', '')
		Next
	EndIf
EndFunc   ;==>_UpdateDestBrng

;-------------------------------------------------------------------------------------------------------------------------------
;DB FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------

Func _SetUpDbTables($dbfile)
	;If $Debug = 1 Then GUICtrlSetData($debugdisplay, '_SetUpDbTables()') ;#Debug Display
	_CreateDB($dbfile)
	_AccessConnectConn($dbfile, $DB_OBJ)
	_CreateTable($dbfile, 'WP', $DB_OBJ)
	_CreateTable($dbfile, 'TRACK', $DB_OBJ)
	_CreateTable($dbfile, 'TRACKSEG', $DB_OBJ)
	_CreatMultipleFields($dbfile, 'WP', $DB_OBJ, 'WPID TEXT(255)|ListRow TEXT(255)|Name TEXT(255)|Desc1 TEXT(255)|Notes TEXT(255)|Latitude TEXT(255)|Longitude TEXT(255)|Bearing TEXT(255)|Distance TEXT(255)|Link TEXT(255)|Author TEXT(255)|Type TEXT(255)|Difficulty TEXT(255)|Terrain TEXT(255)')
	_CreatMultipleFields($dbfile, 'TRACK', $DB_OBJ, 'TRACKID TEXT(255)|ListRow TEXT(255)|name TEXT(255)|desc1 TEXT(255)|cmt TEXT(255)|src TEXT(255)|url TEXT(255)|urlname TEXT(255)|number1 TEXT(255)')
	_CreatMultipleFields($dbfile, 'TRACKSEG', $DB_OBJ, 'TRACKSEGID TEXT(255)|TRACKID TEXT(255)|lat TEXT(20)|lon TEXT(20)|ele TEXT(255)|time1 TEXT(255)|magvar TEXT(255)|course TEXT(255)|geoidheight TEXT(255)|fix TEXT(255)|sat TEXT(255)|hdop TEXT(255)|vdop TEXT(255)|pdop TEXT(255)|ageofgpsdata TEXT(255)|dgpsid TEXT(255)|speed TEXT(255)|name TEXT(255)|cmt TEXT(255)|desc1 TEXT(255)|src TEXT(255)|url TEXT(255)|urlname TEXT(255)|sym TEXT(255)|type TEXT(255)')
	;Create Default GPS Track
	_AddRecord($MysticacheDB, "TRACK", $DB_OBJ, '0|0|' & StringFormat("%04i", @YEAR) & '-' & StringFormat("%02i", @MON) & '-' & StringFormat("%02i", @MDAY) & ' ' & @HOUR & ':' & @MIN & ':' & @SEC & '|||' & $Script_Name & '|||')
EndFunc   ;==>_SetUpDbTables

Func _RecoverMDB()
	_AccessConnectConn($MysticacheDB, $DB_OBJ)
	;Get total WPIDs
	$query = "Select COUNT(WPID) FROM WP"
	$WpMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
	$WPID = $WpMatchArray[1][1]
	ConsoleWrite("WPID:" & $WPID & @CRLF)
	;Get total TRACKIDs
	$query = "Select COUNT(TRACKID) FROM TRACK"
	$TrackMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
	$TRACKID = $TrackMatchArray[1][1]
	ConsoleWrite("TRACKID:" & $TRACKID & @CRLF)
	;Get total TRACKSEGIDs
	$query = "Select COUNT(TRACKSEGID) FROM TRACKSEG"
	$TackSegMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
	$TRACKSEGID = $TackSegMatchArray[1][1]
	ConsoleWrite("TRACKSEGID:" & $TRACKSEGID & @CRLF)

	$query = "UPDATE WP SET ListRow = '-1'"
	_ExecuteMDB($MysticacheDB, $DB_OBJ, $query)
	$query = "SELECT WPID, Name, Desc1, Notes, Latitude, Longitude, Bearing, Distance, Link, Author, Type, Difficulty, Terrain FROM WP"
	$WpMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
	$FoundWpMatch = UBound($WpMatchArray) - 1
	If $FoundWpMatch <> 0 Then ;If WP is not found then add it
		For $rl = 1 To $FoundWpMatch
			$WPWPID = $WpMatchArray[$rl][1]
			$WPName = $WpMatchArray[$rl][2]
			$WPDesc = $WpMatchArray[$rl][3]
			$WPNotes = $WpMatchArray[$rl][4]
			$WPLat = $WpMatchArray[$rl][5]
			$WPLon = $WpMatchArray[$rl][6]
			$WPBrng = $WpMatchArray[$rl][7]
			$WPDist = $WpMatchArray[$rl][8]
			$WPLink = $WpMatchArray[$rl][9]
			$WPAuth = $WpMatchArray[$rl][10]
			$WPType = $WpMatchArray[$rl][11]
			$WPDif = $WpMatchArray[$rl][12]
			$WPTer = $WpMatchArray[$rl][13]
			;Add APs to top of list
			If $AddDirection = 0 Then
				$query = "UPDATE WP SET ListRow = ListRow + 1 WHERE ListRow <> '-1'"
				_ExecuteMDB($MysticacheDB, $DB_OBJ, $query)
				$DBAddPos = 0
			Else ;Add to bottom
				$DBAddPos = -1
			EndIf
			;Add Into ListView
			$ListRow = _GUICtrlListView_InsertItem($ListviewWPs, $WPID, $DBAddPos)
			_ListViewAddWp($ListRow, $WPWPID, $WPName, $WPDesc, $WPNotes, _GpsFormat($WPLat), _GpsFormat($WPLon), $WPBrng, $WPDist, $WPLink, $WPAuth, $WPType, $WPDif, $WPTer)
			$query = "UPDATE WP SET ListRow='" & $ListRow & "' WHERE WPID='" & $WPWPID & "'"
			_ExecuteMDB($MysticacheDB, $DB_OBJ, $query)
		Next
	EndIf
EndFunc   ;==>_RecoverMDB

Func _FixLineNumbers();Update Listview Row Numbers in DataArray
	$ListViewSize = _GUICtrlListView_GetItemCount($ListviewWPs) - 1; Get List Size
	For $lisviewrow = 0 To $ListViewSize
		$APNUM = _GUICtrlListView_GetItemText($ListviewWPs, $lisviewrow, $wp_column_Line)
		$query = "UPDATE WP SET ListRow = '" & $lisviewrow & "' WHERE WPID = '" & $APNUM & "'"
		_ExecuteMDB($MysticacheDB, $DB_OBJ, $query)
	Next
EndFunc   ;==>_FixLineNumbers

;-------------------------------------------------------------------------------------------------------------------------------
;LISTVIEW FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------

Func _ListViewAddWp($line, $Add_Line = '', $Add_Name = '', $Add_Desc = '', $Add_Notes = '', $Add_Latitude = '', $Add_Longitude = '', $Add_Bearing = '', $Add_Distance = '', $Add_Link = '', $Add_Auth = '', $Add_Type = '', $Add_Dif = '', $Add_Ter = '')
	If $Add_Line <> '' Then _GUICtrlListView_SetItemText($ListviewWPs, $line, $Add_Line, $wp_column_Line)
	If $Add_Name <> '' Then _GUICtrlListView_SetItemText($ListviewWPs, $line, $Add_Name, $wp_column_Name)
	If $Add_Desc <> '' Then _GUICtrlListView_SetItemText($ListviewWPs, $line, $Add_Desc, $wp_column_Desc)
	If $Add_Notes <> '' Then _GUICtrlListView_SetItemText($ListviewWPs, $line, $Add_Notes, $wp_column_Notes)
	If $Add_Latitude <> '' Then _GUICtrlListView_SetItemText($ListviewWPs, $line, $Add_Latitude, $wp_column_Latitude)
	If $Add_Longitude <> '' Then _GUICtrlListView_SetItemText($ListviewWPs, $line, $Add_Longitude, $wp_column_Longitude)
	If $Add_Bearing <> '' Then _GUICtrlListView_SetItemText($ListviewWPs, $line, $Add_Bearing, $wp_column_Bearing)
	If $Add_Distance <> '' Then _GUICtrlListView_SetItemText($ListviewWPs, $line, $Add_Distance, $wp_column_Distance)
	If $Add_Link <> '' Then _GUICtrlListView_SetItemText($ListviewWPs, $line, $Add_Link, $wp_column_Link)
	If $Add_Auth <> '' Then _GUICtrlListView_SetItemText($ListviewWPs, $line, $Add_Auth, $wp_column_Author)
	If $Add_Type <> '' Then _GUICtrlListView_SetItemText($ListviewWPs, $line, $Add_Type, $wp_column_Type)
	If $Add_Dif <> '' Then _GUICtrlListView_SetItemText($ListviewWPs, $line, $Add_Dif, $wp_column_Difficulty)
	If $Add_Ter <> '' Then _GUICtrlListView_SetItemText($ListviewWPs, $line, $Add_Ter, $wp_column_Terrain)
EndFunc   ;==>_ListViewAddWp

Func _SetListviewWidthsWp()
	;Set column widths - All variables have ' - 0' after them to make this work. it would not set column widths without the ' - 0'
	_GUICtrlListView_SetColumnWidth($ListviewWPs, $wp_column_Line - 0, $wp_column_Width_Line - 0)
	_GUICtrlListView_SetColumnWidth($ListviewWPs, $wp_column_Name - 0, $wp_column_Width_Name - 0)
	_GUICtrlListView_SetColumnWidth($ListviewWPs, $wp_column_Desc - 0, $wp_column_Width_Desc - 0)
	_GUICtrlListView_SetColumnWidth($ListviewWPs, $wp_column_Notes - 0, $wp_column_Width_Notes - 0)
	_GUICtrlListView_SetColumnWidth($ListviewWPs, $wp_column_Latitude - 0, $wp_column_Width_Latitude - 0)
	_GUICtrlListView_SetColumnWidth($ListviewWPs, $wp_column_Longitude - 0, $wp_column_Width_Longitude - 0)
	_GUICtrlListView_SetColumnWidth($ListviewWPs, $wp_column_Bearing - 0, $wp_column_Width_Bearing - 0)
	_GUICtrlListView_SetColumnWidth($ListviewWPs, $wp_column_Distance - 0, $wp_column_Width_Distance - 0)
	_GUICtrlListView_SetColumnWidth($ListviewWPs, $wp_column_Link - 0, $wp_column_Width_Link - 0)
	_GUICtrlListView_SetColumnWidth($ListviewWPs, $wp_column_Author - 0, $wp_column_Width_Author - 0)
	_GUICtrlListView_SetColumnWidth($ListviewWPs, $wp_column_Type - 0, $wp_column_Width_Type - 0)
	_GUICtrlListView_SetColumnWidth($ListviewWPs, $wp_column_Difficulty - 0, $wp_column_Width_Difficulty - 0)
	_GUICtrlListView_SetColumnWidth($ListviewWPs, $wp_column_Terrain - 0, $wp_column_Width_Terrain - 0)
EndFunc   ;==>_SetListviewWidthsWp

Func _GetListviewWidthsWp()
	$wp_column_Width_Line = _GUICtrlListView_GetColumnWidth($ListviewWPs, $wp_column_Line - 0)
	$wp_column_Width_Name = _GUICtrlListView_GetColumnWidth($ListviewWPs, $wp_column_Name - 0)
	$wp_column_Width_Desc = _GUICtrlListView_GetColumnWidth($ListviewWPs, $wp_column_Desc - 0)
	$wp_column_Width_Notes = _GUICtrlListView_GetColumnWidth($ListviewWPs, $wp_column_Notes - 0)
	$wp_column_Width_Latitude = _GUICtrlListView_GetColumnWidth($ListviewWPs, $wp_column_Latitude - 0)
	$wp_column_Width_Longitude = _GUICtrlListView_GetColumnWidth($ListviewWPs, $wp_column_Longitude - 0)
	$wp_column_Width_Bearing = _GUICtrlListView_GetColumnWidth($ListviewWPs, $wp_column_Bearing - 0)
	$wp_column_Width_Distance = _GUICtrlListView_GetColumnWidth($ListviewWPs, $wp_column_Distance - 0)
	$wp_column_Width_Link = _GUICtrlListView_GetColumnWidth($ListviewWPs, $wp_column_Link - 0)
	$wp_column_Width_Author = _GUICtrlListView_GetColumnWidth($ListviewWPs, $wp_column_Author - 0)
	$wp_column_Width_Type = _GUICtrlListView_GetColumnWidth($ListviewWPs, $wp_column_Type - 0)
	$wp_column_Width_Difficulty = _GUICtrlListView_GetColumnWidth($ListviewWPs, $wp_column_Difficulty - 0)
	$wp_column_Width_Terrain = _GUICtrlListView_GetColumnWidth($ListviewWPs, $wp_column_Terrain - 0)
EndFunc   ;==>_GetListviewWidthsWp

Func _HeaderSortWp($column);Sort a column in ap list
	If $Direction[$column] = 0 Then
		Dim $v_sort = False;set descending
	Else
		Dim $v_sort = True;set ascending
	EndIf
	If $Direction[$column] = 0 Then
		$Direction[$column] = 1
	Else
		$Direction[$column] = 0
	EndIf
	_GUICtrlListView_SimpleSort($ListviewWPs, $v_sort, $column)
	_FixLineNumbers()
	$SortColumn = -1
EndFunc   ;==>_HeaderSortWp

Func _SortColumnToggleWp(); Sets the ap list column header that was clicked
	$SortColumn = GUICtrlGetState($ListviewWPs)
EndFunc   ;==>_SortColumnToggleWp

Func _ListViewAddTrk($line, $Add_Line = '', $Add_Name = '', $Add_Desc = '', $Add_Comments = '', $Add_Source = '', $Add_Url = '', $Add_UrlName = '', $Add_Number = '')
	If $Add_Line <> '' Then _GUICtrlListView_SetItemText($ListviewTrk, $line, $Add_Line, $trk_column_Line)
	If $Add_Name <> '' Then _GUICtrlListView_SetItemText($ListviewTrk, $line, $Add_Name, $trk_column_Name)
	If $Add_Desc <> '' Then _GUICtrlListView_SetItemText($ListviewTrk, $line, $Add_Desc, $trk_column_Desc)
	If $Add_Comments <> '' Then _GUICtrlListView_SetItemText($ListviewTrk, $line, $Add_Comments, $trk_column_Comments)
	If $Add_Source <> '' Then _GUICtrlListView_SetItemText($ListviewTrk, $line, $Add_Source, $trk_column_Source)
	If $Add_Url <> '' Then _GUICtrlListView_SetItemText($ListviewTrk, $line, $Add_Url, $trk_column_Url)
	If $Add_UrlName <> '' Then _GUICtrlListView_SetItemText($ListviewTrk, $line, $Add_UrlName, $trk_column_UrlName)
	If $Add_Number <> '' Then _GUICtrlListView_SetItemText($ListviewTrk, $line, $Add_Number, $trk_column_Number)
EndFunc   ;==>_ListViewAddTrk

Func _SetListviewWidthsTrk()
	;Set column widths - All variables have ' - 0' after them to make this work. it would not set column widths without the ' - 0'
	_GUICtrlListView_SetColumnWidth($ListviewTrk, $trk_column_Line - 0, $trk_column_Width_Line - 0)
	_GUICtrlListView_SetColumnWidth($ListviewTrk, $trk_column_Name - 0, $trk_column_Width_Name - 0)
	_GUICtrlListView_SetColumnWidth($ListviewTrk, $trk_column_Desc - 0, $trk_column_Width_Desc - 0)
	_GUICtrlListView_SetColumnWidth($ListviewTrk, $trk_column_Comments - 0, $trk_column_Width_Comments - 0)
	_GUICtrlListView_SetColumnWidth($ListviewTrk, $trk_column_Source - 0, $trk_column_Width_Source - 0)
	_GUICtrlListView_SetColumnWidth($ListviewTrk, $trk_column_Url - 0, $trk_column_Width_Url - 0)
	_GUICtrlListView_SetColumnWidth($ListviewTrk, $trk_column_UrlName - 0, $trk_column_Width_UrlName - 0)
	_GUICtrlListView_SetColumnWidth($ListviewTrk, $trk_column_Number - 0, $trk_column_Width_Number - 0)
EndFunc   ;==>_SetListviewWidthsTrk

Func _GetListviewWidthsTrk()
	$trk_column_Width_Line = _GUICtrlListView_GetColumnWidth($ListviewTrk, $trk_column_Line - 0)
	$trk_column_Width_Name = _GUICtrlListView_GetColumnWidth($ListviewTrk, $trk_column_Name - 0)
	$trk_column_Width_Desc = _GUICtrlListView_GetColumnWidth($ListviewTrk, $trk_column_Desc - 0)
	$trk_column_Width_Comments = _GUICtrlListView_GetColumnWidth($ListviewTrk, $trk_column_Comments - 0)
	$trk_column_Width_Source = _GUICtrlListView_GetColumnWidth($ListviewTrk, $trk_column_Source - 0)
	$trk_column_Width_Url = _GUICtrlListView_GetColumnWidth($ListviewTrk, $trk_column_Url - 0)
	$trk_column_Width_UrlName = _GUICtrlListView_GetColumnWidth($ListviewTrk, $trk_column_UrlName - 0)
	$trk_column_Width_Number = _GUICtrlListView_GetColumnWidth($ListviewTrk, $trk_column_Number - 0)
EndFunc   ;==>_GetListviewWidthsTrk

Func _HeaderSortTrk($column);Sort a column in ap list
	If $Direction[$column] = 0 Then
		Dim $v_sort = False;set descending
	Else
		Dim $v_sort = True;set ascending
	EndIf
	If $Direction[$column] = 0 Then
		$Direction[$column] = 1
	Else
		$Direction[$column] = 0
	EndIf
	_GUICtrlListView_SimpleSort($ListviewTrk, $v_sort, $column)
	;_FixLineNumbers()
	$SortColumn = -1
EndFunc   ;==>_HeaderSortTrk

Func _SortColumnToggleTrk(); Sets the ap list column header that was clicked
	$SortColumn = GUICtrlGetState($ListviewTrk)
EndFunc   ;==>_SortColumnToggleTrk


;-------------------------------------------------------------------------------------------------------------------------------
;MENU FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------

Func _NewSession()
	Run(@ScriptDir & "\Mysticache.exe")
EndFunc   ;==>_NewSession

Func _AddWpPosToggle()
	If $AddDirection = 0 Then
		GUICtrlSetState($But_AddWaypointsToTop, $GUI_UNCHECKED)
		$AddDirection = -1
	Else
		GUICtrlSetState($But_AddWaypointsToTop, $GUI_CHECKED)
		$AddDirection = 0
	EndIf
EndFunc   ;==>_AddWpPosToggle

Func _OpenWptLink()
	$Selected = _GUICtrlListView_GetNextItem($ListviewWPs); find what WP is selected in the list. returns -1 is nothing is selected
	If $Selected <> -1 Then
		;Get WPID and ListRow
		$query = "SELECT Link FROM WP WHERE ListRow='" & $Selected & "'"
		$WpMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
		$WPLink = $WpMatchArray[1][1]
		If $WPLink <> '' Then
			Run("RunDll32.exe url.dll,FileProtocolHandler " & $WPLink)
		Else
			MsgBox(0, "Error", "This waypoint has no link")
		EndIf
	Else
		MsgBox(0, "Error", "No waypoint selected")
	EndIf
EndFunc   ;==>_OpenWptLink

Func _ClearAll();Clear all WPs
	$ClearAllWps = 1
EndFunc   ;==>_ClearAll

Func _ClearAllWp()
	;Reset Variables
	$WPID = 0
	$TRACKID = 0
	$TRACKSEGID = 0
	;Clear DB
	$query = "DELETE * FROM WP"
	_ExecuteMDB($MysticacheDB, $DB_OBJ, $query)
	$query = "DELETE * FROM TRACK"
	_ExecuteMDB($MysticacheDB, $DB_OBJ, $query)
	$query = "DELETE * FROM TRACKSEG"
	_ExecuteMDB($MysticacheDB, $DB_OBJ, $query)
	;Create Default GPS Track
	_AddRecord($MysticacheDB, "TRACK", $DB_OBJ, '0|0|' & StringFormat("%04i", @YEAR) & '-' & StringFormat("%02i", @MON) & '-' & StringFormat("%02i", @MDAY) & ' ' & @HOUR & ':' & @MIN & ':' & @SEC & '|||' & $Script_Name & '|||')
	;Recreate Listview
	_GetListviewWidthsWp()
	GUICtrlDelete($ListviewWPs)
	$ListviewWPs = GUICtrlCreateListView($wp_headers, 2, 70, 978, 602, $LVS_REPORT + $LVS_SINGLESEL, $LVS_EX_HEADERDRAGDROP + $LVS_EX_GRIDLINES + $LVS_EX_FULLROWSELECT)
	GUICtrlSetBkColor(-1, $ControlBackgroundColor)
	_SetListviewWidthsWp()
	;GUICtrlSetOnEvent($ListviewWPs, '_SortColumnToggleWp')
	$Redraw = 1
	_SetControlSizes()
	$ClearAllWps = 0
EndFunc   ;==>_ClearAllWp

Func _AddToMysticacheDB()
	$dbfile = $SaveDir & $ldatetimestamp & '.GPX'
	FileDelete($dbfile)
	If _SaveGPX($dbfile, 0, 1) = 1 Then
		$url_root = $PhilsWdbURL & 'login.php?return=/wifidb/cp/?func%3Dboeyes%26boeye_func%3Dimport_gpx%26'
		$url_data = "file%3D" & $dbfile
		Run("RunDll32.exe url.dll,FileProtocolHandler " & $url_root & $url_data);open url with rundll 32
	EndIf
EndFunc   ;==>_AddToMysticacheDB

Func _SaveGpsHistoryToggle()
	If $SaveGpsHistory = 1 Then
		$SaveGpsHistory = 0
		GUICtrlSetState($But_SaveGpsHistory, $GUI_UNCHECKED)
	Else
		$SaveGpsHistory = 1
		GUICtrlSetState($But_SaveGpsHistory, $GUI_CHECKED)
	EndIf
EndFunc   ;==>_SaveGpsHistoryToggle

Func _ToggleTrackView()
	$VMode = 2
	GUICtrlSetState($ViewTrack, $GUI_CHECKED)
	GUICtrlSetState($ViewWaypoints, $GUI_UNCHECKED)
	;Hide waypoint gui items
	GUICtrlSetState($AddWpButton, $GUI_HIDE)
	GUICtrlSetState($EditWpButton, $GUI_HIDE)
	GUICtrlSetState($DelWpButton, $GUI_HIDE)
	GUICtrlSetState($SetDestButton, $GUI_HIDE)
	GUICtrlSetState($ListviewWPs, $GUI_HIDE)
	;Show track gui items
	GUICtrlSetState($AddTrkButton, $GUI_SHOW)
	GUICtrlSetState($EditTrkButton, $GUI_SHOW)
	GUICtrlSetState($DelTrkButton, $GUI_SHOW)
	GUICtrlSetState($ListviewTrk, $GUI_SHOW)
EndFunc   ;==>_ToggleTrackView

Func _ToggleWaypointView()
	$VMode = 1
	GUICtrlSetState($ViewWaypoints, $GUI_CHECKED)
	GUICtrlSetState($ViewTrack, $GUI_UNCHECKED)
	;Show waypoint gui items
	GUICtrlSetState($AddWpButton, $GUI_SHOW)
	GUICtrlSetState($EditWpButton, $GUI_SHOW)
	GUICtrlSetState($DelWpButton, $GUI_SHOW)
	GUICtrlSetState($SetDestButton, $GUI_SHOW)
	GUICtrlSetState($ListviewWPs, $GUI_SHOW)
	;Hide track gui items
	GUICtrlSetState($AddTrkButton, $GUI_HIDE)
	GUICtrlSetState($EditTrkButton, $GUI_HIDE)
	GUICtrlSetState($DelTrkButton, $GUI_HIDE)
	GUICtrlSetState($ListviewTrk, $GUI_HIDE)
EndFunc   ;==>_ToggleWaypointView

;-------------------------------------------------------------------------------------------------------------------------------
;BUTTON FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------

Func _SetDestination()
	$Selected = _GUICtrlListView_GetNextItem($ListviewWPs); find what AP is selected in the list. returns -1 is nothing is selected
	If $Selected <> -1 Then ;If a access point is selected in the listview, play its signal strenth
		$query = "SELECT Latitude, Longitude FROM WP WHERE ListRow='" & $Selected & "'"
		$WpMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
		$DestLat = $WpMatchArray[1][1]
		$DestLon = $WpMatchArray[1][2]
		$DestSet = 1
		GUICtrlSetData($Lab_DestGPS, 'Dest GPS:     Latitude: ' & _GpsFormat($DestLat) & '     Longitude: ' & _GpsFormat($DestLon))
	Else
		MsgBox(0, "Error", "No waypoint selected")
	EndIf
	GUICtrlSetState($ListviewWPs, $GUI_FOCUS)
EndFunc   ;==>_SetDestination

Func _AddWaypointGUI()
	If $AddWaypoingGuiOpen = 0 Then
		$AddWaypoingGuiOpen = 1

		$AddWaypoingGui = GUICreate("Add Waypoint", 502, 373)
		GUISetBkColor($BackgroundColor)
		GUICtrlCreateGroup("Waypoint Details", 10, 8, 481, 217)
		GUICtrlCreateLabel("Name:", 20, 31, 55, 17)
		$GUI_AddName = GUICtrlCreateInput("", 80, 29, 401, 21)
		GUICtrlCreateLabel("GC #:", 20, 63, 55, 17)
		$GUI_AddDesc = GUICtrlCreateInput("", 80, 61, 401, 21)
		GUICtrlCreateLabel("Notes:", 20, 95, 55, 17)
		$GUI_AddNotes = GUICtrlCreateInput("", 80, 93, 401, 21)
		GUICtrlCreateLabel("Author:", 20, 128, 55, 17)
		$GUI_AddAuthor = GUICtrlCreateInput("", 80, 126, 401, 21)
		GUICtrlCreateLabel("Link:", 20, 160, 55, 17)
		$GUI_AddLink = GUICtrlCreateInput("", 80, 158, 401, 21)
		GUICtrlCreateLabel("Type:", 20, 193, 55, 17)
		$GUI_AddType = GUICtrlCreateInput("", 80, 191, 165, 21)
		GUICtrlCreateLabel("Difficulty:", 265, 193, 50, 17)
		$GUI_AddDifficulty = GUICtrlCreateInput("", 320, 191, 50, 21)
		GUICtrlCreateLabel("Terrain:", 385, 194, 40, 17)
		$GUI_AddTerrain = GUICtrlCreateInput("", 430, 192, 50, 21)
		GUICtrlCreateGroup("Waypoint Location", 8, 232, 481, 97)
		$Rad_DestGPS_LatLon = GUICtrlCreateRadio("", 18, 260, 17, 17)
		If $RadDestGPSLatLon = 1 Then GUICtrlSetState($Rad_DestGPS_LatLon, $GUI_CHECKED)
		GUICtrlCreateLabel("Latitude:", 40, 261, 45, 17)
		$dLat = GUICtrlCreateInput("", 98, 257, 153, 21)
		GUICtrlCreateLabel("Longitude:", 264, 261, 54, 17)
		$dLon = GUICtrlCreateInput("", 328, 257, 153, 21)
		$Rad_DestGPS_BrngDist = GUICtrlCreateRadio("", 17, 293, 17, 17)
		If $RadDestGPSBrngDist = 1 Then GUICtrlSetState($Rad_DestGPS_BrngDist, $GUI_CHECKED)
		GUICtrlCreateLabel("Bearing:", 39, 294, 43, 17)
		$dBrng = GUICtrlCreateInput("", 97, 290, 153, 21)
		GUICtrlCreateLabel("Distance:", 263, 294, 49, 17)
		$dDist = GUICtrlCreateInput("", 327, 290, 153, 21)
		$But_AddWapoint = GUICtrlCreateButton("Add Waypoint", 96, 336, 129, 25, $WS_GROUP)
		$But_Cancel = GUICtrlCreateButton("Cancel", 272, 338, 129, 25, $WS_GROUP)

		GUISetState(@SW_SHOW)
		GUICtrlSetOnEvent($But_AddWapoint, '_AddWaypoint')
		GUICtrlSetOnEvent($But_Cancel, '_CloseAddWaypointGUI')
	EndIf
EndFunc   ;==>_AddWaypointGUI

Func _AddWaypoint()
	$WPName = GUICtrlRead($GUI_AddName)
	$WPDesc = GUICtrlRead($GUI_AddDesc)
	$WPNotes = GUICtrlRead($GUI_AddNotes)
	$WPLink = GUICtrlRead($GUI_AddLink)
	$WPAuth = GUICtrlRead($GUI_AddAuthor)
	$WPType = GUICtrlRead($GUI_AddType)
	$WPDif = GUICtrlRead($GUI_AddDifficulty)
	$WPTer = GUICtrlRead($GUI_AddTerrain)
	$WPBrng = GUICtrlRead($dBrng)
	$WPDist = GUICtrlRead($dDist)
	$WPLat = GUICtrlRead($dLat)
	$WPLon = GUICtrlRead($dLon)


	If GUICtrlRead($Rad_DestGPS_LatLon) = 1 And BitAND($WPLat <> "", $WPLon <> "") Then
		$DestLat = _Format_GPS_All_to_DMM($WPLat, "N", "S")
		$DestLon = _Format_GPS_All_to_DMM($WPLon, "E", "W")
		$RadDestGPSLatLon = 1
		$RadDestGPSBrngDist = 4
	ElseIf GUICtrlRead($Rad_DestGPS_BrngDist) = 1 And BitAND($WPBrng <> "", $WPDist <> "") Then
		$DestLat = _DestLat($StartLat, $WPBrng, $WPDist)
		$DestLon = _DestLon($StartLat, $StartLon, $DestLat, $WPBrng, $WPDist)
		$RadDestGPSLatLon = 4
		$RadDestGPSBrngDist = 1
	Else
		$DestLat = 'N 0.0000'
		$DestLon = 'E 0.0000'
	EndIf
	$DestBrng = StringFormat('%0.1f', _BearingBetweenPoints($StartLat, $StartLon, $DestLat, $DestLon))
	$DestDist = StringFormat('%0.1f', _DistanceBetweenPoints($StartLat, $StartLon, $DestLat, $DestLon))
	$query = "SELECT TOP 1 WPID FROM WP WHERE Name = '" & StringReplace($WPName, "'", "''") & "' And Desc1 = '" & StringReplace($WPDesc, "'", "''") & "' And Latitude = '" & $DestLat & "' And Longitude = '" & $DestLon & "'"
	$WpMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
	$FoundWpMatch = UBound($WpMatchArray) - 1
	If $FoundWpMatch = 0 Then ;If WP is not found then add it
		$WPID += 1
		;Add APs to top of list
		If $AddDirection = 0 Then
			$query = "UPDATE WP SET ListRow = ListRow + 1 WHERE ListRow <> '-1'"
			_ExecuteMDB($MysticacheDB, $DB_OBJ, $query)
			$DBAddPos = 0
		Else ;Add to bottom
			$DBAddPos = -1
		EndIf
		;Add Into ListView
		$ListRow = _GUICtrlListView_InsertItem($ListviewWPs, $WPID, $DBAddPos)
		_ListViewAddWp($ListRow, $WPID, $WPName, $WPDesc, $WPNotes, _GpsFormat($DestLat), _GpsFormat($DestLon), $DestBrng, $DestDist, $WPLink, $WPAuth, $WPType, $WPDif, $WPTer)
		_AddRecord($MysticacheDB, "WP", $DB_OBJ, $WPID & '|' & $ListRow & '|' & $WPName & '|' & $WPDesc & '|' & $WPNotes & '|' & $DestLat & '|' & $DestLon & '|' & $DestBrng & '|' & $DestDist & '|' & $WPLink & '|' & $WPAuth & '|' & $WPType & '|' & $WPDif & '|' & $WPTer)

		_CloseAddWaypointGUI()
	Else
		MsgBox(0, "Error", "This waypoint already exists")
	EndIf

EndFunc   ;==>_AddWaypoint

Func _CloseAddWaypointGUI()
	GUIDelete($AddWaypoingGui)
	$AddWaypoingGuiOpen = 0
	GUICtrlSetState($ListviewWPs, $GUI_FOCUS)
EndFunc   ;==>_CloseAddWaypointGUI

Func _EditWaypointGUI()
	If $EditWaypoingGuiOpen = 0 Then
		$Selected = _GUICtrlListView_GetNextItem($ListviewWPs); find what AP is selected in the list. returns -1 is nothing is selected
		If $Selected <> -1 Then ;If a access point is selected in the listview, play its signal strenth
			$query = "SELECT WPID, ListRow, Name, Desc1, Notes, Latitude, Longitude, Bearing, Distance, Link, Type, Difficulty, Terrain, Author FROM WP WHERE ListRow='" & $Selected & "'"
			$WpMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
			$DB_WPID = $WpMatchArray[1][1]
			$DB_ListRow = $WpMatchArray[1][2]
			$DB_Name = $WpMatchArray[1][3]
			$DB_Desc = $WpMatchArray[1][4]
			$DB_Notes = $WpMatchArray[1][5]
			$DB_Latitude = _GpsFormat($WpMatchArray[1][6])
			$DB_Longitude = _GpsFormat($WpMatchArray[1][7])
			$DB_Bearing = $WpMatchArray[1][8]
			$DB_Distance = $WpMatchArray[1][9]
			$DB_Link = $WpMatchArray[1][10]
			$DB_Type = $WpMatchArray[1][11]
			$DB_Difficulty = $WpMatchArray[1][12]
			$DB_Terrain = $WpMatchArray[1][13]
			$DB_Author = $WpMatchArray[1][14]
			$dWPID = $DB_WPID
			$dListRow = $DB_ListRow
			$EditWaypoingGuiOpen = 1



			$EditWaypoingGui = GUICreate("Edit Waypoint", 502, 373)
			GUISetBkColor($BackgroundColor)
			GUICtrlCreateGroup("Waypoint Details", 10, 8, 481, 217)
			GUICtrlCreateLabel("Name:", 20, 31, 55, 17)
			$GUI_AddName = GUICtrlCreateInput($DB_Name, 80, 29, 401, 21)
			GUICtrlCreateLabel("Desc:", 20, 63, 55, 17)
			$GUI_AddDesc = GUICtrlCreateInput($DB_Desc, 80, 61, 401, 21)
			GUICtrlCreateLabel("Notes:", 20, 95, 55, 17)
			$GUI_AddNotes = GUICtrlCreateInput($DB_Notes, 80, 93, 401, 21)
			GUICtrlCreateLabel("Author:", 20, 128, 55, 17)
			$GUI_AddAuthor = GUICtrlCreateInput($DB_Author, 80, 126, 401, 21)
			GUICtrlCreateLabel("Link:", 20, 160, 55, 17)
			$GUI_AddLink = GUICtrlCreateInput($DB_Link, 80, 158, 401, 21)
			GUICtrlCreateLabel("Type:", 20, 193, 55, 17)
			$GUI_AddType = GUICtrlCreateInput($DB_Type, 80, 191, 165, 21)
			GUICtrlCreateLabel("Difficulty:", 265, 193, 50, 17)
			$GUI_AddDifficulty = GUICtrlCreateInput($DB_Difficulty, 320, 191, 50, 21)
			GUICtrlCreateLabel("Terrain:", 385, 194, 40, 17)
			$GUI_AddTerrain = GUICtrlCreateInput($DB_Terrain, 430, 192, 50, 21)
			GUICtrlCreateGroup("Waypoint Location", 8, 232, 481, 97)
			$Rad_DestGPS_LatLon = GUICtrlCreateRadio("", 18, 260, 17, 17)
			If $RadEditDestGPSLatLon = 1 Then GUICtrlSetState($Rad_DestGPS_LatLon, $GUI_CHECKED)
			GUICtrlCreateLabel("Latitude:", 40, 261, 45, 17)
			$dLat = GUICtrlCreateInput($DB_Latitude, 98, 257, 153, 21)
			GUICtrlCreateLabel("Longitude:", 264, 261, 54, 17)
			$dLon = GUICtrlCreateInput($DB_Longitude, 328, 257, 153, 21)
			$Rad_DestGPS_BrngDist = GUICtrlCreateRadio("", 17, 293, 17, 17)
			If $RadEditDestGPSBrngDist = 1 Then GUICtrlSetState($Rad_DestGPS_BrngDist, $GUI_CHECKED)
			GUICtrlCreateLabel("Bearing:", 39, 294, 43, 17)
			$dBrng = GUICtrlCreateInput($DB_Bearing, 97, 290, 153, 21)
			GUICtrlCreateLabel("Distance:", 263, 294, 49, 17)
			$dDist = GUICtrlCreateInput($DB_Distance, 327, 290, 153, 21)
			$But_AddWapoint = GUICtrlCreateButton("Edit Waypoint", 96, 336, 129, 25, $WS_GROUP)
			$But_Cancel = GUICtrlCreateButton("Cancel", 272, 338, 129, 25, $WS_GROUP)
			GUISetState(@SW_SHOW)
			GUICtrlSetOnEvent($But_AddWapoint, '_EditWaypoint')
			GUICtrlSetOnEvent($But_Cancel, '_CloseEditWaypointGUI')
		Else
			MsgBox(0, "Error", "No waypoint selected")
		EndIf
	EndIf
EndFunc   ;==>_EditWaypointGUI

Func _CloseEditWaypointGUI()
	GUIDelete($EditWaypoingGui)
	$EditWaypoingGuiOpen = 0
	GUICtrlSetState($ListviewWPs, $GUI_FOCUS)
EndFunc   ;==>_CloseEditWaypointGUI

Func _EditWaypoint()
	$WPWPID = $dWPID
	$WPListrow = $dListRow
	$WPName = GUICtrlRead($GUI_AddName)
	$WPDesc = GUICtrlRead($GUI_AddDesc)
	$WPNotes = GUICtrlRead($GUI_AddNotes)
	$WPLink = GUICtrlRead($GUI_AddLink)
	$WPAuth = GUICtrlRead($GUI_AddAuthor)
	$WPType = GUICtrlRead($GUI_AddType)
	$WPDif = GUICtrlRead($GUI_AddDifficulty)
	$WPTer = GUICtrlRead($GUI_AddTerrain)
	$WPBrng = GUICtrlRead($dBrng)
	$WPDist = GUICtrlRead($dDist)
	$WPLat = GUICtrlRead($dLat)
	$WPLon = GUICtrlRead($dLon)

	If GUICtrlRead($Rad_DestGPS_LatLon) = 1 And BitAND($WPLat <> "", $WPLon <> "") Then
		$DestLat = _Format_GPS_All_to_DMM($WPLat, "N", "S")
		$DestLon = _Format_GPS_All_to_DMM($WPLon, "E", "W")
		$RadEditDestGPSLatLon = 1
		$RadEditDestGPSBrngDist = 4
	ElseIf GUICtrlRead($Rad_DestGPS_BrngDist) = 1 And BitAND($WPBrng <> "", $WPDist <> "") Then
		$DestLat = _DestLat($StartLat, $WPBrng, $WPDist)
		$DestLon = _DestLon($StartLat, $StartLon, $DestLat, $WPBrng, $WPDist)
		$RadEditDestGPSLatLon = 4
		$RadEditDestGPSBrngDist = 1
	Else
		$DestLat = 'N 0.0000'
		$DestLon = 'E 0.0000'
	EndIf
	$DestBrng = StringFormat('%0.1f', _BearingBetweenPoints($StartLat, $StartLon, $DestLat, $DestLon))
	$DestDist = StringFormat('%0.1f', _DistanceBetweenPoints($StartLat, $StartLon, $DestLat, $DestLon))

	_ListViewAddWp($WPListrow, $WPWPID, $WPName, $WPDesc, $WPNotes, _GpsFormat($DestLat), _GpsFormat($DestLon), $DestBrng, $DestDist, $WPLink, $WPAuth, $WPType, $WPDif, $WPTer)
	$query = "UPDATE WP SET Name = '" & StringReplace($WPName, "'", "''") & "', Desc1 = '" & StringReplace($WPDesc, "'", "''") & "', Notes = '" & StringReplace($WPNotes, "'", "''") & "', Latitude = '" & $DestLat & "', Longitude = '" & $DestLon & "', Bearing = '" & $DestBrng & "', Distance = '" & $DestDist & "' WHERE WPID = '" & $WPWPID & "'"
	_ExecuteMDB($MysticacheDB, $DB_OBJ, $query)

	_CloseEditWaypointGUI()
EndFunc   ;==>_EditWaypoint

Func _DeleteWaypoint()
	$Selected = _GUICtrlListView_GetNextItem($ListviewWPs); find what WP is selected in the list. returns -1 is nothing is selected
	If $Selected <> -1 Then
		;Get WPID and ListRow
		$query = "SELECT WPID, ListRow FROM WP WHERE ListRow='" & $Selected & "'"
		$WpMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
		$DelWPID = $WpMatchArray[1][1]
		$DelListRow = $WpMatchArray[1][2]
		;Delete Waypoint from Listview
		_GUICtrlListView_DeleteItem(GUICtrlGetHandle($ListviewWPs), $DelListRow)
		;Delete Waypoint from DB
		$query = "DELETE FROM WP WHERE WPID='" & $DelWPID & "'"
		_ExecuteMDB($MysticacheDB, $DB_OBJ, $query)
		;Decrease WPID count
		$WPID -= 1
		;Update WPID and Listrow in DB of all other APs
		$query = "SELECT WPID, ListRow FROM WP"
		$WpMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
		$FoundWpMatch = UBound($WpMatchArray) - 1
		If $FoundWpMatch <> 0 Then
			For $du = 1 To $FoundWpMatch
				$WPWPID = $WpMatchArray[$du][1]
				$WPListrow = $WpMatchArray[$du][2]
				ConsoleWrite('Listrow - ' & $WPListrow & '>' & $DelListRow & @CRLF)
				If StringFormat("%09i", $WPListrow) > StringFormat("%09i", $DelListRow) Then
					$NewListrow = $WPListrow - 1
					$query = "UPDATE WP SET Listrow = '" & $NewListrow & "' WHERE WPID='" & $WPWPID & "'"
					_ExecuteMDB($MysticacheDB, $DB_OBJ, $query)
					$WPListrow = $NewListrow
				EndIf
				ConsoleWrite('WPID - ' & $WPWPID & '>' & $DelWPID & @CRLF)
				If StringFormat("%09i", $WPWPID) > StringFormat("%09i", $DelWPID) Then
					$NewWPID = $WPWPID - 1
					$query = "UPDATE WP SET WPID='" & $NewWPID & "' WHERE WPID='" & $WPWPID & "'"
					_ExecuteMDB($MysticacheDB, $DB_OBJ, $query)
					$WPWPID = $NewWPID
				EndIf
				_ListViewAddWp($WPListrow, $WPWPID, '', '', '', '', '', '', '', '', '', '', '', '')
			Next
		EndIf
	Else
		MsgBox(0, "Error", "No waypoint selected")
	EndIf
EndFunc   ;==>_DeleteWaypoint

Func _GetCurrentGps()
	GUICtrlSetData($cLat, _GpsFormat($Latitude))
	GUICtrlSetData($cLon, _GpsFormat($Longitude))
EndFunc   ;==>_GetCurrentGps

;-------------------------------------------------------------------------------------------------------------------------------
;DATE/TIME FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------

Func _DateTimeUtcConvert($Date, $time, $ConvertToUTC)
	Local $mon, $d, $y, $h, $m, $s, $ms
	$DateSplit = StringSplit($Date, '-')
	$TimeSplit = StringSplit($time, ':')
	If $DateSplit[0] = 3 And $TimeSplit[0] = 3 Then
		If StringInStr($TimeSplit[3], '.') Then
			$SecMsSplit = StringSplit($TimeSplit[3], '.')
			$s = $SecMsSplit[1]
			$ms = $SecMsSplit[2]
		Else
			$s = $TimeSplit[3]
			$ms = '000'
		EndIf
		$tSystem = _Date_Time_EncodeSystemTime($DateSplit[2], $DateSplit[3], $DateSplit[1], $TimeSplit[1], $TimeSplit[2], $s)
		If $ConvertToUTC = 1 Then
			$rTime = _Date_Time_TzSpecificLocalTimeToSystemTime(DllStructGetPtr($tSystem))
		Else
			$rTime = _Date_Time_SystemTimeToTzSpecificLocalTime(DllStructGetPtr($tSystem))
		EndIf
		$dts1 = StringSplit(_Date_Time_SystemTimeToDateTimeStr($rTime), ' ')
		$dts2 = StringSplit($dts1[1], '/')
		$dts3 = StringSplit($dts1[2], ':')
		$mon = $dts2[1]
		$d = $dts2[2]
		$y = $dts2[3]
		$h = $dts3[1]
		$m = $dts3[2]
		$s = $dts3[3]
		Return ($y & '-' & $mon & '-' & $d & ' ' & $h & ':' & $m & ':' & $s & '.' & $ms)
	Else
		Return ('0000-00-00 00:00:00.000')
	EndIf
EndFunc   ;==>_DateTimeUtcConvert

Func _DateTimeLocalFormat($DateTimeString)
	$dta = StringSplit($DateTimeString, ' ')
	$ds = _DateLocalFormat($dta[1])
	Return ($ds & ' ' & $dta[2])
EndFunc   ;==>_DateTimeLocalFormat

Func _DateLocalFormat($DateString)
	If StringInStr($DateString, '/') Then
		$da = StringSplit($DateString, '/')
		$y = $da[1]
		$m = $da[2]
		$d = $da[3]
		Return (StringReplace(StringReplace(StringReplace($DateFormat, 'M', $m), 'd', $d), 'yyyy', $y))
	ElseIf StringInStr($DateString, '-') Then
		$da = StringSplit($DateString, '-')
		$y = $da[1]
		$m = $da[2]
		$d = $da[3]
		Return (StringReplace(StringReplace(StringReplace(StringReplace($DateFormat, 'M', $m), 'd', $d), 'yyyy', $y), '/', '-'))
	EndIf
EndFunc   ;==>_DateLocalFormat

;-------------------------------------------------------------------------------------------------------------------------------
;GPS FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------

Func _GpsToggle();Turns GPS on or off
	If $UseGPS = 1 Then
		$TurnOffGPS = 1
	Else
		$openport = _OpenComPort($ComPort, $BAUD, $PARITY, $DATABIT, $STOPBIT);Open The GPS COM port
		If $openport = 1 Then
			$UseGPS = 1
			GUICtrlSetData($But_UseGPS, "Stop GPS")
			$GPGGA_Update = TimerInit()
			$GPRMC_Update = TimerInit()
			;GUICtrlSetData($Lab_GpsInfo, "Succesfully Opened GPS")
		Else
			$UseGPS = 0
			;GUICtrlSetData($Lab_GpsInfo, "Error Opening GPS")
			SoundPlay($SoundDir & $ErrorFlag_sound, 0)
		EndIf
	EndIf
EndFunc   ;==>_GpsToggle

Func _TurnOffGPS();Turns off GPS, resets variable\
	$UseGPS = 0
	$TurnOffGPS = 0
	$disconnected_time = -1
	$Latitude = 'N 0.0000'
	$Longitude = 'E 0.0000'
	$Latitude2 = 'N 0.0000'
	$Longitude2 = 'E 0.0000'
	$NumberOfSatalites = '00'
	$HorDilPitch = '0'
	$Alt = '0'
	$AltS = 'M'
	$Geo = '0'
	$GeoS = 'M'
	$SpeedInKnots = '0'
	$SpeedInMPH = '0'
	$SpeedInKmH = '0'
	$TrackAngle = '0'

	_CloseComPort($ComPort) ;Close The GPS COM port
	GUICtrlSetData($But_UseGPS, "Use GPS")
	;GUICtrlSetData($Lab_GpsInfo, "")
EndFunc   ;==>_TurnOffGPS

Func _OpenComPort($CommPort = '8', $sBAUD = '4800', $sPARITY = 'N', $sDataBit = '8', $sStopBit = '1', $sFlow = '0');Open specified COM port
	If $GpsType = 0 Then
		If $sPARITY = 'O' Then ;Odd
			$iPar = '1'
		ElseIf $sPARITY = 'E' Then ;Even
			$iPar = '2'
		ElseIf $sPARITY = 'M' Then ;Mark
			$iPar = '3'
		ElseIf $sPARITY = 'S' Then ;Space
			$iPar = '4'
		Else
			$iPar = '0';None
		EndIf
		$OpenedPort = _CommSetPort($CommPort, $sErr, $sBAUD, $sDataBit, $iPar, $sStopBit, $sFlow)
		If $OpenedPort = 1 Then
			Return (1)
		Else
			Return (0)
		EndIf
	ElseIf $GpsType = 1 Then
		$return = 0
		$ComError = 0
		$CommSettings = $sBAUD & ',' & $sPARITY & ',' & $sDataBit & ',' & $sStopBit
		;	Create NETComm.ocx object
		$NetComm = ObjCreate("NETCommOCX.NETComm")
		If IsObj($NetComm) = 0 Then ;If $NetComm is not an object then netcomm ocx is probrably not installed
			MsgBox(0, "Error", "Install Netcomm OCX (http://home.comcast.net/~hardandsoftware/NETCommOCX.htm)")
		Else
			$NetComm.CommPort = $CommPort ;Set port number
			$NetComm.Settings = $CommSettings ;Set port settings
			$NetComm.InputLen = 0 ;reads entire buffer
			If $ComError <> 1 Then
				$NetComm.InputMode = 0 ;reads in text mode
				$NetComm.HandShaking = 3 ;uses both RTS and Xon/Xoff handshaking
				$NetComm.PortOpen = "True"
				$return = 1
			EndIf
		EndIf
		Return ($return)
	ElseIf $GpsType = 2 Then
		If $sPARITY = 'O' Then ;Odd
			$iPar = '1'
		ElseIf $sPARITY = 'E' Then ;Even
			$iPar = '2'
		ElseIf $sPARITY = 'M' Then ;Mark
			$iPar = '3'
		ElseIf $sPARITY = 'S' Then ;Space
			$iPar = '4'
		Else
			$iPar = '0';None
		EndIf
		If $sStopBit = '1' Then
			$iStop = '0'
		ElseIf $sStopBit = '1.5' Then
			$iStop = '1'
		ElseIf $sStopBit = '2' Then
			$iStop = '2'
		EndIf
		$OpenedPort = _OpenComm($CommPort, $sBAUD, $sDataBit, $iPar, $iStop)
		If $OpenedPort = '-1' Then
			Return (0)
		Else
			Return (1)
		EndIf
	EndIf
EndFunc   ;==>_OpenComPort

Func _CloseComPort($CommPort = '8');Closes specified COM port
	;Close the COM Port
	If $GpsType = 0 Then
		_CommClosePort()
	ElseIf $GpsType = 1 Then
		With $NetComm
			.CommPort = $CommPort ;Set port number
			.PortOpen = "False"
		EndWith
	ElseIf $GpsType = 2 Then
		_CloseComm($OpenedPort)
	EndIf
EndFunc   ;==>_CloseComPort

Func _GetGPS(); Recieves data from gps device
	$timeout = TimerInit()
	$return = 1
	$FoundData = 0

	$maxtime = $RefreshLoopTime * 0.8; Set GPS timeout to 80% of the given timout time
	If $maxtime < 800 Then $maxtime = 800;Set GPS timeout to 800 if it is under that

	Dim $Temp_FixTime, $Temp_FixTime2, $Temp_FixDate, $Temp_Lat, $Temp_Lon, $Temp_Lat2, $Temp_Lon2, $Temp_Quality, $Temp_NumberOfSatalites, $Temp_HorDilPitch, $Temp_Alt, $Temp_AltS, $Temp_Geo, $Temp_GeoS, $Temp_Status, $Temp_SpeedInKnots, $Temp_SpeedInMPH, $Temp_SpeedInKmH, $Temp_TrackAngle
	Dim $Temp_Quality = 0, $Temp_Status = "V"

	While 1 ;Loop to extract gps data untill location is found or timout time is reached
		If $UseGPS = 0 Then ExitLoop
		If $GpsType = 0 Then ;Use CommMG
			$dataline = StringStripWS(_CommGetLine(@CR, 500, $maxtime), 8);Read data line from GPS
			If $GpsDetailsOpen = 1 Then GUICtrlSetData($GpsCurrentDataGUI, $dataline);Show data line in "GPS Details" GUI if it is open
			If StringInStr($dataline, '$') And StringInStr($dataline, '*') Then ;Check if string containts start character ($) and checsum character (*). If it does not have them, ignore the data
				$FoundData = 1
				If StringInStr($dataline, "$GPGGA") Then
					_GPGGA($dataline);Split GPGGA data from data string
					$disconnected_time = -1
				ElseIf StringInStr($dataline, "$GPRMC") Then
					_GPRMC($dataline);Split GPRMC data from data string
					$disconnected_time = -1
				EndIf
			EndIf
		ElseIf $GpsType = 1 Then ;Use Netcomm ocx to get data (more stable right now)
			If $NetComm.InBufferCount Then
				$Buffer = $NetComm.InBufferCount
				If $Buffer > 85 And TimerDiff($timeout) < $maxtime Then
					$inputdata = $NetComm.inputdata
					If StringInStr($inputdata, '$') And StringInStr($inputdata, '*') Then ;Check if string containts start character ($) and checsum character (*). If it does not have them, ignore the data
						$FoundData = 1
						$gps = StringSplit($inputdata, @CR);Split data string by CR and put data into the $gps array
						For $readloop = 1 To $gps[0];go through array
							$gpsline = StringStripWS($gps[$readloop], 3)
							If $GpsDetailsOpen = 1 Then GUICtrlSetData($GpsCurrentDataGUI, $gpsline);Show data line in "GPS Details" GUI if it is open
							If StringInStr($gpsline, '$') And StringInStr($gpsline, '*') Then ;Check if string containts start character ($) and checsum character (*). If it does not have them, ignore the data
								If StringInStr($gpsline, "$GPGGA") Then
									_GPGGA($gpsline);Split GPGGA data from data string
								ElseIf StringInStr($gpsline, "$GPRMC") Then
									_GPRMC($gpsline);Split GPRMC data from data string
								EndIf
							EndIf
							If BitOR($Temp_Quality = 1, $Temp_Quality = 2) = 1 And BitOR($Temp_Status = "A", $GpsDetailsOpen <> 1) Then ExitLoop;If $Temp_Quality = 1 (GPS has a fix) And, If the details window is open, $Temp_Status = "A" (Active data, not Void)
							If TimerDiff($timeout) > $maxtime Then ExitLoop;If time is over timeout period, exitloop
						Next
					EndIf
				EndIf
			EndIf
		ElseIf $GpsType = 2 Then ;Use Kernel32
			$gstring = StringStripWS(_rxwait($OpenedPort, '1000', $maxtime), 8);Read data line from GPS
			$dataline = $gstring; & $LastGpsString
			$LastGpsString = $gstring
			If StringInStr($dataline, '$') And StringInStr($dataline, '*') Then
				$FoundData = 1
				$dlsplit = StringSplit($dataline, '$')
				For $gda = 1 To $dlsplit[0]
					If $GpsDetailsOpen = 1 Then GUICtrlSetData($GpsCurrentDataGUI, $dlsplit[$gda]);Show data line in "GPS Details" GUI if it is open
					If StringInStr($dlsplit[$gda], '*') Then ;Check if string containts start character ($) and checsum character (*). If it does not have them, ignore the data

						If StringInStr($dlsplit[$gda], "GPGGA") Then
							_GPGGA($dlsplit[$gda]);Split GPGGA data from data string
							$disconnected_time = -1
						ElseIf StringInStr($dlsplit[$gda], "GPRMC") Then
							_GPRMC($dlsplit[$gda]);Split GPRMC data from data string
							$disconnected_time = -1
						EndIf
					EndIf

				Next
			EndIf
		EndIf
		If BitOR($Temp_Quality = 1, $Temp_Quality = 2) = 1 And BitOR($Temp_Status = "A", $GpsDetailsOpen <> 1) Then ExitLoop;If $Temp_Quality = 1 (GPS has a fix) And, If the details window is open, $Temp_Status = "A" (Active data, not Void)
		If TimerDiff($timeout) > $maxtime Then ExitLoop;If time is over timeout period, exitloop
	WEnd
	If $FoundData = 1 Then
		$disconnected_time = -1
		If BitOR($Temp_Quality = 1, $Temp_Quality = 2) = 1 Then ;If the GPGGA data has a fix(1) then write data to perminant variables
			If $FixTime <> $Temp_FixTime Then $GPGGA_Update = TimerInit()
			$FixTime = $Temp_FixTime
			$Latitude = $Temp_Lat
			$Longitude = $Temp_Lon
			$NumberOfSatalites = $Temp_NumberOfSatalites
			$HorDilPitch = $Temp_HorDilPitch
			$Alt = $Temp_Alt
			$AltS = $Temp_AltS
			$Geo = $Temp_Geo
			$GeoS = $Temp_GeoS
		EndIf
		If $Temp_Status = "A" Then ;If the GPRMC data is Active(A) then write data to perminant variables
			If $FixTime2 <> $Temp_FixTime2 Then $GPRMC_Update = TimerInit()
			$FixTime2 = $Temp_FixTime2
			$Latitude2 = $Temp_Lat2
			$Longitude2 = $Temp_Lon2
			$SpeedInKnots = $Temp_SpeedInKnots
			$SpeedInMPH = $Temp_SpeedInMPH
			$SpeedInKmH = $Temp_SpeedInKmH
			$TrackAngle = $Temp_TrackAngle
			$FixDate = $Temp_FixDate
		EndIf
	Else
		If $disconnected_time = -1 Then $disconnected_time = TimerInit()
		If TimerDiff($disconnected_time) > 10000 Then ; If nothing has been found in the buffer for 10 seconds, turn off gps
			$disconnected_time = -1
			$return = 0
			_TurnOffGPS()
			SoundPlay($SoundDir & $ErrorFlag_sound, 0)
		EndIf
	EndIf

	_ClearGpsDetailsGUI();Reset variables if they are over the allowed timeout
	_UpdateGpsDetailsGUI();Write changes to "GPS Details" GUI if it is open

	If $TurnOffGPS = 1 Then _TurnOffGPS()

	Return ($return)
EndFunc   ;==>_GetGPS

Func _GPGGA($data);Strips data from a gps $GPGGA data string
	;GUICtrlSetData($Lab_GpsInfo, $data)
	If _CheckGpsChecksum($data) = 1 Then
		$GPGGA_Split = StringSplit($data, ",");
		If $GPGGA_Split[0] >= 14 Then
			$Temp_Quality = $GPGGA_Split[7]
			If BitOR($Temp_Quality = 1, $Temp_Quality = 2) = 1 Then
				$Temp_FixTime = _FormatGpsTime($GPGGA_Split[2])
				$Temp_Lat = $GPGGA_Split[4] & " " & StringFormat('%0.4f', $GPGGA_Split[3]);_FormatLatLon($GPGGA_Split[3], $GPGGA_Split[4])
				$Temp_Lon = $GPGGA_Split[6] & " " & StringFormat('%0.4f', $GPGGA_Split[5]);_FormatLatLon($GPGGA_Split[5], $GPGGA_Split[6])
				$Temp_NumberOfSatalites = $GPGGA_Split[8]
				$Temp_HorDilPitch = $GPGGA_Split[9]
				$Temp_Alt = $GPGGA_Split[10] * 3.2808399
				$Temp_AltS = $GPGGA_Split[11]
				$Temp_Geo = $GPGGA_Split[12]
				$Temp_GeoS = $GPGGA_Split[13]
			EndIf
		EndIf
	EndIf
EndFunc   ;==>_GPGGA

Func _GPRMC($data);Strips data from a gps $GPRMC data string
	;GUICtrlSetData($Lab_GpsInfo, $data)
	If _CheckGpsChecksum($data) = 1 Then
		$GPRMC_Split = StringSplit($data, ",")
		If $GPRMC_Split[0] >= 11 Then
			$Temp_Status = $GPRMC_Split[3]
			If $Temp_Status = "A" Then
				$Temp_FixTime2 = _FormatGpsTime($GPRMC_Split[2])
				$Temp_Lat2 = $GPRMC_Split[5] & ' ' & StringFormat('%0.4f', $GPRMC_Split[4]) ;_FormatLatLon($GPRMC_Split[4], $GPRMC_Split[5])
				$Temp_Lon2 = $GPRMC_Split[7] & ' ' & StringFormat('%0.4f', $GPRMC_Split[6]) ;_FormatLatLon($GPRMC_Split[6], $GPRMC_Split[7])
				$Temp_SpeedInKnots = $GPRMC_Split[8]
				$Temp_SpeedInMPH = Round($GPRMC_Split[8] * 1.15, 2)
				$Temp_SpeedInKmH = Round($GPRMC_Split[8] * 1.85200, 2)
				$Temp_TrackAngle = $GPRMC_Split[9]
				$Temp_FixDate = _FormatGpsDate($GPRMC_Split[10])
			EndIf
		EndIf
	EndIf
EndFunc   ;==>_GPRMC

Func _CheckGpsChecksum($checkdata);Checks if GPS Data Checksum is correct. Returns 1 if it is correct, else Returns 0
	$end = 0
	$calc_checksum = 0
	$checkdata_checksum = ''
	$gps_data_split = StringSplit($checkdata, '');Seperate all characters of data and put them into an array
	For $gds = 1 To $gps_data_split[0]
		If $gps_data_split[$gds] <> '$' And $gps_data_split[$gds] <> '*' And $end = 0 Then
			If $calc_checksum = 0 Then ;If $calc_checksum is equal 0, set $calc_checksum to the ascii value of this character
				$calc_checksum = Asc($gps_data_split[$gds])
			Else;If $calc_checksum is not equal 0 then XOR the new character ascii value with the $calc_checksum value
				$calc_checksum = BitXOR($calc_checksum, Asc($gps_data_split[$gds]))
			EndIf
		ElseIf $gps_data_split[$gds] = '*' Then ;If the checksum has been reached, set the $end flag
			$end = 1
		ElseIf $end = 1 And StringIsAlNum($gps_data_split[$gds]) Then ;if the end flag is equal 1 and the character is alpha-numeric then add the character to the end of $checkdata_checksum
			$checkdata_checksum &= $gps_data_split[$gds]
		EndIf
	Next
	$calc_checksum = Hex($calc_checksum, 2)
	If $calc_checksum = $checkdata_checksum Then ;If the calculated checksum matches the given checksum then Return 1, Else Return 0
		Return (1)
	Else
		Return (0)
	EndIf
EndFunc   ;==>_CheckGpsChecksum

Func _Format_GPS_DMM_to_DMS($gps);converts gps ddmm.mmmm to 'dd� mm' ss"
	;If $Debug = 1 Then GUICtrlSetData($debugdisplay, '_Format_GPS_DMM_to_DMS()') ;#Debug Display
	$return = '0� 0' & Chr(39) & ' 0"'
	$splitlatlon1 = StringSplit($gps, " ");Split N,S,E,W from data
	If $splitlatlon1[0] = 2 Then
		$splitlatlon2 = StringSplit($splitlatlon1[2], ".")
		If $splitlatlon2[0] = 2 Then
			$DD = StringTrimRight($splitlatlon2[1], 2)
			$MM = StringTrimLeft($splitlatlon2[1], StringLen($splitlatlon2[1]) - 2)
			$SS = StringFormat('%0.4f', (('.' & $splitlatlon2[2]) * 60)); multiply remaining minutes by 60 to get ss
			$return = $splitlatlon1[1] & ' ' & $DD & '� ' & $MM & Chr(39) & ' ' & $SS & '"' ;Format data properly (ex. dd� mm' ss"N)
		Else
			$return = $splitlatlon1[1] & ' 0� 0' & Chr(39) & ' 0"'
		EndIf
	EndIf
	Return ($return)
EndFunc   ;==>_Format_GPS_DMM_to_DMS

Func _Format_GPS_DMM_to_DDD($gps);converts gps position from ddmm.mmmm to dd.ddddddd
	$return = '0.0000000'
	$splitlatlon1 = StringSplit($gps, " ");Split N,S,E,W from data
	If $splitlatlon1[0] = 2 Then
		$splitlatlon2 = StringSplit($splitlatlon1[2], ".");Split dd from data
		$latlonleft = StringTrimRight($splitlatlon2[1], 2)
		$latlonright = (StringTrimLeft($splitlatlon2[1], StringLen($splitlatlon2[1]) - 2) & '.' & $splitlatlon2[2]) / 60
		$return = $splitlatlon1[1] & ' ' & StringFormat('%0.7f', $latlonleft + $latlonright);set return
	EndIf
	Return ($return)
EndFunc   ;==>_Format_GPS_DMM_to_DDD

Func _Format_GPS_All_to_DMM($gps, $PosChr, $NegChr);converts dd.ddddddd, 'dd� mm' ss", or ddmm.mmmm to ddmm.mmmm
	Local $return = "N 0.0000"
	If StringInStr($gps, '-') Or StringInStr($gps, $NegChr) Then
		$gDir = $NegChr
	Else
		$gDir = $PosChr
	EndIf
	$gps = StringReplace(StringReplace(StringReplace(StringReplace(StringReplace($gps, " ", ""), "-", ""), "+", ""), $PosChr, ""), $NegChr, "")
	$splitlatlon2 = StringSplit($gps, ".")
	If $splitlatlon2[0] = 1 Then
		$DDSplit = StringSplit($gps, "�")
		If $DDSplit[0] = 2 Then
			$DD = $DDSplit[1] * 100
			$MMSplit = StringSplit($DDSplit[2], "'")
			If $MMSplit[0] = 2 Then
				$MM = $MMSplit[1] + (StringReplace($MMSplit[2], '"', '') / 60)
				$return = $gDir & ' ' & StringFormat('%0.4f', $DD + $MM)
			EndIf
		EndIf
	ElseIf $splitlatlon2[0] = 2 Then
		If StringLen($splitlatlon2[2]) = 4 Then ;ddmm.mmmm to ddmm.mmmm
			$return = $gDir & ' ' & StringFormat('%0.4f', $gps)
		Else; dd.dddd to ddmm.mmmm
			$DD = $splitlatlon2[1] * 100
			$MM = ('.' & $splitlatlon2[2]) * 60 ;multiply remaining decimal by 60 to get mm.mmmm
			$return = $gDir & ' ' & StringFormat('%0.4f', $DD + $MM);Format data properly (ex. N ddmm.mmmm)
		EndIf
	EndIf
	Return ($return)
EndFunc   ;==>_Format_GPS_All_to_DMM

Func _Format_GPS_DMM_to_D_MM($gps)
	Local $return = "N 0.0000"
	If $gps = "N 0.0000" Or $gps = "E 0.0000" Then
		$return = $gps
	Else
		$spga = StringSplit($gps, ".")
		If $spga[0] = 2 Then
			$DM = $spga[1]
			$MMMM = $spga[2]
			$d = StringTrimRight($DM, 2)
			$m = StringTrimLeft($DM, StringLen($DM) - 2)
			$return = $d & ' ' & $m & '.' & $MMMM
		EndIf
	EndIf
	Return ($return)
EndFunc   ;==>_Format_GPS_DMM_to_D_MM

Func _FormatGpsTime($time)
	$time = StringTrimRight($time, 4)
	$h = StringTrimRight($time, 4)
	$m = StringTrimLeft(StringTrimRight($time, 2), 2)
	$s = StringTrimLeft($time, 4)
	If $h > 12 Then
		$h = $h - 12
		$l = "PM"
	Else
		$l = "AM"
	EndIf
	Return ($h & ":" & $m & ":" & $s & $l & ' (UTC)')
EndFunc   ;==>_FormatGpsTime

Func _FormatGpsDate($Date)
	$d = StringTrimRight($Date, 4)
	$m = StringTrimLeft(StringTrimRight($Date, 2), 2)
	$y = StringTrimLeft($Date, 4)
	Return ($y & '-' & $m & '-' & $d)
EndFunc   ;==>_FormatGpsDate

Func _DistanceBetweenPoints($Lat1, $Lon1, $Lat2, $Lon2)
	Local $EarthRadius = 6378137 ;meters
	$Lat1 = _deg2rad(StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($Lat1), " ", ""), "N", ""), "S", "-"))
	$Lon1 = _deg2rad(StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($Lon1), " ", ""), "E", ""), "W", "-"))
	$Lat2 = _deg2rad(StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($Lat2), " ", ""), "N", ""), "S", "-"))
	$Lon2 = _deg2rad(StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($Lon2), " ", ""), "E", ""), "W", "-"))
	Return (ACos(Sin($Lat1) * Sin($Lat2) + Cos($Lat1) * Cos($Lat2) * Cos($Lon2 - $Lon1)) * $EarthRadius);Return distance in meters
EndFunc   ;==>_DistanceBetweenPoints

Func _BearingBetweenPoints($Lat1, $Lon1, $Lat2, $Lon2)
	$Lat1 = _deg2rad(StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($Lat1), " ", ""), "N", ""), "S", "-"))
	$Lon1 = _deg2rad(StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($Lon1), " ", ""), "E", ""), "W", "-"))
	$Lat2 = _deg2rad(StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($Lat2), " ", ""), "N", ""), "S", "-"))
	$Lon2 = _deg2rad(StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($Lon2), " ", ""), "E", ""), "W", "-"))
	$bDegrees = _rad2deg(_ATan2(Cos($Lat1) * Sin($Lat2) - Sin($Lat1) * Cos($Lat2) * Cos($Lon2 - $Lon1), Sin($Lon2 - $Lon1) * Cos($Lat2)));Return Bearing in degrees
	If $bDegrees < 0 Then $bDegrees += 360
	Return ($bDegrees);Return bearing in degrees
EndFunc   ;==>_BearingBetweenPoints

Func _DestLat($Lat1, $Brng1, $Dist1)
	Local $EarthRadius = 6378137 ;meters
	$Lat1 = _deg2rad(StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($Lat1), " ", ""), "N", ""), "S", "-"))
	$Brng1 = _deg2rad($Brng1)
	Return (_Format_GPS_All_to_DMM(_rad2deg(ASin(Sin($Lat1) * Cos($Dist1 / $EarthRadius) + Cos($Lat1) * Sin($Dist1 / $EarthRadius) * Cos($Brng1))), "N", "S"));Return destination dmm latitude
EndFunc   ;==>_DestLat

Func _DestLon($Lat1, $Lon1, $Lat2, $Brng1, $Dist1)
	Local $EarthRadius = 6378137 ;meters
	$Lat1 = _deg2rad(StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($Lat1), " ", ""), "N", ""), "S", "-"))
	$Lon1 = _deg2rad(StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($Lon1), " ", ""), "E", ""), "W", "-"))
	$Lat2 = _deg2rad(StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($Lat2), " ", ""), "N", ""), "S", "-"))
	$Brng1 = _deg2rad($Brng1)
	Return (_Format_GPS_All_to_DMM(_rad2deg($Lon1 + _ATan2(Cos($Dist1 / $EarthRadius) - Sin($Lat1) * Sin($Lat2), Sin($Brng1) * Sin($Dist1 / $EarthRadius) * Cos($Lat1))), "E", "W"));Return destination dmm longitude
EndFunc   ;==>_DestLon

Func _GPSOptions()
	;GPS Settings
	$CloseGpsGUI = 0
	Opt("GUIOnEventMode", 0) ; Turn Off OnEvent mode
	$GpsOptions = GUICreate("GPS Settings", 420, 115, -1, -1)
	GUISetBkColor($BackgroundColor)
	GUICtrlCreateLabel("Com Port:", 15, 20, 50, 17)
	$CommPort = GUICtrlCreateCombo("1", 65, 15, 80, 25)
	GUICtrlSetData(-1, "2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20", $ComPort)
	GUICtrlCreateLabel("Baud:", 150, 20, 50, 17)
	$CommBaud = GUICtrlCreateCombo("4800", 185, 15, 80, 25)
	GUICtrlSetData(-1, "9600|14400|19200|38400|57600|115200", $BAUD)
	GUICtrlCreateLabel("Interface:", 270, 20, 50, 17)
	If $GpsType = 0 Then
		$DefGpsInt = "CommMG"
	ElseIf $GpsType = 1 Then
		$DefGpsInt = "Netcomm OCX"
	Else
		$DefGpsInt = "Kernel32"
	EndIf
	$Interface = GUICtrlCreateCombo("Kernel32", 325, 15, 80, 25)
	GUICtrlSetData(-1, "CommMG|Netcomm OCX", $DefGpsInt)
	GUICtrlCreateLabel("Stop Bit:", 16, 52, 50, 17)
	$CommBit = GUICtrlCreateCombo("1", 65, 47, 80, 25)
	GUICtrlSetData(-1, "1.5|2", $STOPBIT)
	GUICtrlCreateLabel("Parity:", 150, 52, 50, 17)
	If $PARITY = 'E' Then
		$l_PARITY = 'Even'
	ElseIf $PARITY = 'M' Then
		$l_PARITY = 'Mark'
	ElseIf $PARITY = 'O' Then
		$l_PARITY = 'Odd'
	ElseIf $PARITY = 'S' Then
		$l_PARITY = 'Space'
	Else
		$l_PARITY = 'None'
	EndIf
	$CommParity = GUICtrlCreateCombo("None", 185, 47, 80, 25)
	GUICtrlSetData(-1, 'Even|Mark|Odd|Space', $l_PARITY)
	GUICtrlCreateLabel("Data Bit:", 270, 52, 50, 17)
	$CommDataBit = GUICtrlCreateCombo("4", 325, 47, 80, 25)
	GUICtrlSetData(-1, "5|6|7|8", $DATABIT)
	$GPS_OK = GUICtrlCreateButton("Ok", 100, 80, 81, 25, 0)
	$GPS_Cancel = GUICtrlCreateButton("Cancel", 240, 80, 81, 25, 0)
	GUISetState(@SW_SHOW)
	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $GPS_Cancel
				ExitLoop
			Case $GPS_OK
				$ComPort = GUICtrlRead($CommPort)
				$BAUD = GUICtrlRead($CommBaud)
				$PARITY = GUICtrlRead($CommParity)
				$DATABIT = GUICtrlRead($CommDataBit)
				$STOPBIT = GUICtrlRead($CommBit)
				If GUICtrlRead($Interface) = "CommMG" Then
					$GpsType = 0
				ElseIf GUICtrlRead($Interface) = "Netcomm OCX" Then
					$GpsType = 1
				Else
					$GpsType = 2
				EndIf
				ExitLoop
		EndSwitch
	WEnd
	Opt("GUIOnEventMode", 1) ; Change to OnEvent mode
	GUIDelete($GpsOptions)
EndFunc   ;==>_GPSOptions

Func _GpsFormat($gps);Converts ddmm.mmmm to the users set gps format
	If $GpsFormat = 1 Then $return = _Format_GPS_DMM_to_DDD($gps)
	If $GpsFormat = 2 Then $return = _Format_GPS_DMM_to_DMS($gps)
	If $GpsFormat = 3 Then $return = $gps
	If $GpsFormat = 4 Then $return = _Format_GPS_DMM_to_D_MM($gps)
	Return ($return)
EndFunc   ;==>_GpsFormat

;-------------------------------------------------------------------------------------------------------------------------------
;                                                       GPS DETAILS GUI FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------

Func _OpenGpsDetailsGUI();Opens GPS Details GUI
	If $GpsDetailsOpen = 0 Then
		$GpsDetailsGUI = GUICreate("Gps Details", 565, 190, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPSIBLINGS))
		GUISetBkColor($BackgroundColor)
		$GpsCurrentDataGUI = GUICtrlCreateLabel('', 8, 5, 550, 15)
		GUICtrlSetColor(-1, $TextColor)
		$GPGGA_Quality = GUICtrlCreateLabel("Quality" & ":", 310, 22, 180, 15)
		GUICtrlSetColor(-1, $TextColor)
		$GPRMC_Status = GUICtrlCreateLabel("Status" & ":", 32, 22, 235, 15)
		GUICtrlSetColor(-1, $TextColor)
		GUICtrlCreateGroup("GPRMC", 8, 40, 273, 145)
		GUICtrlSetColor(-1, $TextColor)
		$GPRMC_Time = GUICtrlCreateLabel("Time" & ":", 25, 55, 235, 15)
		GUICtrlSetColor(-1, $TextColor)
		$GPRMC_Date = GUICtrlCreateLabel("Date" & ":", 25, 70, 235, 15)
		GUICtrlSetColor(-1, $TextColor)
		$GPRMC_Lat = GUICtrlCreateLabel("Latitude" & ":", 25, 85, 235, 15)
		GUICtrlSetColor(-1, $TextColor)
		$GPRMC_Lon = GUICtrlCreateLabel("Longitude" & ":", 25, 100, 235, 15)
		GUICtrlSetColor(-1, $TextColor)
		$GPRMC_SpeedKnots = GUICtrlCreateLabel("Speed(knots)" & ":", 25, 115, 235, 15)
		GUICtrlSetColor(-1, $TextColor)
		$GPRMC_SpeedMPH = GUICtrlCreateLabel("Speed(MPH)" & ":", 25, 130, 243, 15)
		GUICtrlSetColor(-1, $TextColor)
		$GPRMC_SpeedKmh = GUICtrlCreateLabel("Speed(kmh)" & ":", 25, 145, 243, 15)
		GUICtrlSetColor(-1, $TextColor)
		$GPRMC_TrackAngle = GUICtrlCreateLabel("Track Angle" & ":", 25, 160, 243, 20)
		GUICtrlSetColor(-1, $TextColor)
		GUICtrlCreateGroup("GPGGA", 287, 40, 273, 125)
		GUICtrlSetColor(-1, $TextColor)
		$GPGGA_Time = GUICtrlCreateLabel("Time" & ":", 304, 55, 235, 15)
		GUICtrlSetColor(-1, $TextColor)
		$GPGGA_Satalites = GUICtrlCreateLabel("Number of sats" & ":", 304, 70, 235, 15)
		GUICtrlSetColor(-1, $TextColor)
		$GPGGA_Lat = GUICtrlCreateLabel("Latitude" & ":", 304, 85, 235, 15)
		GUICtrlSetColor(-1, $TextColor)
		$GPGGA_Lon = GUICtrlCreateLabel("Longitude" & ":", 304, 100, 235, 15)
		GUICtrlSetColor(-1, $TextColor)
		$GPGGA_HorDilPitch = GUICtrlCreateLabel("H.D.P." & ":", 304, 115, 235, 15)
		GUICtrlSetColor(-1, $TextColor)
		$GPGGA_Alt = GUICtrlCreateLabel("Altitude" & ":", 304, 130, 243, 15)
		GUICtrlSetColor(-1, $TextColor)
		$GPGGA_Geo = GUICtrlCreateLabel("Height of Geoid" & ":", 304, 145, 243, 15)
		GUICtrlSetColor(-1, $TextColor)
		$CloseGpsDetailsGUI = GUICtrlCreateButton("Close", 375, 165, 97, 25, 0)
		GUICtrlSetOnEvent($CloseGpsDetailsGUI, '_CloseGpsDetailsGUI')
		GUISetOnEvent($GUI_EVENT_CLOSE, '_CloseGpsDetailsGUI')

		GUISetState(@SW_SHOW)

		$gpsplit = StringSplit($GpsDetailsPosition, ',')
		If $gpsplit[0] = 4 Then ;If $CompassPosition is a proper position, move and resize window
			WinMove($GpsDetailsGUI, '', $gpsplit[1], $gpsplit[2], $gpsplit[3], $gpsplit[4])
		Else ;Set $CompassPosition to the current window position
			$g = WinGetPos($GpsDetailsGUI)
			$GpsDetailsPosition = $g[0] & ',' & $g[1] & ',' & $g[2] & ',' & $g[3]
		EndIf

		$GpsDetailsOpen = 1
	EndIf
EndFunc   ;==>_OpenGpsDetailsGUI

Func _UpdateGpsDetailsGUI();Updates information on GPS Details GUI
	If $GpsDetailsOpen = 1 Then
		GUICtrlSetData($GPGGA_Time, "Time" & ": " & $FixTime)
		GUICtrlSetData($GPGGA_Lat, "Latitude" & ": " & StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($Latitude), 'S', '-'), 'N', ''), ' ', ''))
		GUICtrlSetData($GPGGA_Lon, "Longitude" & ": " & StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($Longitude), 'W', '-'), 'E', ''), ' ', ''))
		GUICtrlSetData($GPGGA_Quality, "Quality" & ": " & $Temp_Quality)
		GUICtrlSetData($GPGGA_Satalites, "Number of sats" & ": " & $NumberOfSatalites)
		GUICtrlSetData($GPGGA_HorDilPitch, "H.D.P." & ": " & $HorDilPitch)
		GUICtrlSetData($GPGGA_Alt, "Altitude" & ": " & $Alt & $AltS)
		GUICtrlSetData($GPGGA_Geo, "Height of Geoid" & ": " & $Geo & $GeoS)

		GUICtrlSetData($GPRMC_Time, "Time" & ": " & $FixTime2)
		GUICtrlSetData($GPRMC_Date, "Date" & ": " & $FixDate)
		GUICtrlSetData($GPRMC_Lat, "Latitude" & ": " & StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($Latitude2), 'S', '-'), 'N', ''), ' ', ''))
		GUICtrlSetData($GPRMC_Lon, "Longitude" & ": " & StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($Longitude2), 'W', '-'), 'E', ''), ' ', ''))
		GUICtrlSetData($GPRMC_Status, "Status" & ": " & $Temp_Status)
		GUICtrlSetData($GPRMC_SpeedKnots, "Speed(knots)" & ": " & $SpeedInKnots & " Kn")
		GUICtrlSetData($GPRMC_SpeedMPH, "Speed(MPH)" & ": " & $SpeedInMPH & " MPH")
		GUICtrlSetData($GPRMC_SpeedKmh, "Speed(kmh)" & ": " & $SpeedInKmH & " Km/H")
		GUICtrlSetData($GPRMC_TrackAngle, "Track Angle" & ": " & $TrackAngle)
	EndIf
EndFunc   ;==>_UpdateGpsDetailsGUI

Func _ClearGpsDetailsGUI();Clears all GPS Details information
	If Round(TimerDiff($GPGGA_Update)) > $GpsTimeout Then
		$FixTime = ''
		$Latitude = '0.0000000'
		$Longitude = '0.0000000'
		$NumberOfSatalites = '00'
		$HorDilPitch = '0'
		$Alt = '0'
		$AltS = 'M'
		$Geo = '0'
		$GeoS = 'M'
		$GPGGA_Update = TimerInit()
	EndIf
	If Round(TimerDiff($GPRMC_Update)) > $GpsTimeout Then
		$FixTime2 = ''
		$Latitude2 = '0.0000000'
		$Longitude2 = '0.0000000'
		$SpeedInKnots = '0'
		$SpeedInMPH = '0'
		$SpeedInKmH = '0'
		$TrackAngle = '0'
		$FixDate = ''
		$GPRMC_Update = TimerInit()
	EndIf
EndFunc   ;==>_ClearGpsDetailsGUI

Func _CloseGpsDetailsGUI(); Closes GPS Details GUI
	GUIDelete($GpsDetailsGUI)
	$GpsDetailsOpen = 0
EndFunc   ;==>_CloseGpsDetailsGUI

;-------------------------------------------------------------------------------------------------------------------------------
;                                                       GPS COMPASS GUI FUNCTIONS
;-------------------------------------------------------------------------------------------------------------------------------

Func _CompassGUI()
	If $CompassOpen = 0 Then
		$CompassGUI = GUICreate("Compass", 130, 130, -1, -1, BitOR($WS_OVERLAPPEDWINDOW, $WS_CLIPSIBLINGS))
		GUISetBkColor($BackgroundColor)
		$CompassBack = GUICtrlCreateLabel('', 0, 0, 130, 130)
		GUICtrlSetState($CompassBack, $GUI_HIDE)
		$north = GUICtrlCreateLabel("N", 50, 0, 15, 15)
		GUICtrlSetColor(-1, $TextColor)
		$south = GUICtrlCreateLabel("S", 50, 90, 15, 15)
		GUICtrlSetColor(-1, $TextColor)
		$east = GUICtrlCreateLabel("E", 93, 45, 15, 12)
		GUICtrlSetColor(-1, $TextColor)
		$west = GUICtrlCreateLabel("W", 3, 45, 15, 12)
		GUICtrlSetColor(-1, $TextColor)

		_GDIPlus_Startup()
		$CompassGraphic = _GDIPlus_GraphicsCreateFromHWND($CompassGUI)
		$CompassColor = '0xFF' & StringTrimLeft($ControlBackgroundColor, 2)
		$hBrush = _GDIPlus_BrushCreateSolid($CompassColor) ;red
		_GDIPlus_GraphicsFillEllipse($CompassGraphic, 15, 15, 100, 100, $hBrush)

		GUISetOnEvent($GUI_EVENT_CLOSE, '_CloseCompassGui')
		GUISetOnEvent($GUI_EVENT_RESIZED, '_SetCompassSizes')
		GUISetOnEvent($GUI_EVENT_RESTORE, '_SetCompassSizes')

		GUISetState(@SW_SHOW)

		$cpsplit = StringSplit($CompassPosition, ',')
		If $cpsplit[0] = 4 Then ;If $CompassPosition is a proper position, move and resize window
			WinMove($CompassGUI, '', $cpsplit[1], $cpsplit[2], $cpsplit[3], $cpsplit[4])
		Else ;Set $CompassPosition to the current window position
			$c = WinGetPos($CompassGUI)
			$CompassPosition = $c[0] & ',' & $c[1] & ',' & $c[2] & ',' & $c[3]
		EndIf
		_SetCompassSizes()

		$CompassOpen = 1
	Else
		WinActivate($CompassGUI)
	EndIf
EndFunc   ;==>_CompassGUI

Func _CloseCompassGui();closes the compass window
	_GDIPlus_GraphicsDispose($CompassGraphic)
	_GDIPlus_Shutdown()
	GUIDelete($CompassGUI)
	$CompassOpen = 0
EndFunc   ;==>_CloseCompassGui

Func _SetCompassSizes();Takes the size of a hidden label in the compass window and determines the Width/Height of the compass
	If $CompassOpen = 1 Then
		;Check Compass Window Position
		If WinActive($CompassGUI) Then
			$c = WinGetPos($CompassGUI)
			If $c[0] & ',' & $c[1] & ',' & $c[2] & ',' & $c[3] <> $CompassPosition Then $CompassPosition = $c[0] & ',' & $c[1] & ',' & $c[2] & ',' & $c[3] ;If the $CompassGUI has moved or resized, set $CompassPosition to current window size
		EndIf
		;Get sizes
		$a = ControlGetPos("", "", $CompassBack)
		If Not @error Then
			$compasspos = $a[0] & $a[1] & $a[2] & $a[3]
			If $a[2] > $a[3] Then
				Dim $CompassHeight = $a[3] - 30
			Else
				Dim $CompassHeight = $a[2] - 30
			EndIf
		EndIf
		$CompassMidWidth = 10 + ($CompassHeight / 2)
		$CompassMidHeight = 10 + ($CompassHeight / 2)
		GUICtrlSetPos($north, $CompassMidWidth, 0, 15, 15)
		GUICtrlSetPos($south, $CompassMidWidth, $CompassHeight + 15, 15, 15)
		GUICtrlSetPos($east, $CompassHeight + 15, $CompassMidHeight, 15, 15)
		GUICtrlSetPos($west, 0, $CompassMidHeight, 15, 15)

		_GDIPlus_GraphicsDispose($CompassGraphic)
		_GDIPlus_Shutdown()
		_GDIPlus_Startup()

		$CompassGraphic = _GDIPlus_GraphicsCreateFromHWND($CompassGUI)
		$CompassColor = '0xFF' & StringTrimLeft($ControlBackgroundColor, 2)
		$hBrush = _GDIPlus_BrushCreateSolid($CompassColor)
		_GDIPlus_GraphicsFillEllipse($CompassGraphic, 15, 15, $CompassHeight, $CompassHeight, $hBrush)
	EndIf
EndFunc   ;==>_SetCompassSizes

Func _DrawCompassLine($Degree, $LineColorARGB = "0xFF000000");, $Degree2);Draws compass in GPS Details GUI
	If $CompassOpen = 1 Then
		$Radius = ($CompassHeight / 2) - 1
		$CenterX = ($CompassHeight / 2) + 15
		$CenterY = ($CompassHeight / 2) + 15
		If $Degree >= 0 And $Degree <= 360 Then ;Only Draw line if valid degree value was given
			;Calculate (X, Y) based on Degrees, Radius, And Center of circle (X, Y) for $Degree
			If $Degree = 0 Or $Degree = 360 Then
				$CircleX = $CenterX
				$CircleY = $CenterY - $Radius
			ElseIf $Degree > 0 And $Degree < 90 Then
				$Radians = $Degree * 0.0174532925
				$CircleX = $CenterX + (Sin($Radians) * $Radius)
				$CircleY = $CenterY - (Cos($Radians) * $Radius)
			ElseIf $Degree = 90 Then
				$CircleX = $CenterX + $Radius
				$CircleY = $CenterY
			ElseIf $Degree > 90 And $Degree < 180 Then
				$TmpDegree = $Degree - 90
				$Radians = $TmpDegree * 0.0174532925
				$CircleX = $CenterX + (Cos($Radians) * $Radius)
				$CircleY = $CenterY + (Sin($Radians) * $Radius)
			ElseIf $Degree = 180 Then
				$CircleX = $CenterX
				$CircleY = $CenterY + $Radius
			ElseIf $Degree > 180 And $Degree < 270 Then
				$TmpDegree = $Degree - 180
				$Radians = $TmpDegree * 0.0174532925
				$CircleX = $CenterX - (Sin($Radians) * $Radius)
				$CircleY = $CenterY + (Cos($Radians) * $Radius)
			ElseIf $Degree = 270 Then
				$CircleX = $CenterX - $Radius
				$CircleY = $CenterY
			ElseIf $Degree > 270 And $Degree < 360 Then
				$TmpDegree = $Degree - 270
				$Radians = $TmpDegree * 0.0174532925
				$CircleX = $CenterX - (Cos($Radians) * $Radius)
				$CircleY = $CenterY - (Sin($Radians) * $Radius)
			EndIf
			;Draw $Degree Line
			$pen = _GDIPlus_PenCreate($LineColorARGB, 2)
			_GDIPlus_GraphicsDrawLine($CompassGraphic, $CenterX, $CenterY, $CircleX, $CircleY, $pen)
			_GDIPlus_PenDispose($pen)
		EndIf

	EndIf
EndFunc   ;==>_DrawCompassLine

Func _DrawCompassCircle($Percent, $LineColorARGB = "0xFF000000");, $Degree2);Draws compass in GPS Details GUI
	$Radius = ($CompassHeight / 2) - 1
	$pen = _GDIPlus_PenCreate($LineColorARGB, 2)
	_GDIPlus_GraphicsDrawEllipse($CompassGraphic, 15 + ($Radius * ($Percent * .01)), 15 + ($Radius * ($Percent * .01)), $CompassHeight - (2 * ($Radius * ($Percent * .01))), $CompassHeight - (2 * ($Radius * ($Percent * .01))), $pen)
	_GDIPlus_PenDispose($pen)
EndFunc   ;==>_DrawCompassCircle

;---------------------------------------------------------------------------------------
;Import Functions
;---------------------------------------------------------------------------------------

Func _ImportGPX()
	$GPXfile = FileOpenDialog("Import from GPX", '', "GPS eXchange Format" & ' (*.GPX)', 1)
	ConsoleWrite($GPXfile & @CRLF)
	$result = _XMLFileOpen($GPXfile)
	$path = "/*[1]"
	$GpxArray = _XMLGetChildNodes($path)
	If IsArray($GpxArray) Then
		For $X = 1 To $GpxArray[0]
			If $GpxArray[$X] = "wpt" Then
				ConsoleWrite("! -------------------------------------------------------------------------------------------> wpt" & @CRLF)
				Local $ImpLat, $ImpLon, $ImpDesc, $ImpNotes, $ImpName, $ImpLink, $ImpAuth, $ImpType, $ImpDif, $ImpTer
				Local $aKeys[1], $aValues[1] ;Arrays used for attributes
				_XMLGetAllAttrib($path & "/*[" & $X & "]", $aKeys, $aValues) ;Retrieve all attributes
				If Not @error Then
					For $y = 0 To UBound($aKeys) - 1
						;ConsoleWrite($aKeys[$Y] & "=" & $aValues[$Y] & ", ") ;Output all attributes
						If $aKeys[$y] = "lat" Then $ImpLat = $aValues[$y]
						If $aKeys[$y] = "lon" Then $ImpLon = $aValues[$y]
						_XMLGetAllAttrib($path & "/*[" & $X & "]", $aKeys, $aValues) ;Retrieve all attributes
					Next
				EndIf
				ConsoleWrite($path & "/*[" & $X & "]" & @CRLF)
				$WptDataPath = $path & "/*[" & $X & "]"
				$WptDataArray = _XMLGetChildNodes($WptDataPath)
				If IsArray($WptDataArray) Then

					For $X1 = 1 To $WptDataArray[0]
						$WptFieldPath = $WptDataPath & "/*[" & $X1 & "]"
						$WptFieldValueArray = _XMLGetValue($WptDataPath & "/*[" & $X1 & "]")
						If IsArray($WptFieldValueArray) Then
							If $WptDataArray[$X1] = "name" Then $ImpName = $WptFieldValueArray[1]
							If $WptDataArray[$X1] = "desc" Then
								If StringInStr($WptFieldValueArray[1], ' by ') Then
									$descarr1 = StringSplit($WptFieldValueArray[1], ' by ', 1)
									$ImpDesc = $descarr1[1]
									If StringInStr($descarr1[2], ', ') Then
										$descarr2 = StringSplit($descarr1[2], ', ', 1)
										$ImpAuth = $descarr2[1]
										If StringInStr($descarr2[2], ' (') Then
											$descarr3 = StringSplit($descarr2[2], ' (', 1)
											$ImpType = $descarr3[1]
											If StringInStr($descarr3[2], '/') Then
												$descarr4 = StringSplit($descarr3[2], '/', 1)
												$ImpDif = $descarr4[1]
												$ImpTer = StringReplace($descarr4[2], ')', '')
											EndIf
										EndIf
									EndIf
								Else
									$ImpNotes = $WptFieldValueArray[1]
								EndIf
							EndIf
							If $WptDataArray[$X1] = "urlname" Then $ImpDesc = $WptFieldValueArray[1]
							If $WptDataArray[$X1] = "url" Then $ImpLink = $WptFieldValueArray[1]
							If $WptDataArray[$X1] = "Notes" Then $ImpNotes = $WptFieldValueArray[1]
						EndIf
					Next
				EndIf
				ConsoleWrite($ImpLat & " - " & $ImpLon & " - " & $ImpDesc & " - " & $ImpNotes & " - " & $ImpName & " - " & $ImpAuth & " - " & $ImpType & " - " & $ImpDif & " - " & $ImpTer & @CRLF)

				$WPName = $ImpName
				$WPDesc = $ImpDesc
				$WPNotes = $ImpNotes
				$WPLink = $ImpLink
				$WPAuth = $ImpAuth
				$WPType = $ImpType
				$WPDif = $ImpDif
				$WPTer = $ImpTer
				$DestLat = _Format_GPS_All_to_DMM(StringFormat('%0.7f', $ImpLat), "N", "S")
				$DestLon = _Format_GPS_All_to_DMM(StringFormat('%0.7f', $ImpLon), "E", "W")
				$DestBrng = StringFormat('%0.1f', _BearingBetweenPoints($StartLat, $StartLon, $DestLat, $DestLon))
				$DestDist = StringFormat('%0.1f', _DistanceBetweenPoints($StartLat, $StartLon, $DestLat, $DestLon))

				$query = "SELECT TOP 1 WPID FROM WP WHERE Name = '" & StringReplace($WPName, "'", "''") & "' And Desc1 = '" & StringReplace($WPDesc, "'", "''") & "' And Latitude = '" & $DestLat & "' And Longitude = '" & $DestLon & "'"
				$WpMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
				$FoundWpMatch = UBound($WpMatchArray) - 1
				If $FoundWpMatch = 0 Then ;If WP is not found then add it
					$WPID += 1
					;Add WPs to top of list
					If $AddDirection = 0 Then
						$query = "UPDATE WP SET ListRow = ListRow + 1 WHERE ListRow <> '-1'"
						_ExecuteMDB($MysticacheDB, $DB_OBJ, $query)
						$DBAddPos = 0
					Else ;Add to bottom
						$DBAddPos = -1
					EndIf
					;Add Into ListView
					$ListRow = _GUICtrlListView_InsertItem($ListviewWPs, $WPID, $DBAddPos)

					_ListViewAddWp($ListRow, $WPID, $WPName, $WPDesc, $WPNotes, _GpsFormat($DestLat), _GpsFormat($DestLon), $DestBrng, $DestDist, $WPLink, $WPAuth, $WPType, $WPDif, $WPTer)
					ConsoleWrite($WPID & '|' & $ListRow & '|' & $WPDesc & '|' & $WPName & '|' & $WPNotes & '|' & $DestLat & '|' & $DestLon & '|' & $DestBrng & '|' & $DestDist & '|' & $WPLink & '|' & $WPAuth & '|' & $WPType & '|' & $WPDif & '|' & $WPTer & @CRLF)
					_AddRecord($MysticacheDB, "WP", $DB_OBJ, $WPID & '|' & $ListRow & '|' & $WPName & '|' & $WPDesc & '|' & $WPNotes & '|' & $DestLat & '|' & $DestLon & '|' & $DestBrng & '|' & $DestDist & '|' & $WPLink & '|' & $WPAuth & '|' & $WPType & '|' & $WPDif & '|' & $WPTer)

				EndIf

			ElseIf $GpxArray[$X] = "trk" Then
				ConsoleWrite("! -------------------------------------------------------------------------------------------> trk" & @CRLF)
				Local $TrackSegNum, $TrackName, $TrackDesc, $TrackCmt, $TrackSrc, $TrackUrl, $TrackUrlName, $TrackNum
				$TrkDataPath = $path & "/*[" & $X & "]"
				$TrkDataArray = _XMLGetChildNodes($TrkDataPath)
				;ConsoleWrite($TrkDataPath & @CRLF)
				If IsArray($TrkDataArray) Then
					Local $TrackSegNum = 0
					For $X1 = 1 To $TrkDataArray[0]
						$TrkFieldPath = $TrkDataPath & "/*[" & $X1 & "]"
						$TrkFieldValueArray = _XMLGetValue($TrkDataPath & "/*[" & $X1 & "]")
						;ConsoleWrite($TrkFieldPath & @CRLF)
						If IsArray($TrkFieldValueArray) Then
							If $TrkDataArray[$X1] = "name" Then $TrackName = $TrkFieldValueArray[1]
							If $TrkDataArray[$X1] = "desc" Then $TrackDesc = $TrkFieldValueArray[1]
							If $TrkDataArray[$X1] = "cmt" Then $TrackCmt = $TrkFieldValueArray[1]
							If $TrkDataArray[$X1] = "src" Then $TrackSrc = $TrkFieldValueArray[1]
							If $TrkDataArray[$X1] = "url" Then $TrackUrl = $TrkFieldValueArray[1]
							If $TrkDataArray[$X1] = "urlname" Then $TrackUrlName = $TrkFieldValueArray[1]
							If $TrkDataArray[$X1] = "number" Then $TrackNum = $TrkFieldValueArray[1]
							If $TrkDataArray[$X1] = "trkseg" Then
								;Add Track Information to table
								$TrackSegNum += 1
								If $TrackNum = 0 Then $TrackNum = $TrackSegNum
								$TRACKID += 1
								If $AddDirection = 0 Then ;Add TRKs to top of list
									$query = "UPDATE TRACK SET ListRow = ListRow + 1 WHERE ListRow <> '-1'"
									_ExecuteMDB($MysticacheDB, $DB_OBJ, $query)
									$DBAddPos = 0
								Else ;Add to bottom
									$DBAddPos = -1
								EndIf
								$ListRow = _GUICtrlListView_InsertItem($ListviewTrk, $TRACKID, $DBAddPos)
								_ListViewAddTrk($ListRow, $TRACKID, $TrackName, $TrackDesc, $TrackCmt, $TrackSrc, $TrackUrl, $TrackUrlName, $TrackNum)
								_AddRecord($MysticacheDB, "TRACK", $DB_OBJ, $TRACKID & '|' & $ListRow & '|' & $TrackName & '|' & $TrackDesc & '|' & $TrackCmt & '|' & $TrackSrc & '|' & $TrackUrl & '|' & $TrackUrlName & '|' & $TrackNum)
								;Get Track Segment
								$TrkSegArray = _XMLGetChildNodes($TrkFieldPath)
								If IsArray($TrkSegArray) Then
									For $X2 = 1 To $TrkSegArray[0]
										Local $TrackLat, $TrackLon, $TrackElev, $TrackTime, $TrackMagvar, $TrackCourse, $TrackGeoidHeight, $TrackFix, $TrackSat, $TrackHdop, $TrackVdop, $TrackPdop, $TrackAgeOfGpsData, $TrackDgpsid, $TrackSpeed, $TrackptName, $TrackCmt, $TrackDesc, $TrackSrc, $TrackUrl, $TrackUrlName, $TrackSym, $TrackType
										If $TrkSegArray[$X2] = "trkpt" Then
											$TrkptPath = $TrkFieldPath & "/*[" & $X2 & "]"
											;ConsoleWrite($TrkptPath & @CRLF)
											Local $aKeys[1], $aValues[1] ;Arrays used for attributes
											_XMLGetAllAttrib($TrkptPath, $aKeys, $aValues) ;Retrieve all attributes
											If Not @error Then
												For $y = 0 To UBound($aKeys) - 1
													;ConsoleWrite($aKeys[$Y] & "=" & $aValues[$Y] & ", ") ;Output all attributes
													If $aKeys[$y] = "lat" Then $TrackLat = _Format_GPS_All_to_DMM(StringFormat('%0.7f', $aValues[$y]), "N", "S")
													If $aKeys[$y] = "lon" Then $TrackLon = _Format_GPS_All_to_DMM(StringFormat('%0.7f', $aValues[$y]), "E", "W")
													_XMLGetAllAttrib($TrkptPath, $aKeys, $aValues) ;Retrieve all attributes
												Next
											EndIf
											$TrkptArray = _XMLGetChildNodes($TrkptPath)
											If IsArray($TrkptArray) Then
												For $X3 = 1 To $TrkptArray[0]
													$TrkptFieldPath = $TrkptPath & "/*[" & $X3 & "]"
													$TrkptFieldValueArray = _XMLGetValue($TrkptFieldPath)
													;ConsoleWrite($TrkptFieldPath & @CRLF)
													If IsArray($TrkptFieldValueArray) Then
														If $TrkptArray[$X3] = "ele" Then $TrackElev = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "time" Then $TrackTime = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "magvar" Then $TrackMagvar = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "corse" Then $TrackCourse = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "geoidheight" Then $TrackGeoidHeight = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "fix" Then $TrackFix = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "sat" Then $TrackSat = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "hdop" Then $TrackHdop = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "vdop" Then $TrackVdop = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "pdop" Then $TrackPdop = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "ageofgpsdata" Then $TrackAgeOfGpsData = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "dgpsid" Then $TrackDgpsid = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "speed" Then $TrackSpeed = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "name" Then $TrackptName = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "cmt" Then $TrackCmt = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "desc" Then $TrackDesc = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "src" Then $TrackSrc = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "url" Then $TrackUrl = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "urlname" Then $TrackUrlName = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "sym" Then $TrackSym = $TrkptFieldValueArray[1]
														If $TrkptArray[$X3] = "type" Then $TrackType = $TrkptFieldValueArray[1]
													EndIf
												Next
											EndIf
											$TRACKSEGID += 1
											_AddRecord($MysticacheDB, "TRACKSEG", $DB_OBJ, $TRACKSEGID & '|' & $TRACKID & '|' & $TrackLat & '|' & $TrackLon & '|' & $TrackElev & '|' & $TrackTime & '|' & $TrackMagvar & '|' & $TrackCourse & '|' & $TrackGeoidHeight & '|' & $TrackFix & '|' & $TrackSat & '|' & $TrackHdop & '|' & $TrackVdop & '|' & $TrackPdop & '|' & $TrackAgeOfGpsData & '|' & $TrackDgpsid & '|' & $TrackSpeed & '|' & $TrackptName & '|' & $TrackCmt & '|' & $TrackDesc & '|' & $TrackSrc & '|' & $TrackUrl & '|' & $TrackUrlName & '|' & $TrackSym & '|' & $TrackType)
											ConsoleWrite('Name:' & $TrackName & ' desc:' & $TrackDesc & ' lat:' & $TrackLat & ' lon:' & $TrackLon & ' ele:' & $TrackElev & ' datetime:' & $TrackTime & @CRLF)
										EndIf
									Next
								EndIf
							EndIf
						EndIf
					Next
				EndIf
			EndIf
		Next
		MsgBox(0, "Done", "Import complete")
	EndIf
EndFunc   ;==>_ImportGPX

Func _ImportLOC()
	$Locfile = FileOpenDialog("Import from LOC", '', "LOC File" & ' (*.LOC)', 1)
	$result = _XMLFileOpen($Locfile)
	$path = "/*[1]"
	$LocArray = _XMLGetChildNodes($path)
	If IsArray($LocArray) Then
		For $X = 1 To $LocArray[0]
			Local $ImpLat = "", $ImpLon = "", $ImpDesc = "", $ImpNotes = "", $ImpName = "", $ImpLink = "", $ImpAuth = "", $ImpType = "", $ImpDif = "", $ImpTer = ""
			ConsoleWrite($ImpLat & " - " & $ImpLon & " - " & $ImpDesc & " - " & $ImpNotes & " - " & $ImpName & " - " & $ImpLink & @CRLF)
			If $LocArray[$X] = "waypoint" Then
				ConsoleWrite("! -------------------------------------------------------------------------------------------> wpt" & @CRLF)
				ConsoleWrite($path & "/*[" & $X & "]" & @CRLF)
				$WptDataPath = $path & "/*[" & $X & "]"
				$WptDataArray = _XMLGetChildNodes($WptDataPath)
				If IsArray($WptDataArray) Then
					For $X1 = 1 To $WptDataArray[0]
						$WptFieldPath = $WptDataPath & "/*[" & $X1 & "]"
						$WptFieldValueArray = _XMLGetValue($WptDataPath & "/*[" & $X1 & "]")
						If IsArray($WptFieldValueArray) Then
							If $WptDataArray[$X1] = "name" Then
								If StringInStr($WptFieldValueArray[1], ' by ') Then
									$descarr1 = StringSplit($WptFieldValueArray[1], ' by ', 1)
									$ImpDesc = $descarr1[1]
									If StringInStr($descarr1[2], ' (') Then
										$descarr2 = StringSplit($descarr1[2], ' (', 1)
										$ImpAuth = $descarr2[1]
										If StringInStr($descarr2[2], '/') Then
											$descarr3 = StringSplit($descarr2[2], '/', 1)
											$ImpDif = $descarr3[1]
											$ImpTer = StringReplace($descarr3[2], ')', '')
										EndIf
									EndIf
								Else
									$ImpNotes = $WptFieldValueArray[1]
								EndIf
								Local $aKeys[1], $aValues[1] ;Arrays used for attributes
								_XMLGetAllAttrib($WptFieldPath, $aKeys, $aValues) ;Retrieve all attributes
								If Not @error Then
									For $y = 0 To UBound($aKeys) - 1
										;ConsoleWrite($aKeys[$Y] & "=" & $aValues[$Y] & ", ") ;Output all attributes
										If $aKeys[$y] = "id" Then $ImpName = $aValues[$y]
									Next
								EndIf
							EndIf
							If $WptDataArray[$X1] = "type" Then $ImpType = $WptFieldValueArray[1]
							If $WptDataArray[$X1] = "urlName" Then $ImpDesc = $WptFieldValueArray[1]
							If $WptDataArray[$X1] = "Notes" Then $ImpNotes = $WptFieldValueArray[1]
							If $WptDataArray[$X1] = "CacheType" Then $ImpType = $WptFieldValueArray[1]
							If $WptDataArray[$X1] = "link" Then $ImpLink = $WptFieldValueArray[1]
							If $WptDataArray[$X1] = "coord" Then
								Local $aKeys[1], $aValues[1] ;Arrays used for attributes
								_XMLGetAllAttrib($WptFieldPath, $aKeys, $aValues) ;Retrieve all attributes
								If Not @error Then
									For $y = 0 To UBound($aKeys) - 1
										;ConsoleWrite($aKeys[$Y] & "=" & $aValues[$Y] & ", ") ;Output all attributes
										If $aKeys[$y] = "lat" Then $ImpLat = $aValues[$y]
										If $aKeys[$y] = "lon" Then $ImpLon = $aValues[$y]
									Next
								EndIf
							EndIf
						EndIf
					Next
				EndIf
				ConsoleWrite($ImpLat & " - " & $ImpLon & " - " & $ImpDesc & " - " & $ImpNotes & " - " & $ImpName & " - " & $ImpLink & @CRLF)

				$WPName = $ImpName
				$WPDesc = $ImpDesc
				$WPNotes = $ImpNotes
				$WPLink = $ImpLink
				$WPAuth = $ImpAuth
				$WPType = $ImpType
				$WPDif = $ImpDif
				$WPTer = $ImpTer
				$DestLat = _Format_GPS_All_to_DMM(StringFormat('%0.7f', $ImpLat), "N", "S")
				$DestLon = _Format_GPS_All_to_DMM(StringFormat('%0.7f', $ImpLon), "E", "W")
				$DestBrng = StringFormat('%0.1f', _BearingBetweenPoints($StartLat, $StartLon, $DestLat, $DestLon))
				$DestDist = StringFormat('%0.1f', _DistanceBetweenPoints($StartLat, $StartLon, $DestLat, $DestLon))

				$query = "SELECT TOP 1 WPID FROM WP WHERE Name = '" & StringReplace($WPName, "'", "''") & "' And Desc1 = '" & StringReplace($WPDesc, "'", "''") & "' And Latitude = '" & $DestLat & "' And Longitude = '" & $DestLon & "'"
				$WpMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
				$FoundWpMatch = UBound($WpMatchArray) - 1
				If $FoundWpMatch = 0 Then ;If WP is not found then add it
					$WPID += 1
					;Add APs to top of list
					If $AddDirection = 0 Then
						$query = "UPDATE WP SET ListRow = ListRow + 1 WHERE ListRow <> '-1'"
						_ExecuteMDB($MysticacheDB, $DB_OBJ, $query)
						$DBAddPos = 0
					Else ;Add to bottom
						$DBAddPos = -1
					EndIf
					;Add Into ListView
					$ListRow = _GUICtrlListView_InsertItem($ListviewWPs, $WPID, $DBAddPos)

					_ListViewAddWp($ListRow, $WPID, $WPName, $WPDesc, $WPNotes, _GpsFormat($DestLat), _GpsFormat($DestLon), $DestBrng, $DestDist, $WPLink, $WPAuth, $WPType, $WPDif, $WPTer)
					_ListViewAddWp($ListRow, $WPID, $WPName, $WPDesc, $WPNotes, _GpsFormat($DestLat), _GpsFormat($DestLon), $DestBrng, $DestDist, $WPLink, $WPAuth, $WPType, $WPDif, $WPTer)
					_AddRecord($MysticacheDB, "WP", $DB_OBJ, $WPID & '|' & $ListRow & '|' & $WPName & '|' & $WPDesc & '|' & $WPNotes & '|' & $DestLat & '|' & $DestLon & '|' & $DestBrng & '|' & $DestDist & '|' & $WPLink & '|' & $WPAuth & '|' & $WPType & '|' & $WPDif & '|' & $WPTer)
				EndIf

			EndIf
		Next
		MsgBox(0, "Done", "Import complete")
	EndIf
EndFunc   ;==>_ImportLOC

;---------------------------------------------------------------------------------------
;Export Functions
;---------------------------------------------------------------------------------------

;-->KML
Func _ExportAllToKml()
	$kml = FileSaveDialog("Google Earth Output File", $SaveDir, 'Google Earth (*.kml)', '', $ldatetimestamp & '.kml')
	If Not @error Then
		$savekml = _SaveKml($kml)
		If $savekml = 1 Then
			MsgBox(0, 'Done', 'Saved As' & ': "' & $kml & '"')
		Else
			MsgBox(0, 'Error', 'Error saving file' & ': "' & $kml & '"')
		EndIf
	EndIf
EndFunc   ;==>_ExportAllToKml

Func _SaveKml($kml, $MapGpsTrack = 1, $MapGpsWpts = 1)
	$file = '<?xml version="1.0" encoding="utf-8"?>' & @CRLF _
			 & '<kml xmlns="http://earth.google.com/kml/2.0">' & @CRLF _
			 & '<Document>' & @CRLF _
			 & '<description>' & 'Myticache AutoKML' & ' - By ' & 'Andrew Calcutt' & '</description>' & @CRLF _
			 & '<name>' & 'Mysticache AutoKML' & ' ' & 'V1.0' & '</name>' & @CRLF
	If $MapGpsWpts = 1 Then
		$file &= '<Style id="Waypoint">' & @CRLF _
				 & '<IconStyle>' & @CRLF _
				 & '<scale>.7</scale>' & @CRLF _
				 & '<Icon>' & @CRLF _
				 & '<href>' & $ImageDir & 'waypoint.png</href>' & @CRLF _
				 & '</Icon>' & @CRLF _
				 & '</IconStyle>' & @CRLF _
				 & '</Style>' & @CRLF
	EndIf
	If $MapGpsTrack = 1 Then
		$file &= '<Style id="Location">' & @CRLF _
				 & '<LineStyle>' & @CRLF _
				 & '<color>7f0000ff</color>' & @CRLF _
				 & '<width>4</width>' & @CRLF _
				 & '</LineStyle>' & @CRLF _
				 & '</Style>' & @CRLF
	EndIf
	If $MapGpsWpts = 1 Then
		$query = "SELECT WPID, Name, Desc1, Notes, Latitude, Longitude, Bearing, Distance, Link FROM WP"
		$WpMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
		$FoundWpMatch = UBound($WpMatchArray) - 1
		If $FoundWpMatch <> 0 Then
			$file &= '<Folder>' & @CRLF _
					 & '<name>Waypoints</name>' & @CRLF
			For $exp = 1 To $FoundWpMatch
				$ExpWPID = $WpMatchArray[$exp][1]
				$ExpName = _XMLSanitize($WpMatchArray[$exp][2])
				$ExpGPID = _XMLSanitize($WpMatchArray[$exp][3])
				$ExpNotes = _XMLSanitize($WpMatchArray[$exp][4])
				$ExpLat = StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($WpMatchArray[$exp][5]), 'S', '-'), 'N', ''), ' ', '')
				$ExpLon = StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($WpMatchArray[$exp][6]), 'W', '-'), 'E', ''), ' ', '')
				$ExpBrng = $WpMatchArray[$exp][7]
				$ExpDest = $WpMatchArray[$exp][8]
				$ExpLink = _XMLSanitize($WpMatchArray[$exp][9])

				$file &= '<Placemark>' & @CRLF _
						 & '<name>' & $ExpName & '</name>' & @CRLF _
						 & '<description><![CDATA[<b>' & 'Name' & ': </b>' & $ExpName & '<br /><b>' & 'GC #' & ': </b>' & $ExpGPID & '<br /><b>' & "Notes" & ': </b>' & $ExpNotes & '<br /><b>' & 'Latitude' & ': </b>' & $ExpLat & '<br /><b>' & 'Longitude' & ': </b>' & $ExpLon & '<br /><b>' & "Link" & ': </b>' & $ExpLink & '<br />]]></description>' & @CRLF _
						 & '<styleUrl>#Waypoint</styleUrl>' & @CRLF _
						 & '<Point>' & @CRLF _
						 & '<coordinates>' & $ExpLon & ',' & $ExpLat & ',0</coordinates>' & @CRLF _
						 & '</Point>' & @CRLF _
						 & '</Placemark>' & @CRLF
			Next


			$file &= '</Folder>' & @CRLF
		EndIf

	EndIf
	If $MapGpsTrack = 1 Then
		$query = "SELECT Latitude, Longitude FROM GPS WHERE Latitude <> 'N 0.0000' And Longitude <> 'E 0.0000' ORDER BY Date1, Time1"
		$GpsMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
		$FoundGpsMatch = UBound($GpsMatchArray) - 1
		If $FoundGpsMatch <> 0 Then
			$file &= '<Folder>' & @CRLF _
					 & '<name>Mysticache Gps Track</name>' & @CRLF _
					 & '<Placemark>' & @CRLF _
					 & '<name>Location</name>' & @CRLF _
					 & '<styleUrl>#Location</styleUrl>' & @CRLF _
					 & '<LineString>' & @CRLF _
					 & '<extrude>1</extrude>' & @CRLF _
					 & '<tessellate>1</tessellate>' & @CRLF _
					 & '<coordinates>' & @CRLF
			For $exp = 1 To $FoundGpsMatch
				$ExpLat = _Format_GPS_DMM_to_DDD($GpsMatchArray[$exp][1])
				$ExpLon = _Format_GPS_DMM_to_DDD($GpsMatchArray[$exp][2])
				If $ExpLat <> 'N 0.0000000' And $ExpLon <> 'E 0.0000000' Then
					$FoundApWithGps = 1
					$file &= StringReplace(StringReplace(StringReplace($ExpLon, 'W', '-'), 'E', ''), ' ', '') & ',' & StringReplace(StringReplace(StringReplace($ExpLat, 'S', '-'), 'N', ''), ' ', '') & ',0' & @CRLF
				EndIf
			Next
			$file &= '</coordinates>' & @CRLF _
					 & '</LineString>' & @CRLF _
					 & '</Placemark>' & @CRLF _
					 & '</Folder>' & @CRLF
		EndIf
	EndIf
	$file &= '</Document>' & @CRLF _
			 & '</kml>'

	FileDelete($kml)
	$filewrite = FileWrite($kml, $file)
	If $filewrite = 0 Then
		Return (0)
	Else
		Return (1)
	EndIf
EndFunc   ;==>_SaveKml

;-->GPX
Func _ExportAllToGPX()
	$gpx = FileSaveDialog("GPX Output File", $SaveDir, 'GPS eXchange Format (*.gpx)', '', $ldatetimestamp & '.gpx')
	If Not @error Then
		$savekml = _SaveGPX($gpx)
		If $savekml = 1 Then
			MsgBox(0, 'Done', 'Saved As' & ': "' & $gpx & '"')
		Else
			MsgBox(0, 'Error', 'Error saving file' & ': "' & $gpx & '"')
		EndIf
	EndIf
EndFunc   ;==>_ExportAllToGPX

Func _SaveGPX($gpx, $MapGpsTrack = 1, $MapGpsWpts = 1)
	$FoundApWithGps = 0
	If StringInStr($gpx, '.gpx') = 0 Then $gpx = $gpx & '.gpx'
	FileDelete($gpx)
	$file = '<?xml version="1.0" encoding="UTF-8" standalone="no" ?>' & @CRLF _
			 & '<gpx creator="' & $Script_Name & '" version="1.1">' & @CRLF _
			 & '	<name>' & $ldatetimestamp & '</name>' & @CRLF _
			 & '	<desc>Geocache file generated by ' & $Script_Name & '</desc>' & @CRLF _
			 & '	<author>' & $Script_Name & '</author>' & @CRLF
	If $MapGpsWpts = 1 Then
		$query = "SELECT WPID, Name, Desc1, Notes, Latitude, Longitude, Bearing, Distance, Link, Author, Type, Difficulty, Terrain FROM WP"
		$WpMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
		$FoundWpMatch = UBound($WpMatchArray) - 1
		If $FoundWpMatch <> 0 Then
			For $exp = 1 To $FoundWpMatch
				$ExpWPID = $WpMatchArray[$exp][1]
				$ExpName = _XMLSanitize($WpMatchArray[$exp][2])
				$ExpDesc = _XMLSanitize($WpMatchArray[$exp][3])
				$ExpNotes = _XMLSanitize($WpMatchArray[$exp][4])
				$ExpLat = StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($WpMatchArray[$exp][5]), 'S', '-'), 'N', ''), ' ', '')
				$ExpLon = StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($WpMatchArray[$exp][6]), 'W', '-'), 'E', ''), ' ', '')
				$ExpBrng = $WpMatchArray[$exp][7]
				$ExpDest = $WpMatchArray[$exp][8]
				$ExpLink = _XMLSanitize($WpMatchArray[$exp][9])
				$ExpAuth = _XMLSanitize($WpMatchArray[$exp][10])
				$ExpType = _XMLSanitize($WpMatchArray[$exp][11])
				$ExpDif = _XMLSanitize($WpMatchArray[$exp][12])
				$ExpTer = _XMLSanitize($WpMatchArray[$exp][13])


				If $ExpLat <> '0.0000000' And $ExpLon <> '-0.0000000' Then
					$file &= '	<wpt lat="' & $ExpLat & '" lon="' & $ExpLon & '">' & @CRLF
					If $ExpName <> "" Then $file &= '		<name>' & $ExpName & '</name>' & @CRLF
					If $ExpDesc <> "" Then $file &= '		<desc>' & $ExpDesc & ' by ' & $ExpAuth & ', ' & $ExpType & ' (' & $ExpDif & '/' & $ExpTer & ')</desc>' & @CRLF
					If $ExpLink <> "" Then $file &= '		<url>' & $ExpLink & '</url>' & @CRLF
					If $ExpDesc <> "" Then $file &= '		<urlname>' & $ExpDesc & '</urlname>' & @CRLF
					If $ExpNotes <> "" Then $file &= '		<Notes>' & $ExpNotes & '</Notes>' & @CRLF
					$file &= '	</wpt>' & @CRLF
				EndIf
			Next
		EndIf
	EndIf

	If $MapGpsTrack = 1 Then
		$query = "SELECT TRACKID, name, desc1, cmt, src, url, urlname, number1 FROM TRACK"
		ConsoleWrite($query & @CRLF)
		$TrackMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
		$FoundTrackMatch = UBound($TrackMatchArray) - 1
		If $FoundTrackMatch <> 0 Then
			For $trk = 1 To $FoundTrackMatch
				$ExpTrkID = $TrackMatchArray[$trk][1]
				$ExpTrkName = _XMLSanitize($TrackMatchArray[$trk][2])
				$ExpTrkDesc = _XMLSanitize($TrackMatchArray[$trk][3])
				$ExpTrkCmt = _XMLSanitize($TrackMatchArray[$trk][4])
				$ExpTrkSrc = _XMLSanitize($TrackMatchArray[$trk][5])
				$ExpTrkUrl = _XMLSanitize($TrackMatchArray[$trk][6])
				$ExpTrkUrlname = _XMLSanitize($TrackMatchArray[$trk][7])
				$ExpTrkNumber1 = _XMLSanitize($TrackMatchArray[$trk][8])
				$query = "SELECT lat, lon, ele, time1, magvar, course, geoidheight, fix, sat, hdop, vdop, pdop, ageofgpsdata, dgpsid, speed, name, cmt, desc1, src, url, urlname, sym, type FROM TRACKSEG WHERE lat <> 'N 0.0000' And lon <> 'E 0.0000' And TRACKID = '" & $ExpTrkID & "' ORDER BY TRACKSEGID"
				ConsoleWrite($query & @CRLF)
				$GpsMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
				$FoundGpsMatch = UBound($GpsMatchArray) - 1
				If $FoundGpsMatch <> 0 Then
					$file &= '	<trk>' & @CRLF
					If $ExpTrkName <> "" Then $file &= '		<name>' & $ExpTrkName & '</name>' & @CRLF
					If $ExpTrkDesc <> "" Then $file &= '		<desc>' & $ExpTrkDesc & '</desc>' & @CRLF
					If $ExpTrkCmt <> "" Then $file &= '		<cmt>' & $ExpTrkCmt & '</cmt>' & @CRLF
					If $ExpTrkSrc <> "" Then $file &= '		<src>' & $ExpTrkSrc & '</src>' & @CRLF
					If $ExpTrkUrl <> "" Then $file &= '		<url>' & $ExpTrkUrl & '</url>' & @CRLF
					If $ExpTrkUrlname <> "" Then $file &= '		<urlname>' & $ExpTrkUrlname & '</urlname>' & @CRLF
					If $ExpTrkNumber1 <> "" Then $file &= '		<number>' & $ExpTrkNumber1 & '</number>' & @CRLF

					$file &= '		<trkseg>' & @CRLF
					For $exp = 1 To $FoundGpsMatch
						$ExpLat = StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($GpsMatchArray[$exp][1]), 'S', '-'), 'N', ''), ' ', '')
						$ExpLon = StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($GpsMatchArray[$exp][2]), 'W', '-'), 'E', ''), ' ', '')
						$ExpEle = Round($GpsMatchArray[$exp][3])
						$ExpTime = $GpsMatchArray[$exp][4]
						$ExpMagvar = $GpsMatchArray[$exp][5]
						$ExpCorse = $GpsMatchArray[$exp][6]
						$ExpGeoidHeight = $GpsMatchArray[$exp][7]
						$ExpFix = $GpsMatchArray[$exp][8]
						$ExpSat = $GpsMatchArray[$exp][9]
						$ExpHdop = $GpsMatchArray[$exp][10]
						$ExpVdop = $GpsMatchArray[$exp][11]
						$ExpPdop = $GpsMatchArray[$exp][12]
						$ExpAgeOfGpsData = $GpsMatchArray[$exp][13]
						$ExpDgpsid = $GpsMatchArray[$exp][14]
						$ExpSpeed = $GpsMatchArray[$exp][15]
						$ExpName = $GpsMatchArray[$exp][16]
						$ExpCmt = $GpsMatchArray[$exp][17]
						$ExpDesc = $GpsMatchArray[$exp][18]
						$ExpSrc = $GpsMatchArray[$exp][19]
						$ExpUrl = $GpsMatchArray[$exp][20]
						$ExpUrlName = $GpsMatchArray[$exp][21]
						$ExpSym = $GpsMatchArray[$exp][22]
						$ExpType = $GpsMatchArray[$exp][23]

						If $ExpLat <> 'N 0.0000000' And $ExpLon <> 'E 0.0000000' Then
							$FoundApWithGps = 1
							$file &= '			<trkpt lat="' & $ExpLat & '" lon="' & $ExpLon & '">' & @CRLF
							If $ExpEle <> "" Then $file &= '				<ele>' & $ExpEle & '</ele>' & @CRLF
							If $ExpTime <> "" Then $file &= '				<time>' & $ExpTime & '</time>' & @CRLF
							If $ExpMagvar <> "" Then $file &= '				<magvar>' & $ExpMagvar & '</magvar>' & @CRLF
							If $ExpCorse <> "" Then $file &= '				<course>' & $ExpCorse & '</course>' & @CRLF
							If $ExpGeoidHeight <> "" Then $file &= '				<geoidheigh>' & $ExpGeoidHeight & '</geoidheigh>' & @CRLF
							If $ExpFix <> "" Then $file &= '				<fix>' & $ExpFix & '</fix>' & @CRLF
							If $ExpSat <> "" Then $file &= '				<sat>' & $ExpSat & '</sat>' & @CRLF
							If $ExpHdop <> "" Then $file &= '				<hdop>' & $ExpHdop & '</hdop>' & @CRLF
							If $ExpVdop <> "" Then $file &= '				<vdop>' & $ExpVdop & '</vdop>' & @CRLF
							If $ExpPdop <> "" Then $file &= '				<pdop>' & $ExpPdop & '</pdop>' & @CRLF
							If $ExpAgeOfGpsData <> "" Then $file &= '				<ageofdgpsdata>' & $ExpAgeOfGpsData & '</ageofdgpsdata>' & @CRLF
							If $ExpDgpsid <> "" Then $file &= '				<dgpsid>' & $ExpDgpsid & '</dgpsid>' & @CRLF
							If $ExpSpeed <> "" Then $file &= '				<speed>' & $ExpSpeed & '</speed>' & @CRLF
							If $ExpName <> "" Then $file &= '				<name>' & $ExpName & '</name>' & @CRLF
							If $ExpCmt <> "" Then $file &= '				<cmt>' & $ExpCmt & '</cmt>' & @CRLF
							If $ExpDesc <> "" Then $file &= '				<desc>' & $ExpDesc & '</desc>' & @CRLF
							If $ExpSrc <> "" Then $file &= '				<src>' & $ExpSrc & '</src>' & @CRLF
							If $ExpUrl <> "" Then $file &= '				<url>' & $ExpUrl & '</url>' & @CRLF
							If $ExpUrlName <> "" Then $file &= '				<urlname>' & $ExpUrlName & '</urlname>' & @CRLF
							If $ExpSym <> "" Then $file &= '				<sym>' & $ExpSym & '</sym>' & @CRLF
							If $ExpType <> "" Then $file &= '				<type>' & $ExpType & '</type>' & @CRLF
							$file &= '			</trkpt>' & @CRLF
						EndIf
					Next
					$file &= '		</trkseg>' & @CRLF _
							 & '	</trk>' & @CRLF
				EndIf
			Next
		EndIf
	EndIf
	$file &= '</gpx>' & @CRLF

	$gpx = FileOpen($gpx, 128 + 2);Open in UTF-8 write mode
	$filewrite = FileWrite($gpx, $file)
	FileClose($gpx)
	If $filewrite = 0 Then
		Return (0)
	Else
		Return (1)
	EndIf
EndFunc   ;==>_SaveGPX

;-->LOC
Func _ExportAllToLOC()
	$loc = FileSaveDialog("LOC Output File", $SaveDir, 'LOC (*.loc)', '', $ldatetimestamp & '.loc')
	If Not @error Then
		$saveloc = _SaveLOC($loc)
		If $saveloc = 1 Then
			MsgBox(0, 'Done', 'Saved As' & ': "' & $loc & '"')
		Else
			MsgBox(0, 'Error', 'Error saving file' & ': "' & $loc & '"')
		EndIf
	EndIf
EndFunc   ;==>_ExportAllToLOC

Func _SaveLOC($gpx, $MapGpsWpts = 1)
	$FoundApWithGps = 0
	If StringInStr($gpx, '.loc') = 0 Then $gpx = $gpx & '.loc'
	FileDelete($gpx)
	$file = '<?xml version="1.0" encoding="UTF-8" standalone="no" ?>' & @CRLF _
			 & '<loc version="1.0" src="' & $Script_Name & '">' & @CRLF
	If $MapGpsWpts = 1 Then
		$query = "SELECT WPID, Name, Desc1, Notes, Latitude, Longitude, Bearing, Distance, Link, Author, Type, Difficulty, Terrain FROM WP"
		$WpMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
		$FoundWpMatch = UBound($WpMatchArray) - 1
		If $FoundWpMatch <> 0 Then
			For $exp = 1 To $FoundWpMatch
				$ExpWPID = $WpMatchArray[$exp][1]
				$ExpName = $WpMatchArray[$exp][2]
				$ExpDesc = _XMLSanitize($WpMatchArray[$exp][3])
				$ExpNotes = _XMLSanitize($WpMatchArray[$exp][4])
				$ExpLat = StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($WpMatchArray[$exp][5]), 'S', '-'), 'N', ''), ' ', '')
				$ExpLon = StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($WpMatchArray[$exp][6]), 'W', '-'), 'E', ''), ' ', '')
				$ExpBrng = $WpMatchArray[$exp][7]
				$ExpDest = $WpMatchArray[$exp][8]
				$ExpLink = _XMLSanitize($WpMatchArray[$exp][9])
				$ExpAuth = $WpMatchArray[$exp][10]
				$ExpType = _XMLSanitize($WpMatchArray[$exp][11])
				$ExpDif = $WpMatchArray[$exp][12]
				$ExpTer = $WpMatchArray[$exp][13]

				If $ExpLat <> '0.0000000' And $ExpLon <> '-0.0000000' Then
					$file &= '	<waypoint>' & @CRLF _
							 & '		<name id="' & $ExpName & '"><![CDATA[' & $ExpDesc & ' by ' & $ExpAuth & ' (' & $ExpDif & '/' & $ExpTer & ')]]></name>' & @CRLF _
							 & '		<coord lat="' & $ExpLat & '" lon="' & $ExpLon & '"/>' & @CRLF _
							 & '		<type>Geocache</type>' & @CRLF _
							 & '		<link text="Waypoint Details">' & $ExpLink & '</link>' & @CRLF
					If $ExpName <> '' Then $file &= '		<urlname>' & _XMLSanitize($ExpDesc) & '</urlname>' & @CRLF
					If $ExpNotes <> '' Then $file &= '		<Notes>' & $ExpNotes & '</Notes>' & @CRLF
					If $ExpType <> '' Then $file &= '		<CacheType>' & $ExpType & '</CacheType>' & @CRLF
					$file &= '	</waypoint>' & @CRLF
				EndIf
			Next
		EndIf
	EndIf

	$file &= '</loc>' & @CRLF

	$filewrite = FileWrite($gpx, $file)
	If $filewrite = 0 Then
		Return (0)
	Else
		Return (1)
	EndIf
EndFunc   ;==>_SaveLOC

;-->CSV
Func _ExportCsvData();Saves data to a selected file
	_ExportCsvDataGui(0)
EndFunc   ;==>_ExportCsvData

Func _ExportCsvDataGui($Filter = 0);Saves data to a selected file
	$file = FileSaveDialog($Text_SaveAsTXT, $SaveDir, 'CSV (*.csv)', '', $ldatetimestamp & '.csv')
	If @error <> 1 Then
		If StringInStr($file, '.csv') = 0 Then $file = $file & '.csv'
		FileDelete($file)
		_ExportToCSV($file, $Filter)
		MsgBox(0, "Done", "Saved As" & ': "' & $file & '"')
		$newdata = 0
	EndIf
EndFunc   ;==>_ExportCsvDataGui

Func _ExportToCSV($savefile, $Filter = 0);writes vistumbler data to a txt file
	FileWriteLine($savefile, "Name, Desc, Notes, Start Latitude, Start Longitude, Waypoint Latitude, Waypoint Longitude, Bearing, Distance, Link")
	;If $Filter = 1 Then
	;	$query = $AddQuery
	;Else
	$query = "SELECT Name, Desc1, Notes, Latitude, Longitude, Bearing, Distance, Link FROM WP"
	;EndIf
	$WpMatchArray = _RecordSearch($MysticacheDB, $query, $DB_OBJ)
	$FoundWpMatch = UBound($WpMatchArray) - 1
	For $exp = 1 To $FoundWpMatch
		$ExpName = '"' & $WpMatchArray[$exp][1] & '"'
		$ExpDesc = '"' & $WpMatchArray[$exp][2] & '"'
		$ExpNotes = '"' & $WpMatchArray[$exp][3] & '"'
		$ExpStartLat = StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($StartLat), 'S', '-'), 'N', ''), ' ', '')
		$ExpStartLon = StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($StartLon), 'W', '-'), 'E', ''), ' ', '')
		$ExpLat = StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($WpMatchArray[$exp][4]), 'S', '-'), 'N', ''), ' ', '')
		$ExpLon = StringReplace(StringReplace(StringReplace(_Format_GPS_DMM_to_DDD($WpMatchArray[$exp][5]), 'W', '-'), 'E', ''), ' ', '')
		$ExpBrng = $WpMatchArray[$exp][6]
		$ExpDist = $WpMatchArray[$exp][7]
		$ExpLink = '"' & $WpMatchArray[$exp][8] & '"'

		FileWriteLine($savefile, $ExpName & ',' & $ExpDesc & ',' & $ExpNotes & ',' & $ExpStartLat & ',' & $ExpStartLon & ',' & $ExpLat & ',' & $ExpLon & ',' & $ExpBrng & ',' & $ExpDist & ',' & $ExpLink)
	Next
EndFunc   ;==>_ExportToCSV

;--> Other
Func _OpenSaveFolder();Opens save folder in explorer
	DirCreate($SaveDir)
	Run('RunDll32.exe url.dll,FileProtocolHandler "' & $SaveDir & '"')
EndFunc   ;==>_OpenSaveFolder

Func _XMLSanitize($return)
	$return = StringReplace($return, '&', '&amp;')
	$return = StringReplace($return, '<', '&lt;')
	$return = StringReplace($return, '>', '&gt;')
	Return ($return)
EndFunc   ;==>_XMLSanitize

;---------------------------------------------------------------------------------------
;Math Functions
;---------------------------------------------------------------------------------------

Func _deg2rad($Degree) ;convert degrees to radians
	Local $PI = 3.14159265358979
	$Degree = StringReplace(StringReplace(StringReplace(StringReplace(StringReplace($Degree, 'W', '-'), 'E', ''), 'S', '-'), 'N', ''), ' ', '')
	Return ($Degree * ($PI / 180))
EndFunc   ;==>_deg2rad

Func _rad2deg($radian) ;convert radians to degrees
	Local $PI = 3.14159265358979
	Return ($radian * (180 / $PI))
EndFunc   ;==>_rad2deg

Func _ATan2($X, $y) ;ATan2 function, since autoit only has ATan
	Local Const $PI = 3.14159265358979
	If $y < 0 Then
		Return -_ATan2($X, -$y)
	ElseIf $X < 0 Then
		Return $PI - ATan(-$y / $X)
	ElseIf $X > 0 Then
		Return ATan($y / $X)
	ElseIf $y <> 0 Then
		Return $PI / 2
	Else
		SetError(1)
	EndIf
EndFunc   ;==>_ATan2

Func _MetersToFeet($meters)
	$feet = $meters / 3.28
	Return ($feet)
EndFunc   ;==>_MetersToFeet

;---------------------------------------------------------------------------------------
;Other Functions
;---------------------------------------------------------------------------------------

Func _CleanupFiles($cDIR, $cTYPE)
	$Tmpfiles = _FileListToArray($cDIR, $cTYPE, 1);Find all files in the folder that end in .tmp
	If IsArray($Tmpfiles) Then
		For $FoundTmp = 1 To $Tmpfiles[0]
			$tmpname = $TmpDir & $Tmpfiles[$FoundTmp]
			If _FileInUse($tmpname) = 0 Then FileDelete($tmpname)
		Next
	EndIf
EndFunc   ;==>_CleanupFiles