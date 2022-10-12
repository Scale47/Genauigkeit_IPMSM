%% Autoren: Dipl.-Ing. Daniel Kranz (DK), 13.07.2020 , fortgef�hrt durch  Dipl.-Ing. Simon R�schner (SR), 23.02.2021
% Technische Universit�t Dresden
% Fakult�t Elektrotechnik und Informationstechnik
% Elektrotechnisches Institut
% Professur Elektrische Maschinen und Antriebe

%% Beschreibung
% Funktion zur Bestimmung des Strangwiderstandes der Maschine. Empirische
% Berechnung auf Grundlage von Simulationsdaten aus dem werten Hause ZF    

%% Eingangsgr��en
% kdF :      Frequenz, zu der der Strangwiderstand bestimmt werden soll
% (sModel) : Modell zur Strangwiderstandberechnung
%   'quad' : Quadratische Regression
%   'exp'  : Exponentialansatz
%   '0'    : Vernachl�ssigung

%% Ausgangsgr��en
% kdRstr : Frequenzabh�ngiger Strangwiderstand

%% Change-Log %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Datum %%%%%%% K�rzel %% �nderungen %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2021-02-23 %% SR     %% aus "r_str" (DK) -> "fcnInterpolRstr.m",
%            %%        %% Header, Variablen(namen) angepasst.
%            %%        %% sModel als Parameter zur Festlegung des
%            %%        %% Berechnungsmodells hinzugef�gt.
% ---------- %% ------ %% --------------------------------------------------

function [kdRstr] = fcnInterpolRstr(kdF,sModel)
%% Initialisierung:
if nargin < 2
    sModel = 'quad'; % mit quadratischer Regression rechnen
end
kdOmega = kdF * 2*pi; % Kreisfrequenz

%% Berechnung des Strangwiderstandes in Abh�ngigkeit der Frequenz
if strcmp(sModel, 'quad')
    kdRstr = 2.354e-10 * kdOmega^2 + 1.273e-8 * kdOmega + 0.009457; % Quadratische Regression: kdRstr = a * kdOmega^2 + b * kdOmega + c
elseif strcmp(sModel, 'exp')
    kdRstr = 0.001813 * exp(0.0002974 * kdOmega) + 0.007268; % Ausgleichsrechnung mit Exponentialfunktion: kdRstr = a * exp(b * kdOmega) + c
elseif strcmp(sModel, '0')
    kdRstr = 0; % Gleich Null (Dummy-Fall, falls Strangwiderstand vernachl�ssigt wird)
else
    error('''%s'' ist kein bekanntes Berechnungsmodell. M�gliche Modelle: ''quad'', ''exp'', ''0''.', sModel)
end

end