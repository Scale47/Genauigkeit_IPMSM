%% Es wurden alle "warnings deaktiviert" weil es die Anzeige sinnvoller Informationen gestört hat
% Mit diesem Befehl schaltet man die Warnungen an/ab: w = warning ('off','all');
% Einfach on zu off tauschen, in die Commandozeile einfügen, fertig

% NoElP/(2*frq_el)
% 1/frq_el*(1/6 + (1/6*1/4.023416))

% Warnungen in Kommandozeile ausschalten
w = warning ('off','all');
%% Working Directory anpassen
% Dateipfad dieses Skripts
sActiveFilename = matlab.desktop.editor.getActiveFilename; 
% Ordnerpfad zu diesem Skript
sMainPath = fileparts(sActiveFilename); 
% Working Directory wechseln
cd(sMainPath); 
sPlotPath = fullfile(fileparts(fileparts(sMainPath)),'PrÃ¤sentationen','20220302_PrÃ¤sentation Abschlussbericht 2022');

%% Maxwell-Schnittstelle
% Name Ansys Projekt
sProject = "IPMSMs"; 
% Name Design
sDesign2D = "010_Feinmodell_PPE"; 
% Ansys Fenster oeffnet sich
oAnsoftApp = actxserver('Ansoft.ElectronicsDesktop');  
% schnappt sich aktuelles Fenster
oDesktop   = oAnsoftApp.GetAppDesktop(); oDesktop.RestoreWindow;     
try 
% schon offen
    % aktiv schalten
    oProject = oDesktop.SetActiveProject(sProject); 
% Projekt nicht offen
catch 
    oProject = oDesktop.OpenProject(fullfile(sMainPath,sprintf('%s.aedt',sProject))); % Oeffnen des Projektes
end
% gewuenschtes Design aktiv schalten
oDesign2D = oProject.SetActiveDesign(sDesign2D); 

%%  Definition aller Variablen und Funktionen für die variation des Arbeitspunktes

%% Definition aller Variablen und Funktionen für die Berechnung des Referenzwertes
Anzahl_Arbeitspunkte = 5;
%Erstellen eines "cell arrays" für die Daten des Simulationszeiten
Simulationszeit_Cell_aequidistant_1026 = cell(1,1);
%Erstellen eines "cell arrays" für die Daten des Drehmomentes
Drehmoment_Cell_aequidistant_1026 = cell(1,1);
%Erstellen eines "cell arrays" für die Daten des Strom
Strom_Cell_aequidistant_1026 = cell(1,1);
%Erstellen eines "cell arrays" für die Daten der Wirbelstromverluste
Wirbelstromverluste_gesamt_Cell_aequidistant_1026 = cell(1,1);
%Erstellen eines "cell arrays" für die Daten der Wirbelstromverluste (Mittelwert)
Wirbelstromverluste_Mittelwert_Cell_aequidistant_1026 = cell(1,1);


%% Definition aller Variablen und Funktionen für die Variation der NoS
%Anzahl der Simulationen durch Vorgabe der Anzahl von for-Durchläufen
Anzahl_Simulationen = 6;
%Definition um wie viel sich die NoS pro Iteration erhöhen
Erhoehung_NoS_pro_Schritt = 90;
%Definition bei welchem Wert die 1. Iteration starten soll
Start_NoS = 360;
%Erstellen einer temporären "table" für die Daten der Simulationen
temporaer_table = table();
%Erstellen eines "cell arrays" für die Daten des Simulationszeiten
Simulationszeit_Cell_aequidistant_180_900 = cell(1,Anzahl_Simulationen);
%Erstellen eines "cell arrays" für die Daten des Drehmomentes
Drehmoment_Cell_aequidistant_180_900 = cell(1,Anzahl_Simulationen);
%Erstellen eines "cell arrays" für die Daten des Strom
Strom_Cell_aequidistant_180_900 = cell(1,Anzahl_Simulationen);
%Erstellen eines "cell arrays" für die Daten der Wirbelstromverluste
Wirbelstromverluste_gesamt_Cell_aequidistant_180_900 = cell(1,Anzahl_Simulationen);
%Erstellen eines "cell arrays" für die Daten der Wirbelstromverluste
Wirbelstromverluste_Mittelwert_Cell_aequidistant_180_900 = cell(1,Anzahl_Simulationen);
%Erstellen eines "cell arrays" für die Daten der Wirbelstromverluste
Prozentuale_Abweichung_Simulation_Cell_aequidistant_180_900 = cell(1,Anzahl_Simulationen);


% Erstellung von Strings zur Benennung
Erste_NoS_str = num2str(Start_NoS+Erhoehung_NoS_pro_Schritt);
Letzte_NoS_str = num2str(Start_NoS+Anzahl_Simulationen*Erhoehung_NoS_pro_Schritt);

% Definition von Zählern für die Arbeitspunktstabelle
Zaehler_I_rms = 2;
Zaehler_frq_el = 3;
Zaehler_zdTheta = 4;

for index_AP = 1:Anzahl_Arbeitspunkte
    
    formatOut = "mm_dd_yy";
    d = datestr(now,formatOut);
    d_str = num2str(d);
    
    T = readtable("APe_1_5.xlsx");
    C = table2cell(T);
    I_rms = C{index_AP,Zaehler_I_rms};
    frq_el = C{index_AP,Zaehler_frq_el};
    zdTheta = C{index_AP,Zaehler_zdTheta};
    %% Festlegung der Arbeitspunkte
    % Variable in den Design Properties anpassen EFFEKTIVSTROM
    mwChangeDesignVariable(oDesign2D, 'I_rms',I_rms, 'A');
    % Variable in den Design Properties anpassen ELEKTRISCHE FREQUENZ
    mwChangeDesignVariable(oDesign2D, 'frq_el', frq_el, 'Hz');
    % Variable in den Design Properties anpassen POLRADLAGEWINKEL
    mwChangeDesignVariable(oDesign2D, 'zdTheta', zdTheta, 'deg');    

    index_AP_str = num2str(index_AP);
    
    %% Simulation um Refernzwert für den Arbeitspunkt zu berechnen
    %Definition einer Variable für "Number of Segments" in Abhängigkeit des Index
    NoS = 1026;
    %Umwandlung der Variable NoS in einen "String"
    NoS_str = num2str(NoS);
    
    AP = index_AP;
    AP_str = num2str(AP);
    
    % Variable in den Design Properties anpassen NUMBER OF SEGMENTS
    mwChangeDesignVariable(oDesign2D, 'NoSegm', NoS, '');
    
    % Start des Timers zur Messung der Simulationszeit
    tiSimStart = tic; % Zeit starten
    % Design analysieren
    oDesign2D.Analyze('Setup1');
    % Stoppen der Simulationszeit
    StopZeit = toc(tiSimStart); 
    fprintf("AP%u: Simulation für den Referenzwert mit %u Segmenten nach %.2f min fertig. \n",index_AP, NoS, StopZeit/60);
    
    %% Ergebnis aus Maxwell exportieren
    oModule = oDesign2D.GetModule("ReportSetup");
    oModule.UpdateReports(["Drehmoment", "Stroeme","Wirbelstromverluste_gesamt","Wirbelstromverluste_Mittelwert"]); % Reports updaten (nicht wÃ¤hrend der Simulation, erst am Schluss!)
    oModule.ExportToFile("Drehmoment", fullfile(sMainPath,"Drehmoment.csv"), false);
    oModule.ExportToFile("Stroeme", fullfile(sMainPath,"Stroeme.csv"), false);
    oModule.ExportToFile("Wirbelstromverluste_gesamt", fullfile(sMainPath,"Wirbelstromverluste_gesamt.csv"), false);
    oModule.ExportToFile("Wirbelstromverluste_Mittelwert", fullfile(sMainPath,"Wirbelstromverluste_Mittelwert.csv"), false);
    
    %% Daten einlesen und in Matlab-Cell-Array ablegen - SIMULATIONSZEIT
    % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
    temporaer_table = table(StopZeit);
    % Bezeichnung der Spalten geeignet ändern
    temporaer_table.Properties.VariableNames = "Simulationszeit_s_"+NoS_str;
    % abspeichern der Daten jedes Simulationsdurchlaufes der Variabel "Drehmoment" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
    Simulationszeit_Cell_aequidistant_1026(:,1) = {temporaer_table};
    
    %% Daten einlesen und in Matlab-Cell-Array ablegen - DREHMOMENT
    % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
    temporaer_table = readtable(fullfile(sMainPath,"Drehmoment.csv"));
    % Bezeichnung der Spalten geeignet ändern
    temporaer_table.Properties.VariableNames = ["Time_Feinmodell"+NoS_str,"Moving_Torque__Nm__"+NoS_str];
    % abspeichern der Daten jedes Simulationsdurchlaufes der Variabel "Drehmoment" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
    Drehmoment_Cell_aequidistant_1026(:,1) = {temporaer_table};
    
    %% Daten einlesen und in Matlab-Cell-Array ablegen - STROM
    % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
    temporaer_table = readtable(fullfile(sMainPath,"Stroeme.csv"));
    % Bezeichnung der Spalten geeignet ändern
    temporaer_table.Properties.VariableNames = ["Time_Feinmodell"+NoS_str,"InputCurrent_Phase_A__A__"+NoS_str,"InputCurrent_Phase_B__A__"+NoS_str,"InputCurrent_Phase_C__A__"+NoS_str];
    % abspeichern der Daten jedes Simulationsdurchlaufes der Variable "Strom" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
    Strom_Cell_aequidistant_1026(:,1) = {temporaer_table};
    
    %% Daten einlesen und in Matlab-Cell-Array ablegen - WIRBELSTROMVERLUSTE
    % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
    temporaer_table = readtable(fullfile(sMainPath,"Wirbelstromverluste_gesamt.csv"));
    % Bezeichnung der Spalten geeignet ändern
    temporaer_table.Properties.VariableNames = ["Time_Feinmodell"+NoS_str,"Wirbelstromverluste_gesamt__W__"+NoS_str];
    % abspeichern der Daten jedes Simulationsdurchlaufes der Variabel "Drehmoment" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
    Wirbelstromverluste_gesamt_Cell_aequidistant_1026(:,1) = {temporaer_table};
    
    %% Daten einlesen und in Matlab-Cell-Array ablegen - WIRBELSTROMVERLUSTE MITTELWERT
    % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
    temporaer_table = readtable(fullfile(sMainPath,"Wirbelstromverluste_Mittelwert.csv"));
    % Bezeichnung der Spalten geeignet ändern
    temporaer_table.Properties.VariableNames = ["Time_Feinmodell"+NoS_str,"Wirbelstromverluste_Mittelwert__W__"+NoS_str];
    % abspeichern der Daten jedes Simulationsdurchlaufes der Variabel "Drehmoment" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
    Wirbelstromverluste_Mittelwert_Cell_aequidistant_1026(:,1) = {temporaer_table};

    %bereinigt den Ordner IPMSMs.aedtresults
    oDesign2D.DeleteFullVariation("All", false);
%% Schleife zur Variation der NoS Abweichung
for index = 1:Anzahl_Simulationen

    %% Definition aler Variablen und Funktionen in Abhängigkeit der "for-Schleife" 
    %Definition einer Variable für "Number of Segments" in Abhängigkeit des Index
    NoS = Start_NoS+index*Erhoehung_NoS_pro_Schritt;
    %Umwandlung der Variable NoS in einen "String"
    NoS_str = num2str(NoS);
    
    NoS_Max = 1026;
    NoS_Max_str = num2str(NoS_Max);

    % Variable in den Design Properties anpassen NUMBER OF SEGMENTS
    mwChangeDesignVariable(oDesign2D, 'NoSegm', NoS, '');

    % Start des Timers zur Messung der Simulationszeit
    tiSimStart = tic; % Zeit starten
    % Design analysieren
    oDesign2D.Analyze('Setup1');
    % Stoppen der Simulationszeit
    StopZeit = toc(tiSimStart); 
    fprintf("AP%u: Simulation %u mit %u Segmenten nach %.2f min fertig. \n",index_AP, index, NoS, StopZeit/60);
    
    %% Ergebnis aus Maxwell exportieren
    oModule = oDesign2D.GetModule("ReportSetup");
    oModule.UpdateReports(["Drehmoment", "Stroeme","Wirbelstromverluste_gesamt","Wirbelstromverluste_Mittelwert"]); % Reports updaten (nicht wÃ¤hrend der Simulation, erst am Schluss!)
    oModule.ExportToFile("Drehmoment", fullfile(sMainPath,"Drehmoment.csv"), false);
    oModule.ExportToFile("Stroeme", fullfile(sMainPath,"Stroeme.csv"), false);
    oModule.ExportToFile("Wirbelstromverluste_gesamt", fullfile(sMainPath,"Wirbelstromverluste_gesamt.csv"), false);
    oModule.ExportToFile("Wirbelstromverluste_Mittelwert", fullfile(sMainPath,"Wirbelstromverluste_Mittelwert.csv"), false);
    
    %% Daten einlesen und in Matlab-Cell-Array ablegen - SIMULATIONSZEIT
    % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
    temporaer_table = table(StopZeit);
    % Bezeichnung der Spalten geeignet ändern
    temporaer_table.Properties.VariableNames = "Simulationszeit_s_"+NoS_str;
    % abspeichern der Daten jedes Simulationsdurchlaufes der Variabel "Drehmoment" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
    Simulationszeit_Cell_aequidistant_180_900(:,index) = {temporaer_table};
    
    %% Daten einlesen und in Matlab-Cell-Array ablegen - DREHMOMENT
    % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
    temporaer_table = readtable(fullfile(sMainPath,"Drehmoment.csv"));
    % Bezeichnung der Spalten geeignet ändern
    temporaer_table.Properties.VariableNames = ["Time_Feinmodell"+NoS_str,"Moving_Torque__Nm__"+NoS_str];
    % abspeichern der Daten jedes Simulationsdurchlaufes der Variabel "Drehmoment" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
    Drehmoment_Cell_aequidistant_180_900(:,index) = {temporaer_table};
    
    %% Daten einlesen und in Matlab-Cell-Array ablegen - STROM
    % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
    temporaer_table = readtable(fullfile(sMainPath,"Stroeme.csv"));
    % Bezeichnung der Spalten geeignet ändern
    temporaer_table.Properties.VariableNames = ["Time_Feinmodell"+NoS_str,"InputCurrent_Phase_A__A__"+NoS_str,"InputCurrent_Phase_B__A__"+NoS_str,"InputCurrent_Phase_C__A__"+NoS_str];
    % abspeichern der Daten jedes Simulationsdurchlaufes der Variable "Strom" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
    Strom_Cell_aequidistant_180_900(:,index) = {temporaer_table};
    
    %% Daten einlesen und in Matlab-Cell-Array ablegen - WIRBELSTROMVERLUSTE
    % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
    temporaer_table = readtable(fullfile(sMainPath,"Wirbelstromverluste_gesamt.csv"));
    % Bezeichnung der Spalten geeignet ändern
    temporaer_table.Properties.VariableNames = ["Time_Feinmodell"+NoS_str,"Wirbelstromverluste_gesamt__W__"+NoS_str];
    % abspeichern der Daten jedes Simulationsdurchlaufes der Variabel "Drehmoment" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
    Wirbelstromverluste_gesamt_Cell_aequidistant_180_900(:,index) = {temporaer_table};
    
    %% Daten einlesen und in Matlab-Cell-Array ablegen - WIRBELSTROMVERLUSTE MITTELWERT
    % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
    temporaer_table = readtable(fullfile(sMainPath,"Wirbelstromverluste_Mittelwert.csv"));
    % Bezeichnung der Spalten geeignet ändern
    temporaer_table.Properties.VariableNames = ["Time_Feinmodell"+NoS_str,"Wirbelstromverluste_Mittelwert__W__"+NoS_str];
    % abspeichern der Daten jedes Simulationsdurchlaufes der Variabel "Drehmoment" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
    Wirbelstromverluste_Mittelwert_Cell_aequidistant_180_900(:,index) = {temporaer_table};
    

    %% Berechnung der prozentualen Abweichung der Mittelwerte (Wirbelstromverluste) innerhalb einer Iteration
    Wert_Eins = Wirbelstromverluste_Mittelwert_Cell_aequidistant_180_900{:,index};
    Iteration_Eins = Wert_Eins{:,2};
    Iteration_Zwei = Wirbelstromverluste_Mittelwert_Cell_aequidistant_1026{1,1}{1,2};
    Prozentuale_Abweichung_Simulationen = abs((Iteration_Zwei-Iteration_Eins)/Iteration_Zwei*100);
    %Abspeichern in "cell"
    % Einlesen der Daten aus gewähltem .csv File in MATLAB Tabelle
    temporaer_table = table(Prozentuale_Abweichung_Simulationen);
    % Bezeichnung der Spalten geeignet ändern
    temporaer_table.Properties.VariableNames = "Prozentuale_Abweichung_Simulationen_"+NoS_str+"_zu_"+NoS_Max_str;
    % abspeichern der Daten jedes Simulationsdurchlaufes der Variabel " Prozentuale_Abweichung_Simulationen" in einer neuen Zelle (spaltenweise) in Abhängigkeit des Index
    Prozentuale_Abweichung_Simulation_Cell_aequidistant_180_900(:,index) = {temporaer_table};
    %Ausgabe der aktuellen Abweichung
    fprintf("AP%u: Die aktuelle Abweichung einer Anzahl der NoS von %u zu %d beträgt %.2f%%. \n",index_AP, NoS, NoS_Max, Prozentuale_Abweichung_Simulationen);
    if Prozentuale_Abweichung_Simulationen<1
        fprintf("AP%u: Die aktuelle Abweichung beträgt weniger als 1%% (%.2f%%). Das Simulationsziel wurde erreicht. \n",index_AP, Prozentuale_Abweichung_Simulationen);
    end
    filename = "AP"+AP_str+"_Simulation_"+Erste_NoS_str+"_"+Letzte_NoS_str+"_"+d_str+"_Feinmodell_volle_Periode.mat";
    save(filename)
    %bereinigt den Ordner IPMSMs.aedtresults
    oDesign2D.DeleteFullVariation("All", false);
% Ende Variation NoS Abweichung  
end

%% Abspeichern der Werte eines Arbeitspunktes
%% Definieren aller Variablen und Funktionen
Anzahl_durchgefuehrter_Simulationen = index;
Start_NoS_Auswertung = Start_NoS+Erhoehung_NoS_pro_Schritt;
NoS_Benennung = Start_NoS_Auswertung;
Nos_Max = Start_NoS+Anzahl_durchgefuehrter_Simulationen*Erhoehung_NoS_pro_Schritt;
Nos_Max_str = num2str(Nos_Max);
Nos_Min_str = num2str(Start_NoS_Auswertung);

% Erstellen zweier Tabellen
Tabelle_NoS_Prozentuale_Abweichung = table();
Tabelle_NoS_Simulationszeit = table();

%% Definieren der Ordner zu abspeichern der Textdateien
Ordner_Verlauf_Wirbelstromverluste = "C:\Users\scale\Desktop\Daten Netzspeisung 450 bis 900 fuer AP 1 bis 5_100 Prozent";
Ordner_Verlauf_Simulationszeit_Prozentuale_Abweichung = "C:\Users\scale\Desktop\Daten Netzspeisung 450 bis 900 fuer AP 1 bis 5_100 Prozent";
Ordner_Daten_Simulationszeit_Abweichung = "C:\Users\scale\Desktop\Daten Netzspeisung 450 bis 900 fuer AP 1 bis 5_100 Prozent";


%% Extrahieren von Daten aus "cell" und exportieren in Textdateien zur Darstellung in LaTex
for index_zwei = 1:Anzahl_durchgefuehrter_Simulationen
if index_zwei>1
    NoS_Benennung = (index_zwei-1)*Erhoehung_NoS_pro_Schritt+Start_NoS_Auswertung;
end
NoS_Benennung_str = num2str(NoS_Benennung);

%Tabelle mit NoS Werten
NoS_Bennenung_Cell = cell(1,1);
NoS_Bennenung_Cell{1,1} =  NoS_Benennung;
Tabelle_NoS= table();
Tabelle_NoS(1,1)= NoS_Bennenung_Cell(1,1);

%% Verlauf der Wirbelstromverluste
%definieren aus welchem "cell" Daten extrahiert werden sollen, hier wird der jeweilige Speicherplatz der "cell" in einer "table" abgespeichert 
Tabelle_Verlauf_Wirbelstromverluste = Wirbelstromverluste_gesamt_Cell_aequidistant_180_900{:,index_zwei};
%runden aller Werte in der Tabelle
Tabelle_Verlauf_Wirbelstromverluste{:,:} = round(Tabelle_Verlauf_Wirbelstromverluste.Variables, 6);
%umbenennen der Spaltennamen x und y zum plotten 
Tabelle_Verlauf_Wirbelstromverluste.Properties.VariableNames = ["x","y"];
%bestimmt wo die Textdateien abgespeichert werden
table_path_format_Verlauf_Wireblstromverluste = fullfile(Ordner_Verlauf_Wirbelstromverluste, "AP"+index_AP_str+"_Wirbelstromverluste_Verlauf_"+NoS_Benennung_str+".txt");
%ausgeben der Tabelle für die Prozentuale Abweichung als Textdatei für jede einzelne Simulation in einer seperaten Textdatei
writetable(Tabelle_Verlauf_Wirbelstromverluste,table_path_format_Verlauf_Wireblstromverluste,"Delimiter"," ");
    
%wie man Daten aus einem "cell" extrahiert und in eine Tabelle schreibt
%% Prozentuale Abweichung
%definieren aus welchem "cell" Daten extrahiert werden sollen
Tabelle_Cell_Extrahierung_Indexierung = table(Prozentuale_Abweichung_Simulation_Cell_aequidistant_180_900{:,index_zwei});
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
Tabelle_Cell_Extrahierung_Indexierung = table(Simulationszeit_Cell_aequidistant_180_900{:,index_zwei});
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
end
%% Daten der prozentualen Abweichung und Simulationszeit liegen jetzt alle in Tabellen vor 
%Abspeichern der extrahierten Daten in Textdateien zur Darstellung in LaTeX
%umbenennen der Spaltennamen x und y zum plotten 
Tabelle_NoS_Prozentuale_Abweichung.Properties.VariableNames = ["x","y"];
%bestimmt wo die Textdateien abgespeichert werden
table_path_format_NoS_Prozentuale_Abweichung = fullfile(Ordner_Verlauf_Simulationszeit_Prozentuale_Abweichung, "AP"+index_AP_str+"_NoS_Prozentuale_Abweichung_"+Nos_Min_str+"_"+Nos_Max_str+".txt");
%ausgeben der Tabelle für die Prozentuale Abweichung (y-Achse) über der Simulationszeit (x-Achse) als Textdatei
writetable(Tabelle_NoS_Prozentuale_Abweichung,table_path_format_NoS_Prozentuale_Abweichung,"Delimiter"," ");

%% Daten der prozentualen Abweichung und Simulationszeit liegen jetzt alle in Tabellen vor 
%Abspeichern der extrahierten Daten in Textdateien zur Darstellung in LaTeX
%umbenennen der Spaltennamen x und y zum plotten 
Tabelle_NoS_Simulationszeit.Properties.VariableNames = ["x","y"];
%bestimmt wo die Textdateien abgespeichert werden
table_path_format_NoS_Simulationszeit = fullfile(Ordner_Verlauf_Simulationszeit_Prozentuale_Abweichung, "AP"+index_AP_str+"_NoS_Simulationszeit_"+Nos_Min_str+"_"+Nos_Max_str+".txt");
%ausgeben der Tabelle für die Prozentuale Abweichung (y-Achse) über der Simulationszeit (x-Achse) als Textdatei
writetable(Tabelle_NoS_Simulationszeit,table_path_format_NoS_Simulationszeit,"Delimiter"," ");
fprintf("AP%u: Daten wurden erfolgreich abgespeichert. \n",index_AP);
% Ende Variation Arbeitspunkte 
end