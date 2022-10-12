%% Autoren: Dipl.-Ing. Daniel Kranz (DK), 13.07.2020, fortgeführt durch  Dipl.-Ing. Simon Röschner (SR), 26.02.2021
% Technische Universität Dresden
% Fakultät Elektrotechnik und Informationstechnik
% Elektrotechnisches Institut
% Professur Elektrische Maschinen und Antriebe

%% Beschreibung
% Funktion zur Bearbeitung der Datasets der Strangströme in Maxwell
% editiert. Die Ströme müssen dafür in MATLAB als Struktur vorliegen,
% was bspw. nach Ausführung von fcnCalcStromVerlauf.m der Fall ist. 

%% Eingangsgrößen
% oDesign   : Design-Objekt (in scrInitMaxwell.m erzeugt und generell über die gesamte Programmlaufzeit unverändert.)
% grcExport : Datenstruktur für theoretisch ermittelte Strangströme

%% Ausgangsgrößen
% 

%% Change-Log %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Datum %%%%%%% Kürzel %% Änderungen %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2021-02-26 %% SR     %% Header, Variablen(namen) angepasst, Anpassen der
%            %%        %% Datenstrukur.
% ---------- %% ------ %% --------------------------------------------------

function [] = mwEditCurrentDatasets(oDesign, grcExport)
%% Initisalisierung
rgkdT    = grcExport.grcVerlauf.rgkdT;                                     % Zeitvektor in [s]
rgkdIstr = grcExport.grcVerlauf.rgkdIstr;                                  % Strangstromverläufe in [A], Phase U, V, W
rgsDatasetName = [ % Siehe Dataset Properties in Maxwell, Datasets müssen im Design bereits angelegt sein
    "rgkdIu";
    "rgkdIv";
    "rgkdIw";
    ];

%% Umwandeln der Matrizen in Cell Arrays
rgcMaxwellInput = cell(3,length(rgkdT)+1); % Zeile = Strang, Spalte = Zeitschritt + ein weiteres Element: erste Zelle enthält immer 'NAME:Coordinates'
for ziPhase = 1:size(rgcMaxwellInput,1)
    rgcMaxwellInput{ziPhase,1} = 'NAME:Coordinates';

%% Zusammensetzen des Cell Arrays und Einsetzen der Stromverläufe
    for ziTstep = 1:length(rgkdT)
        rgcMaxwellInput{ziPhase,ziTstep+1} = {'NAME:Coordinate',... % (Maxwell benötigt diese Formatierung)
            'X:=', rgkdT(ziTstep),...
            'Y:=', rgkdIstr(ziPhase,ziTstep)};
    end
    
%% Übergeben der Stromvektoren an Maxwell
    invoke(oDesign, 'EditDataset', rgsDatasetName(ziPhase,1), {sprintf('NAME:%s',rgsDatasetName(ziPhase,1)), rgcMaxwellInput(ziPhase,:)});
    
end

end

