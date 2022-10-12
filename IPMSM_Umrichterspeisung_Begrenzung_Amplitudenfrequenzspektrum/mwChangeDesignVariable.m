%% Autoren: Dipl.-Ing. Daniel Kranz (DK), 13.07.2020, fortgef�hrt durch  Dipl.-Ing. Simon R�schner (SR), 08.02.2021
% Technische Universit�t Dresden
% Fakult�t Elektrotechnik und Informationstechnik
% Elektrotechnisches Institut
% Professur Elektrische Maschinen und Antriebe

%% Beschreibung
% Diese Funktion wird verwendet, um DesignVariablen in Maxwell zu �ndern

%% Eingangsgr��en
% oDesign:  Design-Objekt (in initMaxwell.m erzeugt und generell �ber die gesamte Programmlaufzeit unver�ndert.)
% sName:    Name der Design-Variable in Maxwell
% kdValue:  Neuer Zahlenwert der Variable
% sUnit:    Ggf. Einheit der Gr��e. '', falls einheitenlos

%% Ausgangsgr��en
% 

%% Change-Log %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Datum %%%%%%% K�rzel %% �nderungen %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2021-02-08 %% SR     %% Header, Variablen(namen) angepasst
% ---------- %% ------ %% --------------------------------------------------

function [] = mwChangeDesignVariable(oDesign, sName, kdValue, sUnit)
    %% Vorbehandlung
    sValue = [num2str(kdValue, 16), sUnit]; % Die Darstellungspr�zision wird hier festgelegt, was die Funktion robuster macht. Einheit ist eine Zeichenkette
    
    %% Ver�nderung ausl�sen
    invoke(oDesign, 'ChangeProperty', {'NAME:AllTabs',...
        {'NAME:LocalVariableTab', {'NAME:PropServers', 'LocalVariables'},...
        {'NAME:ChangedProps', {['NAME:', sName], 'Value:=', sValue}}}});
end