%% Autor: Dipl.-Ing. Simon R�schner (SR), 22.04.2022
% Technische Universit�t Dresden
% Fakult�t Elektrotechnik und Informationstechnik
% Elektrotechnisches Institut
% Professur Elektrische Maschinen und Antriebe

%% Beschreibung
% Diese Funktion wird verwendet, um ProjektVariablen in Maxwell zu �ndern

%% Eingangsgr��en
% oProject:  Projekt-Objekt (in initMaxwell.m erzeugt und generell �ber die gesamte Programmlaufzeit unver�ndert.)
% sName:    Name der Design-Variable in Maxwell
% kdValue:  Neuer Zahlenwert der Variable
% sUnit:    Ggf. Einheit der Gr��e. '', falls einheitenlos

%% Ausgangsgr��en
% 

%% Change-Log %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Datum %%%%%%% K�rzel %% �nderungen %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ---------- %% ------ %% --------------------------------------------------

function [] = mwChangeProjectVariable(oProject, sName, kdValue, sUnit)
    %% Vorbehandlung
    sValue = [num2str(kdValue, 16), sUnit]; % Die Darstellungspr�zision wird hier festgelegt, was die Funktion robuster macht. Einheit ist eine Zeichenkette
    if ~startsWith(sName,'$') % $ hinzuf�gen
        sName = frpintf('$%s',sName);
    end
    
    %% Ver�nderung ausl�sen
    invoke(oProject, 'ChangeProperty', {'NAME:AllTabs',...
        {'NAME:ProjectVariableTab', {'NAME:PropServers', 'ProjectVariables'},...
        {'NAME:ChangedProps', {['NAME:', sName], 'Value:=', sValue}}}});
end