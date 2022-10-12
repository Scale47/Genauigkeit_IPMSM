%% Autoren: Dipl.-Ing. Daniel Kranz (DK), 13.07.2020, fortgef�hrt durch  Dipl.-Ing. Simon R�schner (SR), 26.02.2021
% Technische Universit�t Dresden
% Fakult�t Elektrotechnik und Informationstechnik
% Elektrotechnisches Institut
% Professur Elektrische Maschinen und Antriebe

%% Beschreibung
% Funktion zur Bearbeitung der Datasets der Strangstr�me in Maxwell
% editiert. Die Str�me m�ssen daf�r in MATLAB als Struktur vorliegen,
% was bspw. nach Ausf�hrung von fcnCalcStromVerlauf.m der Fall ist. 

%% Eingangsgr��en
% oDesign   : Design-Objekt (in scrInitMaxwell.m erzeugt und generell �ber die gesamte Programmlaufzeit unver�ndert.)
% grcExport : Datenstruktur f�r theoretisch ermittelte Strangstr�me

%% Ausgangsgr��en
% 

%% Change-Log %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Datum %%%%%%% K�rzel %% �nderungen %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2021-02-26 %% SR     %% Header, Variablen(namen) angepasst, Anpassen der
%            %%        %% Datenstrukur.
% ---------- %% ------ %% --------------------------------------------------

function [] = mwEditCurrentDatasets(oDesign, grcExport)
%% Initisalisierung
rgkdT    = grcExport.grcVerlauf.rgkdT;                                     % Zeitvektor in [s]
rgkdIstr = grcExport.grcVerlauf.rgkdIstr;                                  % Strangstromverl�ufe in [A], Phase U, V, W
rgsDatasetName = [ % Siehe Dataset Properties in Maxwell, Datasets m�ssen im Design bereits angelegt sein
    "rgkdIu";
    "rgkdIv";
    "rgkdIw";
    ];

%% Umwandeln der Matrizen in Cell Arrays
rgcMaxwellInput = cell(3,length(rgkdT)+1); % Zeile = Strang, Spalte = Zeitschritt + ein weiteres Element: erste Zelle enth�lt immer 'NAME:Coordinates'
for ziPhase = 1:size(rgcMaxwellInput,1)
    rgcMaxwellInput{ziPhase,1} = 'NAME:Coordinates';

%% Zusammensetzen des Cell Arrays und Einsetzen der Stromverl�ufe
    for ziTstep = 1:length(rgkdT)
        rgcMaxwellInput{ziPhase,ziTstep+1} = {'NAME:Coordinate',... % (Maxwell ben�tigt diese Formatierung)
            'X:=', rgkdT(ziTstep),...
            'Y:=', rgkdIstr(ziPhase,ziTstep)};
    end
    
%% �bergeben der Stromvektoren an Maxwell
    invoke(oDesign, 'EditDataset', rgsDatasetName(ziPhase,1), {sprintf('NAME:%s',rgsDatasetName(ziPhase,1)), rgcMaxwellInput(ziPhase,:)});
    
end

end

