{* UltraStar Deluxe - Karaoke Game
 *
 * UltraStar Deluxe is the legal property of its developers, whose names
 * are too numerous to list here. Please refer to the COPYRIGHT
 * file distributed with this source distribution.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING. If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 * $URL: https://ultrastardx.svn.sourceforge.net/svnroot/ultrastardx/trunk/src/base/UPlaylist.pas $
 * $Id: $
 *}

unit USoundfont;

interface

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$I switches.inc}

uses
  Classes,
  bass,
  bassmidi,
  UIni,
  USong,
  UPath,
  UPathUtils;

type

  TSoundfont = record
    Name:     string;
    Filename: IPath;
  end;

  ASoundfont = array of TSoundfont;

  //----------
  //TSoundfontManager - Class for Managing Soundfonts
  //----------
  TSoundfontManager = class
    private

    public
      CurSoundfont:  Cardinal;
      fSoundfont  : HSOUNDFONT;
      Soundfonts:    ASoundfont;

      constructor Create;
      procedure   LoadSoundfonts;
      function    LoadSoundfont(Index: Cardinal; const Filename: IPath): Boolean;

      procedure   SetSoundfont(Index: Cardinal; fStream: HSTREAM);
      procedure   SetIniSoundfont();
   end;

var
  SoundFontMan:  TSoundFontManager;


implementation

uses
  SysUtils,
  USongs,
  ULog,
  UMain,
  UFilesystem,
  UGraphic,
  UThemes,
  UUnicodeUtils;

//----------
//Create - Construct Class - Dummy for now
//----------
constructor TSoundFontManager.Create;
begin
  inherited;
  LoadSoundfonts;
end;

//----------
//Loadsoundfonts - Load list of Soundfonts from Soundfont Folder
//----------
Procedure   TSoundFontManager.LoadSoundfonts;
var
  Len:  Integer;
  SoundFontsBuffer: TSoundfont;
  Iter: IFileIterator;
  FileInfo: TFileInfo;
begin
  SetLength(Soundfonts, 0);

  Iter := FileSystem.FileFind(SoundFontsPath.Append('*.sf2'), 0);
  while (Iter.HasNext) do
  begin
    Len := Length(Soundfonts);
    SetLength(Soundfonts, Len + 1);

    FileInfo := Iter.Next;

    if not LoadSoundfont(Len, FileInfo.Name) then
      SetLength(Soundfonts, Len)
    else
    begin
      // Sort the Soundfonts - Insertion Sort
      SoundfontsBuffer := Soundfonts[Len];
      Dec(Len);
      while (Len >= 0) AND (CompareText(Soundfonts[Len].Name, SoundfontsBuffer.Name) >= 0) do
      begin
          Soundfonts[Len+1] := Soundfonts[Len];
          Dec(Len);
      end;
      Soundfonts[Len+1] := SoundfontsBuffer;
    end;
  end;
end;

//----------
//LoadSoundfont - Load a Soundfont in the Array
//----------
function TSoundFontManager.LoadSoundfont(Index: Cardinal; const Filename: IPath): Boolean;
var
  FilenameAbs: IPath;
  NewSoundfont: BASS_MIDI_FONT;
  FontInfo: BASS_MIDI_FONTINFO;
begin

  //Load File
  try
    FilenameAbs := SoundFontsPath.Append(Filename);
    NewSoundfont.font := BASS_MIDI_FontInit(PChar(FilenameAbs.ToNative), 0);  // open new soundfont
 	  fSoundfont := NewSoundfont.font;

  except
    begin
      Log.LogError('Could not load Soundfont: ' + FilenameAbs.ToNative);
      Result := False;
      Exit;
    end;
  end;
  Result := True;

  //Set Filename
  BASS_MIDI_FontGetInfo(fSoundfont, FontInfo);
  Soundfonts[Index].Filename := Filename;
  Soundfonts[Index].Name := FontInfo.name;

end;

procedure TSoundFontManager.SetSoundfont(Index: Cardinal; fStream: HSTREAM);
var
  I: Integer;
  NewSoundfont: BASS_MIDI_FONT;
begin
  if (Int(Index) > High(Soundfonts)) then
    exit;

  NewSoundfont.font := BASS_MIDI_FontInit(PChar(SoundFontsPath.Append(SoundFonts[Index].Filename).ToNative), 0);  // open new soundfont

  if (NewSoundfont.font <> 0) and (NewSoundfont.font <> fSoundfont) then begin
    NewSoundfont.preset := -1;                                  // use all presets
 	  NewSoundfont.bank   := 0;                                   // use default bank(s)
    BASS_MIDI_FontFree(fSoundfont);                             // free old soundfont
 	  BASS_MIDI_StreamSetFonts(0, NewSoundfont, 1);               // set default soundfont
    BASS_MIDI_StreamSetFonts(fStream, NewSoundfont, 1);         // set for current stream too
    fSoundfont          := NewSoundfont.font;
  end;

end;

procedure TSoundFontManager.SetIniSoundfont();
var
  I: Integer;
  Exist: boolean;
begin
  Exist := false;

  for I := 0 to High(Soundfonts) do
  begin
    if (Soundfonts[I].Name = Ini.SoundFont) then
    begin
      CurSoundfont := I;
      SetSoundfont(I, 0);
      Exist := true;
    end;
  end;

  if not (Exist) then
    SetSoundfont(0, 0);
end;

//----------

end.