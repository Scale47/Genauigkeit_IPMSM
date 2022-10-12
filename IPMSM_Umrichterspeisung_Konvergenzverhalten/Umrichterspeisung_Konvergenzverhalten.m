%% Dipl.-Ing. Simon Röschner (SR), 22.08.2022
%% Christoph Scale (CS), 03.09.2022
% Technische Universität Dresden
% Fakultät Elektrotechnik und Informationstechnik
% Elektrotechnisches Institut
% Professur Elektrische Maschinen und Antriebe

%% Beschreibung
% Skript zur automatisierten Bestimmung von Induktivitäten und Magnetverlusten (SR)/ Filterung des betrachteten Spektrums für verschiedene NoSegm/ Arbeitspunkte (CS) 
% es wird eine Kaskadierung von for-Schleifen verwendet die wie folgt aufgebaut ist:
%       1. for-Schleife: zur Variation der Arbeitspunkte
%       2. for-Schleife: zur Variation der NoSegm
%       3. for-Schleife zur stückweisen Begrenzung des Stromspektrums
%% Change-Log %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Datum %%%%%%% Kürzel %% Änderungen %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2022-08-22 %% SR     %% erstellt
% ---------- %% ------ %% --------------------------------------------------
% 2022-08-23 %% SR     %% Aliasing Fehler im Erstellen der 
%            %% SR     %% Spannungsfunktion behoben
% ---------- %% ------ %% --------------------------------------------------
% 2022-09-02 %% SR     %% Fehler bei Berechnung der Ersatzinduktivität
%            %% SR     %% behoben
% ---------- %% ------ %% --------------------------------------------------
% 2022-09-04 %% CS     %% Fehler bei Übergabe des Spektrums von Psi0 
%            %% CS     %% und I0 behoben (Verwendung von Tabellen in Ansys) 
% ---------- %% ------ %% --------------------------------------------------
%% Warnungen in Kommandozeile ausschalten
w = warning ('off','all');
%% Working Directory anpassen
sActiveFilename = matlab.desktop.editor.getActiveFilename; % Dateipfad dieses Skripts
sMainPath = fileparts(sActiveFilename); % Ordnerpfad zu diesem Skript
cd(sMainPath); % Working Directory wechseln

%% System-Parameter initialisieren
sProject     = 'IPMSMs';
sLossDesign  = '010_Feinmodell_PPE';

%% bereinigt den Ordner IPMSMs.aedtresults
%oDesign.DeleteFullVariation("All", false);

%% Festlegung der Anzahl der zu untersuchenden Arbeitspunkte
% in Abhängigkeit dieser Variable wird ein Index definiert um innerhalb der Tabelle APe.xlsx dann auf die benötigten Parameter zuzugreifen 
Anzahl_AP = 5;
% 1. for-Schleife um die Arbeitspunktparameter festzulegen
for index_AP = 1:Anzahl_AP
    
% definieren eines Strings in Abhängigkeit des index_AP um den Workspace passend zum AP abzuspeichern 
index_AP_str = num2str(index_AP);

% Festlegung des gewünschten Formats zur Datumsangabe
formatOut = "mm_dd_yy";
% definieren einer Variable um den Workspace mit dem passendem Datum zu beschriften
d = datestr(now,formatOut);
% umwandeln der Datumsangabe in einen String um diese in der Bezeihnung des Workspace verwenden zu können
d_str = num2str(d);

%% Maschinenparameter
grcParam.grcMaschine.ziPp           = 4;                                   % Polpaarzahl
grcParam.grcMaschine.ziN            = 72;                                  % Nutzahl
grcParam.grcMaschine.ziM            = 3;                                   % Phasenzahl
grcParam.grcMaschine.bStern         = true;                                % ist in Stern geschaltet
grcParam.grcMaschine.grcPM.kdBreite = 15e-3;                               % Magnetbreite in [m]
grcParam.grcMaschine.grcPM.kdHoehe  = 3.8e-3;                              % Magnethöhe in [m]
grcParam.grcMaschine.grcPM.kdLaenge = 6.4e-3;                              % Axiale Magnetlänge in [m]
grcParam.grcMaschine.grcPM.kdKappa  = 620e3;                               % Elektrische Leitfähigkeit der Magnete in [S/m]
grcParam.grcMaschine.grcPM.kdMu     = 4*pi*1e-7 * 1.0503;                  % Permeabilität des Magneten in [Vs/Am]
grcParam.grcMaschine.zdGammaOffset  = 150;                                 % Verdrehen der Maschine zur Ausrichtung im dq-Koordinatensystem in [°], Version 18.2: 210

%% Definition von Zählern für die Arbeitspunktstabelle APe.xlsx um die jeweiligen Spalten der Tabelle zuzuordnen
Zaehler_n = 2;
Zaehler_Id_str = 3;
Zaehler_Iq_str = 4;
Zaehler_L_WK = 5;
Zaehler_R_str = 6;
Zaehler_U_P = 7;
Zaehler_L_d = 8;
Zaehler_L_q = 9;

%% Importieren der verschiedenen Parameter in einem Arbeitspunkt aus der Tabelle  
% einlesen der Tabelle
T = readtable("APe.xlsx");
% umwandeln der Tabelle in ein "cell array"
C = table2cell(T);
% zugreifen auf die verschiedenen Parameter innerhalb des "cell array" und hinterlegen in einer Variable
n = C{index_AP,Zaehler_n};
Id_str = C{index_AP,Zaehler_Id_str};
Iq_str = C{index_AP,Zaehler_Iq_str};
L_WK = C{index_AP,Zaehler_L_WK};
R_str = C{index_AP,Zaehler_R_str};
U_P = C{index_AP,Zaehler_U_P};
L_d = C{index_AP,Zaehler_L_d};
L_q = C{index_AP,Zaehler_L_q};

%% Arbeitspunkt (Parameter aus Tabelle)
grcAP.rgkdNn    = n;
grcAP.rgkdIdstr = Id_str;                                                   % d-Strom in [A]
grcAP.rgkdIqstr = Iq_str;                                                   % q-Strom in [A]
grcAP.rgkdLWK   = L_WK;                                                     % Wickelkopfinduktivität in [H], aus Spalte RSPK*Ideff (R_SPK = Widerstand(?) Spulenkopf?)
grcAP.rgkdRstr  = R_str;                                                    % Strangwiderstand in [Ohm]
grcAP.rgkdUp    = U_P;                                                      % Polradspannung in [V]
grcAP.rgkdFfel  = grcAP.rgkdNn .* (grcParam.grcMaschine.ziPp/60);           % Elektrische Grundschwingungsfrequenz in [Hz]
grcAP.rgkdIrms  = sqrt(grcAP.rgkdIdstr.^2 + grcAP.rgkdIqstr.^2)./sqrt(2);   % Effektiv-Strangstroms in [A]
grcAP.rgzdTheta = atan2(grcAP.rgkdIqstr, grcAP.rgkdIdstr) * 180/pi;         % Stromwinkel in der d-q-Ebene aus gegebenen Komponenten in [°]
grcAP.ziAPs     = length(grcAP.rgkdNn);
grcAP.rgkdLd    = L_d;                                                      % Längsinduktivität in [H]
grcAP.rgkdLq    = L_q;                                                      % Querinduktivität in [H]
grcAP.rgkdL2    = nan(1,grcAP.ziAPs);                                       % Inversinduktivität in [H], muss noch ermittelt werden.

%% Umrichterparameter (zuletzt)
grcParam.grcFU.kdUzk                = 550;                                  % Zwischenkreisspannung in [V]
grcParam.grcFU.zdPhiUum             = 0;                                    % Phasenverschiebung Leiter-Mittelpunktspannung in [rad], Phase U
grcParam.grcFU.kdFfc                = 10e3;                                 % Schaltfrequenz des Umrichters in [Hz]
grcParam.grcFU.ziKk                 = 10;                                   % Anzahl der zu betrachtenden Trägerbänder
grcParam.grcFU.ziLmax               = 4;                                    % Maximale Anzahl betrachteter Seitenbänder pro Trägerband

%% Start von Maxwell (Zugriff auf Ansys Maxwell)
% Grab Ansys Electronics Application, Ansys Fenster öffnet sich
oAnsoftApp          = actxserver('Ansoft.ElectronicsDesktop');              
oDesktop            = oAnsoftApp.GetAppDesktop(); 
oDesktop.RestoreWindow;                
% schnappt sich aktuelles Fenster
oDesktop   = oAnsoftApp.GetAppDesktop(); oDesktop.RestoreWindow; 
% schnappt sich aktuelles Fenster
try
    % schon offen, switchen
    oProject = oDesktop.SetActiveProject(sProject);                         
catch
    % öffnen des Projektes
    oProject = oDesktop.OpenProject(fullfile(sMainPath,sprintf('%s.aedt',sProject)));  
end
% aktives Design festlegen (im Reiter DetaildesignSkript)
oDesign             = oProject.SetActiveDesign(sLossDesign); 
% 3D-Modelierer als aktiver Editor
oEditor             = oDesign.SetActiveEditor('3D Modeler');                

%% Simulationsparameter für die Induktivitätsbestimmung
ziAP = 1;
grcParam.grcGetL2.ziNu            = 20;                                                                 % Eingeprägte Oberschwingungsordnung für die Ermittlung der Invers-Reaktanz / - Induktivität
grcParam.grcGetL2.zdTeilPeriode   = 1;                                                                  % Anteil einer ganzen elektrischen Periode (Induktivitäten), Ggf. Reduzierung der Simulation auf weniger als eine el. Periode (<=1)
grcParam.grcGetL2.ziSegmente      = 360;                                                                % Anzahl der Simulationsschritte (für Induktivitäten), Ohne Zusatzschritt durch gleichen Ausgangs- wie Endzustand
grcParam.grcGetL2.kdInu           = 5;                                                                  % Amplitude des injizierten Signals zur Bestimmung der differentiellen Induktivität in [A]
grcParam.grcGetL2.zdKnu           = grcParam.grcGetL2.ziNu / grcParam.grcGetL2.zdTeilPeriode;           % Sollte durch den Kehrwert des zdTeilPeriode teilbar sein, sorgt dafür, dass bei Verkürzung der betrachteten Persodendauer, die gesuchte OS immer genauso viele Perioden hat, wie durch ihre Ordnung angegeben.
grcParam.grcGetL2.kdFnu           = grcParam.grcGetL2.zdKnu * grcAP.rgkdFfel(ziAP);                     % Frequenz des für die Induktivitätsbestimmung überlagerten Signals in [Hz]
grcParam.grcGetL2.ziSchritte      = 2*grcParam.grcGetL2.ziSegmente * grcParam.grcGetL2.zdTeilPeriode;   % Induktivitätsbestimmung: Anzahl der Segmente pro Pol, die die Luftspalttrennlinie besitzen muss, um mit den eingestellten Simulationsparametern das Clicking Mesh sicherzustellen, Verfeinerung über zdTeilPeriodeL2 möglich

%% Definition aller Variablen und Funktionen für die Berechnung des Referenzwertes
%Erstellen eines "cell arrays" für die Daten des Simulationszeiten
Simulationszeit_Cell_1026 = cell(1,1);
%Erstellen eines "cell arrays" für die Daten der Wirbelstromverluste
Wirbelstromverluste_gesamt_Cell_1026 = cell(1,1);
%Erstellen eines "cell arrays" für die Daten der Wirbelstromverluste (Mittelwert)
Wirbelstromverluste_Mittelwert_Cell_1026 = cell(1,1);

%% Definition aller Variablen und Funktionen für die Variation der NoS
%Anzahl der Simulationen durch Vorgabe der Anzahl von for-Durchläufen
Anzahl_Simulationen = 8;
%Definition um wie viel sich die NoS pro Iteration erhöhen
Erhoehung_NoS_pro_Schritt = 90;
%Definition bei welchem Wert die 1. Iteration starten soll
Start_NoS = 360;
%Erstellen einer temporären "table" für die Daten der Simulationen
temporaer_table = table();
%Erstellen eines "cell arrays" für die Daten des Simulationszeiten
Simulationszeit_Cell = cell(1,10);
%Erstellen eines "cell arrays" für die Daten der Wirbelstromverluste
Wirbelstromverluste_gesamt_Cell = cell(1,10);
%Erstellen eines "cell arrays" für die Daten der Wirbelstromverluste
Wirbelstromverluste_Mittelwert_Cell = cell(1,10);
%Erstellen eines "cell arrays" für die Daten der Wirbelstromverluste
Prozentuale_Abweichung_Simulation_Cell = cell(1,10);
%Erstellen eines "cell arrays" für die Daten des THD
THD_Cell = cell(1,10);

%% Designvariablen setzen
mwChangeDesignVariable(oDesign, 'NoSegm', grcParam.grcGetL2.ziSegmente, '');
mwChangeDesignVariable(oDesign, 'kdFnu', grcParam.grcGetL2.kdFnu, 'Hz');
mwChangeDesignVariable(oDesign, 'kdInu', grcParam.grcGetL2.kdInu, 'A');
mwChangeDesignVariable(oDesign, 'frq_el', grcAP.rgkdFfel(ziAP), 'Hz');
mwChangeDesignVariable(oDesign, 'I_rms', grcAP.rgkdIrms(ziAP), 'A');
mwChangeDesignVariable(oDesign, 'zdTheta', grcAP.rgzdTheta(ziAP), 'deg');
mwChangeDesignVariable(oDesign, 'NoElP', grcParam.grcGetL2.zdTeilPeriode, '');

%% Sekanteninduktivitäten mit d-Fluss und q-Fluss alleine
bSimLdLq = true;
if bSimLdLq
    %% Vormagnetisierung entfernen (entsprechendes Material zuweisen)
    sMagnetNames = 'Magnet_1,Magnet_2,Magnet_3,Magnet_4,Magnet_5,Magnet_6';
    sDummyMaterial  = '"SE N41MZ-GR 120deg dummy"'; % = Magnete ohne Koerzitivfeldstärke (H_co = 0 A/m). --> Ermittlung von L_d und L_q
    invoke(oEditor, 'AssignMaterial', {'NAME:Selections', 'Selections:=', sMagnetNames},...
        {'NAME:Attributes', 'MaterialValue:=', sDummyMaterial,...
        'SolveInside:=', true, 'IsMaterialEditable:=', true});
    
    %% Erregung setzen (sinusförmig mit injizierter Oberschwingung)
    % Randbedingung setzen
    oModule = oDesign.GetModule('BoundarySetup');                              
    rgsWindingGroupCurrent = {
        % Version 18.2: '-Inenn*(Id*cos(2*pi*frq_el*time+g_offset)-Iq*sin(2*pi*frq_el*time+g_offset)) + io*cos(2*pi*fo*time)',...
        'I_rms*sqrt(2)*(Id*cos(2*pi*frq_el*time+g_offset)-Iq*sin(2*pi*frq_el*time+g_offset))'; 
        % Version 18.2: '-Inenn*(-0.5*(Id*cos(2*pi*frq_el*time+g_offset)-Iq*sin(2*pi*frq_el*time+g_offset))-0.86603*(Iq*cos(2*pi*frq_el*time+g_offset)+Id*sin(2*pi*frq_el*time+g_offset))) + io*cos(2*pi*fo*time)',...
        'I_rms*sqrt(2)*(Id*cos(2*pi*frq_el*time-2*pi/3+g_offset)-Iq*sin(2*pi*frq_el*time-2*pi/3+g_offset))'; 
        % Version 18.2: '-Inenn*(-0.5*(Id*cos(2*pi*frq_el*time+g_offset)-Iq*sin(2*pi*frq_el*time+g_offset))+0.86603*(Iq*cos(2*pi*frq_el*time+g_offset)+Id*sin(2*pi*frq_el*time+g_offset))) + io*cos(2*pi*fo*time)',...
        'I_rms*sqrt(2)*(Id*cos(2*pi*frq_el*time+2*pi/3+g_offset)-Iq*sin(2*pi*frq_el*time+2*pi/3+g_offset))'; 
        };
     % Phasenbezeichnungen
    rgsPhaseNames = {'U';'V';'W'};
    % alle Phasen durchgehen
    for ziPhase = 1:length(rgsPhaseNames) 
        invoke(oModule, 'EditWindingGroup', sprintf('Phase%s',rgsPhaseNames{ziPhase,1}), {...
            sprintf('NAME:Phase%s',rgsPhaseNames{ziPhase,1})           ,...
            'Type:='                , 'Current',...
            'IsSolid:='             , 'False',...
            'Current:='             ,...
            rgsWindingGroupCurrent{ziPhase,1},...
            'Resistance:='          , '0ohm',...
            'Inductance:='          , '0mH',...
            'Voltage:='             , '0V',...
            'ParallelBranchesNum:='	, 'NoPB'});
    end
    oDesign.Analyze('Setup3');
    
    %% Ausgabe der d- und q-Sekanteninduktivitäten
    oModule = oDesign.GetModule('ReportSetup');
    sAnsysReportName = 'LdLq';
    sAnsysExportName = 'LdLq.csv';
    oModule.ExportToFile(sAnsysReportName, fullfile(sMainPath, sAnsysExportName));
    
    %% Einlesen und Verarbeiten der exportierten Daten
     % Ergebnis-Tabelle exportieren
    grcOpts = delimitedTextImportOptions("NumVariables", 3);                  
    grcOpts.DataLines = [2, Inf];
    grcOpts.Delimiter = ",";
    grcOpts.VariableNames = ["rgkdTt", "rgkdLd", "rgkdLq"];
    grcOpts.VariableTypes = ["double", "double", "double"];
    grcOpts.ExtraColumnsRule = "ignore";
    grcOpts.EmptyLineRule = "read";
    tblLdLq = readtable(fullfile(sMainPath, sAnsysExportName), grcOpts);
    
    
   %% überschreiben der Werte
     % Induktivität in d-Richtung in [H]
    grcAP.rgkdLd(ziAP) = mean(tblLdLq.rgkdLd);   
     % Induktivität in q-Richtung in [H]
    grcAP.rgkdLq(ziAP) = mean(tblLdLq.rgkdLq);                            
    fprintf(1, 'L_d = %.2f µH\n', grcAP.rgkdLd(ziAP)*1e6);
    fprintf(1, 'L_q = %.2f µH\n', grcAP.rgkdLq(ziAP)*1e6);
    clear tblLdLq grcOpts
    
end

%% Vormagnetisierung wieder hinzufügen (entsprechendes Material zuweisen)
sMagnetNames = 'Magnet_1,Magnet_2,Magnet_3,Magnet_4,Magnet_5,Magnet_6';
% = Magnete mit Koerzitivfeldstärke (H_co = -886 kA/m)
sMagnetMaterial = '"SE N41MZ-GR 120deg"';
invoke(oEditor, 'AssignMaterial', {'NAME:Selections', 'Selections:=', sMagnetNames},...
    {'NAME:Attributes', 'MaterialValue:=', sMagnetMaterial,...
    'SolveInside:=', true, 'IsMaterialEditable:=', true});

%% Erregung setzen (sinusförmig mit injizierter Oberschwingung)
oModule = oDesign.GetModule('BoundarySetup');                              % Randbedingung setzen
sIOSFunktion = ' + kdInu*cos(2*pi*kdFnu*time)';                            % Zeitfunktion Oberschwingungskomponente, für alle drei Phasen gleich, damit Nullsystem sichtbar wird. Aus dem Strom im Nullsystem wird später eine Induktivität bestimmt.
rgsWindingGroupCurrent = {
    ['I_rms*sqrt(2)*(Id*cos(2*pi*frq_el*time+g_offset)-Iq*sin(2*pi*frq_el*time+g_offset))', sIOSFunktion]; % Version 18.2: '-Inenn*(Id*cos(2*pi*frq_el*time+g_offset)-Iq*sin(2*pi*frq_el*time+g_offset)) + io*cos(2*pi*fo*time)',...
    ['I_rms*sqrt(2)*(Id*cos(2*pi*frq_el*time-2*pi/3+g_offset)-Iq*sin(2*pi*frq_el*time-2*pi/3+g_offset))', sIOSFunktion]; % Version 18.2: '-Inenn*(-0.5*(Id*cos(2*pi*frq_el*time+g_offset)-Iq*sin(2*pi*frq_el*time+g_offset))-0.86603*(Iq*cos(2*pi*frq_el*time+g_offset)+Id*sin(2*pi*frq_el*time+g_offset))) + io*cos(2*pi*fo*time)',...
    ['I_rms*sqrt(2)*(Id*cos(2*pi*frq_el*time+2*pi/3+g_offset)-Iq*sin(2*pi*frq_el*time+2*pi/3+g_offset))', sIOSFunktion]; % Version 18.2: '-Inenn*(-0.5*(Id*cos(2*pi*frq_el*time+g_offset)-Iq*sin(2*pi*frq_el*time+g_offset))+0.86603*(Iq*cos(2*pi*frq_el*time+g_offset)+Id*sin(2*pi*frq_el*time+g_offset))) + io*cos(2*pi*fo*time)',...
    };
rgsPhaseNames = {'U';'V';'W'}; % Phasenbezeichnungen
for ziPhase = 1:length(rgsPhaseNames) % alle Phasen durchgehen
    invoke(oModule, 'EditWindingGroup', sprintf('Phase%s',rgsPhaseNames{ziPhase,1}), {...
        sprintf('NAME:Phase%s',rgsPhaseNames{ziPhase,1})           ,...
        'Type:='                , 'Current',...
        'IsSolid:='             , 'False',...
        'Current:='             ,...
        rgsWindingGroupCurrent{ziPhase,1},...
        'Resistance:='          , '0ohm',...
        'Inductance:='          , '0mH',...
        'Voltage:='             , '0V',...
        'ParallelBranchesNum:='	, 'NoPB'});
end

%% Simulation durchführen
oDesign.Analyze('Setup1');

%% Ausgabe Nullsystem
oModule = oDesign.GetModule('ReportSetup');
sAnsysReportName = 'Nullsystem_table';
sAnsysExportName = 'Nullsystem_table.csv';
oModule.ExportToFile(sAnsysReportName, fullfile(sMainPath, sAnsysExportName));

%% Einlesen der exportierten Daten
grcOpts = delimitedTextImportOptions("NumVariables", 3);
grcOpts.DataLines = [2, Inf];
grcOpts.Delimiter = ",";
grcOpts.VariableNames = ["rgkdT", "rgkdI0t", "rgkdPsi0t"];
grcOpts.VariableTypes = ["double", "double", "double"];
grcOpts.ExtraColumnsRule = "ignore";
grcOpts.EmptyLineRule = "read";
tblNullsystem = readtable(fullfile(sMainPath, sAnsysExportName), grcOpts);

%% Berechnung der Ersatzinduktivität
% 0. Harmonische ist Gleichanteil, in Matlab liegt 0. Harmonische unter Index = 1.
grcEvalL.ziSpekIndex = grcParam.grcGetL2.ziNu + 1;
% Amplituden-Spektrum  Strom, 0 bis ziSchritte (symmetrisch bei ziSchritte/2)
grcEvalL.rgkdSpekI0 = 2*abs(fft(tblNullsystem.rgkdI0t))/length(tblNullsystem.rgkdI0t); 
% Abschneiden des gespiegelten Bereichs
grcEvalL.rgkdSpekI0 = grcEvalL.rgkdSpekI0(1:floor(end/2),:); 
% mit Ausnahme des Gleichanteils = 0. Harmonische
grcEvalL.rgkdSpekI0(1,:) = grcEvalL.rgkdSpekI0(1,:)/2; 
% Amplituden-Spektrum Flussverkettung
grcEvalL.rgkdSpekPsi0 = 2*abs(fft(tblNullsystem.rgkdPsi0t))/length(tblNullsystem.rgkdPsi0t); 
% Abschneiden des gespiegelten Bereichs
grcEvalL.rgkdSpekPsi0 = grcEvalL.rgkdSpekPsi0(1:floor(end/2),:); 
% mit Ausnahme des Gleichanteils = 0. Harmonische+
grcEvalL.rgkdSpekPsi0(1,:) = grcEvalL.rgkdSpekPsi0(1,:)/2; 
rgkdL2 = grcEvalL.rgkdSpekPsi0./grcEvalL.rgkdSpekI0;
% L2"-Spektrum betrachten
plot(grcEvalL.rgkdSpekPsi0); 
% L2"-Spektrum betrachten
plot(grcEvalL.rgkdSpekI0); 
% L2"-Spektrum betrachten
plot(rgkdL2); 
% Gegenläufige Induktivität in [H]
grcAP.rgkdL2(ziAP) = grcEvalL.rgkdSpekPsi0(grcEvalL.ziSpekIndex)/grcEvalL.rgkdSpekI0(grcEvalL.ziSpekIndex); 
fprintf(1, 'L_2" = %.2f µH\n', grcAP.rgkdL2(ziAP)*10e5);
%clear tblNullsystem grcOpts grcEvalL



    %% 2. for-Schleife zur Variation der NoSegm
    for index = 1:Anzahl_Simulationen
    
    % Festlegung verschiedener Variablen
    if  index == 1
        NoS = 1026;
    else 
        NoS = Start_NoS + Erhoehung_NoS_pro_Schritt*(index-1);
    end

    %Erstellung eines Strings um die Benneung des Workspace mit den aktuellen NoS zu ergänzen
    NoS_str= num2str(NoS);

    %% Zeigerdiagramm nachrechnen (vgl. Bericht5, S. 36)
    kdOmega = 2*pi*grcAP.rgkdFfel(ziAP);
    % Spannungsabfall in der q-Achse (= Imaginärteil der Strangspannung)
    grcAP.rgkdUqstr(ziAP) = (grcAP.rgkdLd(ziAP)+grcAP.rgkdLWK(ziAP))*kdOmega*grcAP.rgkdIdstr(ziAP)+grcAP.rgkdUp(ziAP)+grcAP.rgkdRstr(ziAP)*grcAP.rgkdIdstr(ziAP); 
    % Spannungsabfall in der d-Achse (= Realteil der Strangspannung)
    grcAP.rgkdUdstr(ziAP) = (grcAP.rgkdLq(ziAP)+grcAP.rgkdLWK(ziAP))*kdOmega*grcAP.rgkdIqstr(ziAP)+grcAP.rgkdRstr(ziAP)*grcAP.rgkdIdstr(ziAP);
    grcAP.rgkdULL1peak(ziAP) = sqrt(3)*sqrt(grcAP.rgkdUdstr(ziAP)^2+grcAP.rgkdUqstr(ziAP)^2);

    %% Initialsierung: Auslesen der benötigten Größen
    bStern            = grcParam.grcMaschine.bStern;                            % ist in Stern geschaltet?
    zdGammaOffset     = grcParam.grcMaschine.zdGammaOffset;                     % Verdrehen der Maschine zur Ausrichtung im dq-Koordinatensystem in [°]
    kdUzk             = grcParam.grcFU.kdUzk;                                   % Zwischenkreisspannung in [V]
    ziKk              = grcParam.grcFU.ziKk;                                    % Anzahl der zu betrachtenden Trägerbänder
    kdFfc             = grcParam.grcFU.kdFfc;                                   % Schaltfrequenz des Umrichters in [Hz]
    ziLmax            = grcParam.grcFU.ziLmax;                                  % Maximale Anzahl betrachteter Seitenbänder pro Trägerband
    zdPhiUum          = grcParam.grcFU.zdPhiUum;                                % Phasenverschiebung Leiter-Mittelpunktspannung in [rad], Phase U

    kdULL1peak        = grcAP.rgkdULL1peak(ziAP);                               % Verkettete Spannung (Grundschwingung, Spitzenwert) in [V]
    kdUdstr           = grcAP.rgkdUdstr(ziAP);                                  % d-Spannung in [V]
    kdUqstr           = grcAP.rgkdUqstr(ziAP);                                  % q-Spannung in [V]
    kdIrms            = grcAP.rgkdIrms(ziAP);                                   % Effektiv-Strangstrom in [A]
    kdIdstr           = grcAP.rgkdIdstr(ziAP);                                  % d-Strom in [A]
    kdIqstr           = grcAP.rgkdIqstr(ziAP);                                  % q-Strom in [A]
    zdTheta           = grcAP.rgzdTheta(ziAP);                                  % Stromwinkel in der d-q-Ebene aus gegebenen Komponenten in [°]
    kdFfel            = grcAP.rgkdFfel(ziAP);                                   % Elektrische Grundschwingungsfrequenz in [Hz]
    kdLd              = grcAP.rgkdLd(ziAP);                                     % Induktivität in d-Richtung in [H]
    kdLq              = grcAP.rgkdLq(ziAP);                                     % Induktivität in q-Richtung in [H]
    kdL2              = grcAP.rgkdL2(ziAP);                                     % Gegenläufige Induktivität in [H]
    kdLWK             = grcAP.rgkdLWK(ziAP);                                    % Zusatzinduktivität in [H] zur Berücksichtigung des magn. Streuung im Wickelkopf
    sRstrModel        = 'quad';                                                 % Berechnungsmodell für frequenzabhängigen Strangwiderstand

    %% Betrachtete Zeitachse
    kdT1     = 1/kdFfel; % Grundschwingungsperiode
    ziPunkte = 2; % Anzahl der Punkte pro Periode des höchstfrequenten Signals (mindestens Nyqvist = 2), bei höherer Zahl wird das Spektrum auf der Frequenzachse einfach nur länger.
    kdFfg    = ziKk*kdFfc+ziLmax*kdFfel; % Grenzfrequenz bei der Berechnung des theoretischen Stromspektrums in [Hz]
    ziDeltaT = kdFfg/kdFfel*ziPunkte; % Anzahl der Zeitschritte zur Abbildung der betrachteten Grenzfrequenz
    rgkdT    = linspace(0, kdT1, ziDeltaT+1);  % Zeitvektor //CS:erzeugt einen Vektor von 0 bis kdT1 mit "ziDeltaT+1" Punkten zwischen 0 und kdT1
    rgkdT    = rgkdT(1:end-1); % Der Punkt bei kdT1 ( = Anfang der nächsten Periode) wird erst nach der Phasenanpassung hinzugefügt, um Knicke im Verlauf zu vermeiden.
    kdFfmax  = ziDeltaT/kdT1/2; %CS: wird weiterhin nur zum plotten der Spektren genutzt
    rgkdFf   = linspace(0, kdFfmax, ziDeltaT/2+1); %CS: wird weiterhin nur zum plotten der Spektren genutzt
    %ziDeltaT = int16(ziDeltaT);
    %% Verläufe der Leiter-Mittelpunktspannungen am Wechselrichterausgang je Phase berechnen
    % Theoretische Gleichung nach Bernet: "Selbstgeführte Stromrichter am Gleichspannungszwischenkreis", S. 108f
    % Falls andere Grundgleichungen/Pulsmuster/Modulationsverfahren genutzt werden sollen, muss dieser Block hier geändert werden.
     rgkdUm = 0;
    %rgkdUm = zeros(3, ziDeltaT); % Preallocation Leiter-Mittelpunktspannungen, Spalte = Leiter
    zdMod       = kdULL1peak / (sqrt(3)*kdUzk/2); % Modulationsgrad
    ziKBandMax  = kdFfg / kdFfc;        % Max. Anzahl der Trägerbänder, durch Frequenzwahl der Eingangsparameter festgelegt //CS:wozu diese Berechnung...wird durch "ziKk" festgelegt? Weil es bei ziLmax von 4 ab bei f_el>333.3Hz Sinn macht da dann größer als f_c=1000
    rgzdPhiU = [    % CS: Erstellung der 3 Leiter durch Phasenverschiebung
        zdPhiUum;           % CS: Uum
        zdPhiUum - 2*pi/3;  % CS: Uwm
        zdPhiUum + 2*pi/3;  % CS: Uvm
        ];
    % CS: GRUNDSCHWINGUNG, Spannungswerte werden Stück für Stück aufaddiert in Abhängigkeit des Zeitvektors
     rgkdUm = rgkdUm + zdMod/2 * cos(2*pi*kdFfel*rgkdT + rgzdPhiU); 
    %rgkdUm = zdMod/2 * cos(2*pi*kdFfel*rgkdT + rgzdPhiU); 

    % über alle Trägerbänder iterieren
    for ziK = 1:ziKBandMax 
        % Berechnung erfolgt bezogen auf die Zwischenkreisspannung
        % CS: aufaddieren aller OBERSCHWINGUNGEN aus Trägerbandern
        rgkdUm = rgkdUm + 2/(pi*ziK) .* besselj(0,(ziK*pi*zdMod/2)) .* sin(ziK*pi/2) .* cos(ziK*2*pi*kdFfc.*rgkdT);
        % alle Seitenbänder pro Trägerband betrachten
        for ziL = [ -ziLmax:-1 , 1:ziLmax ] 
            rgkdUm = rgkdUm + 2/(pi*ziK) .* besselj(ziL,(ziK*pi*zdMod/2)) .* sin((ziK+ziL)*pi/2) .* cos(ziK*2*pi*kdFfc.*rgkdT + ziL*(2*pi*kdFfel.*rgkdT+rgzdPhiU)); % CS: aufaddieren aller OBERSCHWINGUNGEN aus Seitenbändern
        end
    end
    rgkdUm = rgkdUm .* kdUzk; % mit Zwischenkreisspannung skalieren

    %% Vekettete Spannungen, Sternpunktspannungen, Strangspannungen
    rgkdULL  = rgkdUm - circshift(rgkdUm,2,1); % Verkettete Spannungen [Uu-Uv; Uv-Uw; Uw-Uu]
    rgkdUnm  = 1/3 * (sum(rgkdUm)); % Sternpunktspannungen //CS: 
    if bStern % Sternschaltung
        rgkdUstr = rgkdUm - rgkdUnm; % Strangspannungen aus Sternpunktspannung
    else % Dreieckschaltung
        rgkdUstr = rgkdULL; % Strangspannungen = Verkettete Spannungen
    end

    %% Fourier-Transformation der Strangspannungen: komplexes Strangspannungsspektrum
    %https://de.mathworks.com/help/matlab/ref/fft.html#d123e424985 ... Cosine waves
    rgkdUstrSpektrum      = fft(rgkdUstr,length(rgkdUstr),2) / length(rgkdUstr) * 2; % *2 = "Rüberklappen" der Amplituden der negativen Frequenzen // CS: gibt die Fourier-Transformation entlang der Dimension dim zurück. Wenn X beispielsweise eine Matrix ist, gibt fft(X,n,2) die n-Punkt-Fouriertransformation jeder Zeile zurück
    rgkdUstrSpektrum(:,1) = rgkdUstrSpektrum(:,1)/2; % mit Ausnahme des Gleichanteils = 0. Harmonische
    rgkdUstrSpektrum      = rgkdUstrSpektrum(:,1:floor(end/2)); % Abschneiden des gespiegelten Bereichs
    plot(rgkdFf(1:end-1),abs(rgkdUstrSpektrum(1,:))); xlabel("Frequenz in Hz"); ylabel("Spannungsamplitude in V"); % Spektrum Test

    %% Berechnung des komplexen Impedanzspektrums
    % (Berücksichtigt frequenzabhängigen Strangwiderstand, interpoliert aus Simulationsergebnissen
    % und die Ersatzinduktivität für das Oberschwingungsverhalten aus den Vorgängersimulationen)
    rgkdZSpektrum = ones(1, length(rgkdUstrSpektrum)); % Preallocation
    for ziNu = 3:length(rgkdUstrSpektrum) % nur Oberschwingungen ohne Grundschwingung durchgehen (1 = Gleichanteil, 2 = Grundschwingung)
        rgkdZSpektrum(1, ziNu) = fcnInterpolRstr(kdFfel*(ziNu-1), sRstrModel) + 1j * 2*pi*kdFfel*(ziNu-1) * (kdLWK+kdL2); 
    end
    plot(rgkdFf(1:end-1),abs(rgkdZSpektrum(1,:))); xlabel("Frequenz in Hz"); ylabel("Impedanz in Ohm"); % Spektrum Test

    %% Berechnung des komplexen Stromspektrums über die Impedanz
    rgkdIstrSpektrum = rgkdUstrSpektrum ./ rgkdZSpektrum;
    zdPhiZ = atan2(kdUqstr, kdUdstr) - atan2(kdIqstr, kdIdstr); % PhiZ = PhiU - PhiI
    rgkdIstrSpektrum(:,2) = sqrt(2)* kdIrms * exp(1j*(rgzdPhiU - zdPhiZ)); % Vorgabe der Stromgrundschwingung, da aus Eingangsdaten bereits bekannt.
     plot(rgkdFf(1:end-1),abs(rgkdIstrSpektrum(1,:))); xlabel("Frequenz in Hz"); ylabel("Spannungsamplitude in V"); % Spektrum Test

    %% Anpassung des Stromspektrums basierend auf der vorgegebenen Stromgrundschwingung und den arbeitspunktabhängigen Induktivitäten
    kdIest = kdULL1peak/(sqrt(3)*2*pi*kdFfel*(kdLd + kdLq)/2); % Mittlerer Grundschwingungsstrom, der bei Annahme des Mittelwerts aus Ld und Lq und Vernachlässigung des Strangwiderstands fließen würde. Grundidee ist, dass die Ersatzinduktivität für das Oberschwingungsverhalten nicht auf die Grundschwingung anwendbar ist und für diese näherungsweise der Mittelwert aus Ld und Lq angenommen werden kann.
    zdIskal = sqrt(2)* kdIrms / kdIest; % Skalierungsfaktor: mittlerer Grundschwingungsstrom bezogen auf gemessenen Grundschwingungsstrom.
    rgkdIstrSpektrum(:,3:end) = rgkdIstrSpektrum(:,3:end) .* zdIskal; % Runterskalieren des Stromspektrums bezogen auf tatsächlichen Grundschwingungsstrom.
    plot(rgkdFf(1:end-1),abs(rgkdIstrSpektrum(1,:))); xlabel("Frequenz in Hz"); ylabel("Stromamplitude in A"); % Spektrum Test


    % Definition einer Variable mit in dem der Wert der maximalen Frequenz des Spektrums hinterlegt ist
    f_Filter = 36000; 
    % Definition eines Skalierungsfaktors zur Begrenzung des Spektrums
    % mit diesem Skalierungsfaktor kann bei gegebener Frequenz f_Filter die Spalte festgelegt werden, ab der die Tabelle "rgkdIstrSpektrum" mit dem Wert 0 aufgefüllt werden soll, so wird das Spektrum begrenzt
    x= 103000/length(rgkdIstrSpektrum);
    
    %if index > 1
    %rgkdT    = rgkdT(1:end-1);
    %end 

        %% 3. for-Schleife zur Filterung des Spektrums
 
        % Ermittlung der Spalte ab der die Tabelle "rgkdIstrSpektrum" mit dem Wert 0 aufgefüllt werden soll    
        y= f_Filter/x;
        % auffüllen der tabelle "rgkdIstrSpektrum" mit dem Wert 0
        rgkdIstrSpektrum(:,y:end) = 0;
        plot(rgkdFf(1:end-1),abs(rgkdIstrSpektrum(1,:))); xlabel("Frequenz in Hz"); ylabel("Stromamplitude in A"); % Spektrum Test
        
        % erstellen eines strings zur Benennung der Dateien
        f_Filter_str = num2str(f_Filter);


        %% Rücktransformation der Stromspektren
        rgkdIstr = 0; % Preallocation
        for ziNu = 2:length(rgkdIstrSpektrum) % Grundschwingung + Oberschwingungen
            rgkdIstr = rgkdIstr + abs(rgkdIstrSpektrum(:,ziNu)) .* cos((ziNu-1)*2*pi*kdFfel*rgkdT + angle(rgkdIstrSpektrum(:,ziNu)));
        end
        %% Phasenverschiebung der Strangströme im Modell (in Grad)
        %zdDeltaPhiI   = zdGammaOffset - (180 - zdTheta); % Phasenverschiebung des Strangstromes im Modell, ist 180°-dq-Winkel, da der Standardfall von reinem NEGATIVEM d-Strom ausgeht, außerdem abhängig vom Arbeitspunkt(?)
        zdDeltaPhiI   = zdGammaOffset + zdTheta; % Phasenverschiebung des Strangstromes im Modell, abhängig vom Arbeitspunkt
        ziIndexShift  = round( length(rgkdT)* (angle(rgkdIstrSpektrum(1,2)) / (2*pi) - zdDeltaPhiI / 360)); % Phase U auf cos-Funktion mit phi=0 bringen und alle Kurven entsprechend verschieben
        rgkdIstr      = circshift(rgkdIstr, ziIndexShift, 2);

        %% Hinzufügen des letzten Punktes (der wieder dem ersten entspricht) zum Auffüllen der gesamten Periodendauer (Vermeidung eines off-by-one-errors) und Knicken im Verlauf (diese können das Gesamtergebnis signifikant beeinflussen)
        rgkdT(end+1)      = kdT1;
        rgkdIstr(:,end+1) = rgkdIstr(:,1);

        %% Ggf. Zuschneiden des Strom-Verlaufs (Falls keine ganze Periode in der nachfolgenden Verlustberechnung betrachtet werden soll)
        % ziPvSchritte ist nicht definiert
        %rgkdT = rgkdT(1:ziPvPMSchritte);
        %rgkdIstr = rgkdIstr(:,1:ziPvPMSchritte);
        mwChangeDesignVariable(oDesign, 'NoSegm', NoS, '');
        mwChangeDesignVariable(oDesign, 'NoElP', 1, '');

        %% Speichern
        grcExport.grcVerlauf.rgkdULL           = rgkdULL;
        grcExport.grcVerlauf.rgkdUm            = rgkdUm;
        grcExport.grcVerlauf.rgkdUnm           = rgkdUnm;
        grcExport.grcVerlauf.rgkdUstr          = rgkdUstr;
        grcExport.grcVerlauf.rgkdIstr          = rgkdIstr;
        grcExport.grcVerlauf.rgkdT             = rgkdT;
        grcExport.grcSpektrum.rgkdUstrSpektrum = rgkdUstrSpektrum;
        grcExport.grcSpektrum.rgkdIstrSpektrum = rgkdIstrSpektrum;
        grcExport.grcSpektrum.rgkdZSpektrum    = rgkdZSpektrum;
        grcErgebnisse.rgzdTHDi = sqrt(sum(abs(rgkdIstrSpektrum(1,:)).^2) - abs(rgkdIstrSpektrum(1,2))^2) / abs(rgkdIstrSpektrum(1,2));
        fprintf('THDi: %.2f %%\n', grcErgebnisse.rgzdTHDi*100);
        grcExport.sDateiname = fullfile(sMainPath, [num2str(grcParam.grcFU.kdUzk), 'V_', num2str(grcParam.grcFU.kdFfc/1e3), 'kHz_']); % Dateiname der Ausgabe von Strangstromzeitwerten, hier automatisch generiert aus Zwischenkreisspannung, Schaltfrequenz und Schrittzahl der Simulation
        save(grcExport.sDateiname, 'grcExport');

        %% Stromverläufe importieren und einbinden
        mwEditCurrentDatasets(oDesign, grcExport);

        %% Erregung setzen (importierte Stromverläufe)
        oModule = oDesign.GetModule('BoundarySetup');
        rgsPhasen = [
            "PhaseU";
            "PhaseV";
            "PhaseW";
            ];
        rgsIstr = [
            "rgkdIu";
            "rgkdIv";
            "rgkdIw";
            ];
        for ziPhase = 1:size(grcExport.grcVerlauf.rgkdIstr,1)
            invoke(oModule, 'EditWindingGroup', rgsPhasen(ziPhase,1), {...
                sprintf('NAME:%s',rgsPhasen(ziPhase,1)),...
                'Type:='                , 'Current',...
                'IsSolid:='             , 'False',...
                'Current:='             , sprintf('pwl(%s, time)',rgsIstr(ziPhase,1)),...
                'Resistance:='          , '0ohm',...
                'Inductance:='          , '0mH',...
                'Voltage:='             , '0V',...
                'ParallelBranchesNum:='	, 'NoPB'});
        end

        %% Simulation durchführen
        % Start des Timers zur Messung der Simulationszeit
        tiSimStart = tic; % Zeit starten
        % Design analysieren
        oDesign.Analyze('Setup2'); % mit SaveFields, brauchen wir zum Bestimmen der Verluste der Einzelmagneten, Gesamtmagnete über SolidLosses.
        % Stoppen der Simulationszeit
        StopZeit = toc(tiSimStart); 
        fprintf("AP%u: Simulation mit %u Segmenten und einer Frequenz von %u nach %.2f min fertig. \n",index_AP, NoS,f_Filter, StopZeit/60);

        %% Referenzwert abspeichern
        if index == 1
        %% Ergebnis aus Maxwell exportieren
        oModule = oDesign.GetModule('ReportSetup');
        oModule.UpdateReports(["Wirbelstromverluste_gesamt","Wirbelstromverluste_Mittelwert"]); % Reports updaten (nicht wÃ¤hrend der Simulation, erst am Schluss!)
        oModule.ExportToFile("Wirbelstromverluste_gesamt", fullfile(sMainPath,"Wirbelstromverluste_gesamt.csv"), false);
        oModule.ExportToFile("Wirbelstromverluste_Mittelwert", fullfile(sMainPath,"Wirbelstromverluste_Mittelwert.csv"), false);

        %% Daten einlesen und in Matlab-Cell-Array ablegen - SIMULATIONSZEIT
        % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
        temporaer_table = table(StopZeit);
        % Bezeichnung der Spalten geeignet ändern
        temporaer_table.Properties.VariableNames = "Simulationszeit_s_"+f_Filter_str;
        % abspeichern der Daten jedes Simulationsdurchlaufes der Variabel "Drehmoment" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
        Simulationszeit_Cell_1026(:,1) = {temporaer_table};

        %% Daten einlesen und in Matlab-Cell-Array ablegen - WIRBELSTROMVERLUSTE
        % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
        temporaer_table = readtable(fullfile(sMainPath,"Wirbelstromverluste_gesamt.csv"));
        % Bezeichnung der Spalten geeignet ändern
        temporaer_table.Properties.VariableNames = ["Time_Feinmodell"+NoS_str,"Wirbelstromverluste_gesamt__W__"+f_Filter_str];
        % abspeichern der Daten jedes Simulationsdurchlaufes der Variabel "Drehmoment" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
        Wirbelstromverluste_gesamt_Cell_1026(:,1) = {temporaer_table};

        %% Daten einlesen und in Matlab-Cell-Array ablegen - WIRBELSTROMVERLUSTE MITTELWERT
        % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
        temporaer_table = readtable(fullfile(sMainPath,"Wirbelstromverluste_Mittelwert.csv"));
        % Bezeichnung der Spalten geeignet ändern
        temporaer_table.Properties.VariableNames = ["Time_Feinmodell"+NoS_str,"Wirbelstromverluste_Mittelwert__W__"+f_Filter_str];
        % abspeichern der Daten jedes Simulationsdurchlaufes der Variabel "Drehmoment" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
        Wirbelstromverluste_Mittelwert_Cell_1026(:,1) = {temporaer_table};

        %bereinigt den Ordner IPMSMs.aedtresults
        oDesign.DeleteFullVariation("All", false);
        %Ende zum abspeichern der Referenz
        end

        if index > 1
        %% Ergebnis aus Maxwell exportieren
        oModule = oDesign.GetModule('ReportSetup');
        oModule.UpdateReports(["Wirbelstromverluste_gesamt","Wirbelstromverluste_Mittelwert"]); % Reports updaten (nicht wÃ¤hrend der Simulation, erst am Schluss!)
        oModule.ExportToFile("Wirbelstromverluste_gesamt", fullfile(sMainPath,"Wirbelstromverluste_gesamt.csv"), false);
        oModule.ExportToFile("Wirbelstromverluste_Mittelwert", fullfile(sMainPath,"Wirbelstromverluste_Mittelwert.csv"), false);

        %% Daten einlesen und in Matlab-Cell-Array ablegen - SIMULATIONSZEIT
        % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
        temporaer_table = table(StopZeit);
        % Bezeichnung der Spalten geeignet ändern
        temporaer_table.Properties.VariableNames = "Simulationszeit_s_"+f_Filter_str;
        % abspeichern der Daten jedes Simulationsdurchlaufes der Variabel "Drehmoment" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
        Simulationszeit_Cell(:,index) = {temporaer_table};

        %% Daten einlesen und in Matlab-Cell-Array ablegen - WIRBELSTROMVERLUSTE
        % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
        temporaer_table = readtable(fullfile(sMainPath,"Wirbelstromverluste_gesamt.csv"));
        % Bezeichnung der Spalten geeignet ändern
        temporaer_table.Properties.VariableNames = ["Time_Feinmodell"+f_Filter_str,"Wirbelstromverluste_gesamt__W__"+f_Filter_str];
        % abspeichern der Daten jedes Simulationsdurchlaufes der Variabel "Drehmoment" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
        Wirbelstromverluste_gesamt_Cell(:,index) = {temporaer_table};

        %% Daten einlesen und in Matlab-Cell-Array ablegen - WIRBELSTROMVERLUSTE MITTELWERT
        % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
        temporaer_table = readtable(fullfile(sMainPath,"Wirbelstromverluste_Mittelwert.csv"));
        % Bezeichnung der Spalten geeignet ändern
        temporaer_table.Properties.VariableNames = ["Time_Feinmodell"+f_Filter_str,"Wirbelstromverluste_Mittelwert__W__"+f_Filter_str];
        % abspeichern der Daten jedes Simulationsdurchlaufes der Variabel "Drehmoment" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
        Wirbelstromverluste_Mittelwert_Cell(:,index) = {temporaer_table};
        
        %% Daten einlesen und in Matlab-Cell-Array ablegen - THD
        % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
        temporaer_table = table(grcErgebnisse.rgzdTHDi*100);
        % Bezeichnung der Spalten geeignet ändern
        temporaer_table.Properties.VariableNames = "THD"+f_Filter_str;
        % abspeichern der Daten jedes Simulationsdurchlaufes der Variabel "Drehmoment" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
        THD_Cell(:,index) = {temporaer_table};

        %% Berechnung der prozentualen Abweichung der Mittelwerte (Wirbelstromverluste) innerhalb einer Iteration
        Wert_Eins = Wirbelstromverluste_Mittelwert_Cell{:,index};
        Iteration_Eins = Wert_Eins{:,2};
        Iteration_Zwei = Wirbelstromverluste_Mittelwert_Cell_1026{1,1}{1,2};
        Prozentuale_Abweichung_Simulationen = abs((Iteration_Zwei-Iteration_Eins)/Iteration_Zwei*100);
        %Abspeichern in "cell"
        % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
        temporaer_table = table(Prozentuale_Abweichung_Simulationen);
        % Bezeichnung der Spalten geeignet ändern
        temporaer_table.Properties.VariableNames = "Prozentuale_Abweichung_Simulationen_"+f_Filter_str+"_zu_100000";
        % abspeichern der Daten jedes Simulationsdurchlaufes der Variabel " Prozentuale_Abweichung_Simulationen" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
        Prozentuale_Abweichung_Simulation_Cell(:,index) = {temporaer_table};
        %Ausgabe der aktuellen Abweichung
        fprintf("AP%u: Die aktuelle Abweichung einem einem Spektrum von %u Hz zu %d Hz beträgt %.2f%%. \n",index_AP, f_Filter, 103000, Prozentuale_Abweichung_Simulationen);
        filename = "AP"+index_AP_str+"_NoS_"+NoS_str+"_Simulation_"+d_str+"_Feinmodell_1_15_Induktivitaet_1_4_mit_L2.mat";
        save(filename)
        %bereinigt den Ordner IPMSMs.aedtresults
        oDesign.DeleteFullVariation("All", false);
        
            % Ende for Schleife für Anpassung NoS
        end
    

    %% Abspeichern der Daten in txt Dateien/ Abspeichern der Werte eines Arbeitspunktes
    
    %% Definieren aller Variablen und Funktionen
    Anzahl_durchgefuehrter_Simulationen = index;
    % Erstellen zweier Tabellen
    Tabelle_NoS_Prozentuale_Abweichung = table();
    Tabelle_NoS_Simulationszeit = table();
    Tabelle_THD = table();

    %% Definieren der Ordner zu abspeichern der Textdateien
    Ordner_Verlauf_Wirbelstromverluste = "C:\Users\scale\Desktop\Daten Umrichterspeisung Konvergenzverhalten verkuerzte Periode 1_15 Induktivitaet schneller 1_4 mit L2 AP 1 bis 5";
    Ordner_Verlauf_Simulationszeit_Prozentuale_Abweichung = "C:\Users\scale\Desktop\Daten Umrichterspeisung Konvergenzverhalten verkuerzte Periode 1_15 Induktivitaet schneller 1_4 mit L2 AP 1 bis 5";
    Ordner_Daten_Simulationszeit_Abweichung = "C:\Users\scale\Desktop\Daten Umrichterspeisung Konvergenzverhalten verkuerzte Periode 1_15 Induktivitaet schneller 1_4 mit L2 AP 1 bis 5";
    
    %% Extrahieren von Daten aus "cell" und exportieren in Textdateien zur Darstellung in LaTex
    for index_zwei = 1:Anzahl_durchgefuehrter_Simulationen-1
    
    
    NoS_Benennung = (index_zwei+1)*Erhoehung_NoS_pro_Schritt+Start_NoS;
    
    NoS_Benennung_str = num2str(NoS_Benennung);

    %Tabelle mit NoS Werten
    NoS_Bennenung_Cell = cell(1,1);
    NoS_Bennenung_Cell{1,1} =  NoS_Benennung;
    Tabelle_NoS= table();
    Tabelle_NoS(1,1)= NoS_Bennenung_Cell(1,1);


    %% Verlauf der Wirbelstromverluste
    %definieren aus welchem "cell" Daten extrahiert werden sollen, hier wird der jeweilige Speicherplatz der "cell" in einer "table" abgespeichert 
    Tabelle_Verlauf_Wirbelstromverluste = Wirbelstromverluste_gesamt_Cell{:,index_zwei+1};
    %runden aller Werte in der Tabelle
    Tabelle_Verlauf_Wirbelstromverluste{:,:} = round(Tabelle_Verlauf_Wirbelstromverluste.Variables, 6);
    %umbenennen der Spaltennamen x und y zum plotten 
    Tabelle_Verlauf_Wirbelstromverluste.Properties.VariableNames = ["x","y"];
    %bestimmt wo die Textdateien abgespeichert werden
    table_path_format_Verlauf_Wireblstromverluste = fullfile(Ordner_Verlauf_Wirbelstromverluste, "AP"+index_AP_str+"_Wirbelstromverluste_Verlauf_"+NoS_str+".txt");
    %ausgeben der Tabelle für die Prozentuale Abweichung als Textdatei für jede einzelne Simulation in einer seperaten Textdatei
    writetable(Tabelle_Verlauf_Wirbelstromverluste,table_path_format_Verlauf_Wireblstromverluste,"Delimiter"," ");

    %wie man Daten aus einem "cell" extrahiert und in eine Tabelle schreibt
    %% Prozentuale Abweichung
    %definieren aus welchem "cell" Daten extrahiert werden sollen
    Tabelle_Cell_Extrahierung_Indexierung = table(Prozentuale_Abweichung_Simulation_Cell{:,index_zwei+1});
    %Zugreifen auf Daten mehrere Ebenen tief: 
    %https://de.mathworks.com/help/matlab/matlab_prog/multilevel-indexing-to-access-parts-of-cells.html
    %zugreifen auf Wert in cell(1,1) mit {1,1} (in dem Fall eine Tabelle) und dann zugreifen auf den Wert innerhalb der Tabelle mit {1,1}{1,1}
    %abspeichern dieses extrahierten Wertes in einer neuen Tabelle
    Tabelle_Table_Extrahierung = table(Tabelle_Cell_Extrahierung_Indexierung{1,1}{1,1});
    %runden des Wertes auf eine sinnvolle Nachkommastelle zur effizienten Dartellung in LaTeX
    Tabelle_Table_Extrahierung_round = round(Tabelle_Table_Extrahierung{1,1},3,"significant");
    %abspeichern der prozentualen Abweichung in einer Tabelle zusammen mit der Simulationszeit (siehe unten) zur Darstellung in LaTeX
    Tabelle_NoS_Prozentuale_Abweichung(index_zwei,1) = Tabelle_NoS(1,1);
    Tabelle_NoS_Prozentuale_Abweichung(index_zwei,2) = table(Tabelle_Table_Extrahierung_round(1,1));


    % wie man Daten aus einem "cell" extrahiert und in eine Tabelle schreibt
    %% Simulationszeit
    %definieren aus welchem "cell" Daten extrahiert werden sollen
    Tabelle_Cell_Extrahierung_Indexierung = table(Simulationszeit_Cell{:,index_zwei+1});
    %Zugreifen auf Daten mehrere Ebenen tief: 
    %https://de.mathworks.com/help/matlab/matlab_prog/multilevel-indexing-to-access-parts-of-cells.html
    %zugreifen auf Wert in cell(1,1) mit {1,1} (in dem Fall eine Tabelle) und dann zugreifen auf den Wert innerhalb der Tabelle mit {1,1}{1,1}
    %abspeichern dieses extrahierten Wertes in einer neuen Tabelle
    Tabelle_Table_Extrahierung = table(Tabelle_Cell_Extrahierung_Indexierung{1,1}{1,1});
    %runden des Wertes auf eine sinnvolle Nachkommastelle zur effizienten Dartellung in LaTeX
    Tabelle_Table_Extrahierung_round = round(Tabelle_Table_Extrahierung{1,1},6,"significant");
    %abspeichern der Simulationszeit in einer Tabelle zusammen mit der prozentualen Abweichung (siehe oben) zur Darstellung in LaTeX
    Tabelle_NoS_Simulationszeit(index_zwei,1) = Tabelle_NoS(1,1);
    Tabelle_NoS_Simulationszeit(index_zwei,2) = table(Tabelle_Table_Extrahierung_round(1,1));
    
    
    %wie man Daten aus einem "cell" extrahiert und in eine Tabelle schreibt
    %% THD
    %definieren aus welchem "cell" Daten extrahiert werden sollen
    Tabelle_Cell_Extrahierung_Indexierung = table(THD_Cell{:,index_zwei+1});
    %Zugreifen auf Daten mehrere Ebenen tief: 
    %https://de.mathworks.com/help/matlab/matlab_prog/multilevel-indexing-to-access-parts-of-cells.html
    %zugreifen auf Wert in cell(1,1) mit {1,1} (in dem Fall eine Tabelle) und dann zugreifen auf den Wert innerhalb der Tabelle mit {1,1}{1,1}
    %abspeichern dieses extrahierten Wertes in einer neuen Tabelle
    Tabelle_Table_Extrahierung = table(Tabelle_Cell_Extrahierung_Indexierung{1,1}{1,1});
    %runden des Wertes auf eine sinnvolle Nachkommastelle zur effizienten Dartellung in LaTeX
    Tabelle_Table_Extrahierung_round = round(Tabelle_Table_Extrahierung{1,1},3,"significant");
    %abspeichern der prozentualen Abweichung in einer Tabelle zusammen mit der Simulationszeit (siehe unten) zur Darstellung in LaTeX
    Tabelle_THD(index_zwei,1) = Tabelle_NoS(1,1);
    Tabelle_THD(index_zwei,2) = table(Tabelle_Table_Extrahierung_round(1,1));
    
    end
    end
    
    %% Daten der prozentualen Abweichung und Simulationszeit liegen jetzt alle in Tabellen vor 
    %Abspeichern der extrahierten Daten in Textdateien zur Darstellung in LaTeX
    %umbenennen der Spaltennamen x und y zum plotten 
    Tabelle_NoS_Prozentuale_Abweichung.Properties.VariableNames = ["x","y"];
    %bestimmt wo die Textdateien abgespeichert werden
    table_path_format_NoS_Prozentuale_Abweichung = fullfile(Ordner_Verlauf_Simulationszeit_Prozentuale_Abweichung, "AP"+index_AP_str+"_Prozentuale_Abweichung_"+NoS_str+".txt");
    %ausgeben der Tabelle für die Prozentuale Abweichung (y-Achse) über der Simulationszeit (x-Achse) als Textdatei
    writetable(Tabelle_NoS_Prozentuale_Abweichung,table_path_format_NoS_Prozentuale_Abweichung,"Delimiter"," ");

    %% Daten der prozentualen Abweichung und Simulationszeit liegen jetzt alle in Tabellen vor 
    %Abspeichern der extrahierten Daten in Textdateien zur Darstellung in LaTeX
    %umbenennen der Spaltennamen x und y zum plotten 
    Tabelle_NoS_Simulationszeit.Properties.VariableNames = ["x","y"];
    %bestimmt wo die Textdateien abgespeichert werden
    table_path_format_NoS_Simulationszeit = fullfile(Ordner_Verlauf_Simulationszeit_Prozentuale_Abweichung, "AP"+index_AP_str+"_Simulationszeit_"+NoS_str+".txt");
    %ausgeben der Tabelle für die Prozentuale Abweichung (y-Achse) über der Simulationszeit (x-Achse) als Textdatei
    writetable(Tabelle_NoS_Simulationszeit,table_path_format_NoS_Simulationszeit,"Delimiter"," ");
    
    %% Daten der prozentualen Abweichung und Simulationszeit liegen jetzt alle in Tabellen vor 
    %Abspeichern der extrahierten Daten in Textdateien zur Darstellung in LaTeX
    %umbenennen der Spaltennamen x und y zum plotten 
    Tabelle_THD.Properties.VariableNames = ["x","y"];
    %bestimmt wo die Textdateien abgespeichert werden
    table_path_format_THD = fullfile(Ordner_Verlauf_Simulationszeit_Prozentuale_Abweichung, "AP"+index_AP_str+"_THD_"+NoS_str+".txt");
    %ausgeben der Tabelle für die Prozentuale Abweichung (y-Achse) über der Simulationszeit (x-Achse) als Textdatei
    writetable(Tabelle_THD,table_path_format_THD,"Delimiter"," ");
    fprintf("AP%u: Daten wurden erfolgreich abgespeichert. \n",index_AP);
    
end
% Ende der Variation der AP

