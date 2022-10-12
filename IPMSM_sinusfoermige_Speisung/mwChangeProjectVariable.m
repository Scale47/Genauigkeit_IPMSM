%% Autor: Dipl.-Ing. Simon Röschner (SR), 22.04.2022
% Technische Universität Dresden
% Fakultät Elektrotechnik und Informationstechnik
% Elektrotechnisches Institut
% Professur Elektrische Maschinen und Antriebe

%% Beschreibung
% Diese Funktion wird verwendet, um ProjektVariablen in Maxwell zu ändern

%% Eingangsgrößen
% oProject:  Projekt-Objekt (in initMaxwell.m erzeugt und generell über die gesamte Programmlaufzeit unverändert.)
% sName:    Name der Design-Variable in Maxwell
% kdValue:  Neuer Zahlenwert der Variable
% sUnit:    Ggf. Einheit der Größe. '', falls einheitenlos

%% Ausgangsgrößen
% 

%% Change-Log %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Datum %%%%%%% Kürzel %% Änderungen %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ---------- %% ------ %% --------------------------------------------------

function [] = mwChangeProjectVariable(oProject, sName, kdValue, sUnit)
    %% Vorbehandlung
    sValue = [num2str(kdValue, 16), sUnit]; % Die Darstellungspräzision wird hier festgelegt, was die Funktion robuster macht. Einheit ist eine Zeichenkette
    if ~startsWith(sName,'$') % $ hinzufügen
        sName = frpintf('$%s',sName);
    end
    
    %% Veränderung auslösen
    invoke(oProject, 'ChangeProperty', {'NAME:AllTabs',...
        {'NAME:ProjectVariableTab', {'NAME:PropServers', 'ProjectVariables'},...
        {'NAME:ChangedProps', {['NAME:', sName], 'Value:=', sValue}}}});
end