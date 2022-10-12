%% Autoren: Dipl.-Ing. Daniel Kranz (DK), 13.07.2020, fortgeführt durch  Dipl.-Ing. Simon Röschner (SR), 08.02.2021
% Technische Universität Dresden
% Fakultät Elektrotechnik und Informationstechnik
% Elektrotechnisches Institut
% Professur Elektrische Maschinen und Antriebe

%% Beschreibung
% Diese Funktion wird verwendet, um DesignVariablen in Maxwell zu ändern

%% Eingangsgrößen
% oDesign:  Design-Objekt (in initMaxwell.m erzeugt und generell über die gesamte Programmlaufzeit unverändert.)
% sName:    Name der Design-Variable in Maxwell
% kdValue:  Neuer Zahlenwert der Variable
% sUnit:    Ggf. Einheit der Größe. '', falls einheitenlos

%% Ausgangsgrößen
% 

%% Change-Log %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Datum %%%%%%% Kürzel %% Änderungen %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2021-02-08 %% SR     %% Header, Variablen(namen) angepasst
% ---------- %% ------ %% --------------------------------------------------

function [] = mwChangeDesignVariable(oDesign, sName, kdValue, sUnit)
    %% Vorbehandlung
    sValue = [num2str(kdValue, 16), sUnit]; % Die Darstellungspräzision wird hier festgelegt, was die Funktion robuster macht. Einheit ist eine Zeichenkette
    
    %% Veränderung auslösen
    invoke(oDesign, 'ChangeProperty', {'NAME:AllTabs',...
        {'NAME:LocalVariableTab', {'NAME:PropServers', 'LocalVariables'},...
        {'NAME:ChangedProps', {['NAME:', sName], 'Value:=', sValue}}}});
end