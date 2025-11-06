%% ==========================================================================
%  PRIORITY 4.1-4.5: COMPREHENSIVE CLINICAL ASSOCIATIONS ANALYSIS
%  ==========================================================================
%  Author: Nikos Diederichs
%  Date: October 26, 2025
%  For: Clara V - NESDA Clinical Associations Phase 2
%  Version: 3.5 - CORRECTED MEDICATION VARIABLE CODING
%  MODIFIED: October 29, 2025 - Fixed _fr variable interpretation
%                               + Proper handling of frequency (0/1/2) vs binary (0/1)
%  MODIFIED: [Current Date] - Updated to OOCV-26 and OOCV-27
%
%  DECISION SCORE VERSIONS USED:
%  - Transition: OOCV-26 (Version A - Dynamic Std) [PRIMARY]
%  - Transition: OOCV-27 (Version B - Site-agnostic) [SENSITIVITY]
%  - bvFTD: OOCV-6 (Dynamic Std)
%
%  ANALYSES INCLUDED:
%  - 4.1: Metabolic Subtypes & BMI
%  - 4.2: Symptom Severity (11 variables) + ENHANCED PCA (PC1, PC2, PC3)
%  - 4.3: Clinical History (21 variables including illness duration)
%  - 4.4: Cognition & Functioning
%  - 4.4B: Medication Analysis (PATIENTS ONLY) - CORRECTED CODING
%  - NEW 9C: Recency Stratified Analysis (OPTION 6)
%  - 4.5: Comprehensive Statistical Summary (ALL 40+ VARIABLES)
%  - NEW: Forest Plots for BOTH Transition-26 AND bvFTD
%  - NEW: Complete PC1, PC2, PC3 correlations with all decision scores
%  ==========================================================================

clear; clc; close all;
fprintf('---------------------------------------------------\n');
fprintf('| PRIORITY 4.1-4.5: COMPREHENSIVE CLINICAL ANALYSIS |\n');
fprintf('---------------------------------------------------\n');
fprintf('Start time: %s\n\n', datestr(now));

%% ==========================================================================
%  SECTION 0: VARIABLE LABEL MAPPING (NEW!)
%  ==========================================================================
fprintf('---------------------------------------------------\n');
fprintf('SECTION 0: VARIABLE LABEL MAPPING\n');
fprintf('---------------------------------------------------\n\n');

% Create interpretable labels for all clinical variables
variable_labels = containers.Map();

% Symptom Severity Variables
variable_labels('aids') = 'Depression Total (IDS-SR)';
variable_labels('aidssev') = 'Depression Severity';
variable_labels('aids_mood_cognition') = 'Depression: Mood/Cognition';
variable_labels('aids_anxiety_arousal') = 'Depression: Anxiety/Arousal';
variable_labels('aidsatyp') = 'Atypical Depression';
variable_labels('aidsmel') = 'Melancholic Depression';
variable_labels('abaiscal') = 'Anxiety Total (BAI)';
variable_labels('abaisev') = 'Anxiety Severity';
variable_labels('abaisom') = 'Anxiety: Somatic';
variable_labels('abaisub') = 'Anxiety: Subjective';
variable_labels('aauditsc') = 'Alcohol Use (AUDIT)';

% Age of Onset
variable_labels('AD2962xAO') = 'Age Onset - MDD';
variable_labels('AD2963xAO') = 'Age Onset - Dysthymia';
variable_labels('AD3004AO') = 'Age Onset - Any Depression';

% Illness Duration
variable_labels('AD2962xDuration') = 'Illness Duration - MDD (yrs)';
variable_labels('AD2963xDuration') = 'Illness Duration - Dysthymia (yrs)';
variable_labels('AD3004Duration') = 'Illness Duration - Any Depression (yrs)';

% Recency Variables (NEW - OPTION 6)
variable_labels('AD2962xRE') = 'Recency - Single MDD';
variable_labels('AD2963xRE') = 'Recency - Recurrent MDD';
variable_labels('AD3004RE') = 'Recency - Dysthymia';

% Clinical History
variable_labels('acidep10') = 'N Depressive Episodes';
variable_labels('acidep11') = 'Months Current Episode';
variable_labels('acidep13') = 'N Remitted Episodes';
variable_labels('acidep14') = 'N Chronic Episodes';
variable_labels('aanxy21') = 'Age First Anxiety';
variable_labels('aanxy22') = 'N Anxiety Episodes';
variable_labels('ANDPBOXSX') = 'N Depressive Symptoms (Lifetime)';
variable_labels('acontrol') = 'Perceived Control';
variable_labels('afamhdep') = 'Family History Depression';
variable_labels('appfmuse#') = 'N Medications';
variable_labels('atca_ddd') = 'TCA Dose (DDD)';
variable_labels('assri_ddd') = 'SSRI Dose (DDD)';
variable_labels('aotherad_ddd') = 'Other Antidep Dose (DDD)';

% Medication FREQUENCY Variables (_fr suffix: 0=No, 1=Infrequent, 2=Frequent)
variable_labels('assri_fr') = 'SSRI Frequency (0/1/2)';
variable_labels('abenzo_fr') = 'Benzodiazepine Frequency (0/1/2)';
variable_labels('atca_fr') = 'TCA Frequency (0/1/2)';
variable_labels('apsychotropic_fr') = 'Any Psychotropic Frequency (0/1/2)';
variable_labels('aother_ad_fr') = 'Other Antidep Frequency (0/1/2)';
variable_labels('aantipsychotic_fr') = 'Antipsychotic Frequency (0/1/2)';
variable_labels('ahypnotic_sedative_fr') = 'Hypnotic/Sedative Frequency (0/1/2)';
variable_labels('aanxiolytic_fr') = 'Anxiolytic Frequency (0/1/2)';
variable_labels('aother_psychotropic_fr') = 'Other Psychotropic Frequency (0/1/2)';

% Medication BINARY Variables (no _fr suffix: 0=No, 1=Yes)
variable_labels('assri') = 'SSRI Use (Binary Yes/No)';
variable_labels('abenzo') = 'Benzodiazepine Use (Binary Yes/No)';
variable_labels('atca') = 'TCA Use (Binary Yes/No)';
variable_labels('apsychotropic') = 'Any Psychotropic Use (Binary Yes/No)';
variable_labels('aother_ad') = 'Other Antidep Use (Binary Yes/No)';
variable_labels('aantipsychotic') = 'Antipsychotic Use (Binary Yes/No)';
variable_labels('ahypnotic_sedative') = 'Hypnotic/Sedative Use (Binary Yes/No)';
variable_labels('aanxiolytic') = 'Anxiolytic Use (Binary Yes/No)';
variable_labels('aother_psychotropic') = 'Other Psychotropic Use (Binary Yes/No)';

variable_labels('aother_ad_ddd') = 'Other Antidep Dose (DDD)';
variable_labels('n_psychotropic_classes') = 'N Psychotropic Classes';

% TASK 5.3: BENDEP scales
variable_labels('asumbd1') = 'BENDEP: Problematic Use';
variable_labels('asumbd2') = 'BENDEP: Preoccupation';
variable_labels('asumbd3') = 'BENDEP: Lack of Compliance';

% Childhood Adversity
variable_labels('ACTI_total') = 'Childhood Trauma Total';
variable_labels('ACLEI') = 'Childhood Life Events';
variable_labels('aseparation') = 'Parental Separation';
variable_labels('adeathparent') = 'Parental Death';
variable_labels('adivorce') = 'Parental Divorce';

% Demographics
variable_labels('Age') = 'Age (years)';
variable_labels('Sexe') = 'Sex (1=M, 2=F)';
variable_labels('abmi') = 'BMI (kg/m²)';
variable_labels('aedu') = 'Education (years)';
variable_labels('amarpart') = 'Marital Status';
variable_labels('aarea') = 'Geographic Site';
variable_labels('aLCAsubtype') = 'Metabolic Subtype';

% Alternative names used in analysis (from Section 8B demographics)
variable_labels('BMI') = 'BMI (kg/m²)';
variable_labels('Sex') = 'Sex (1=M, 2=F)';
variable_labels('Education') = 'Education (years)';
variable_labels('Marital_Status') = 'Marital Status';

% Helper function - robust version with error handling
get_label = @(v) get_label_safe(v, variable_labels);

fprintf('  Initialized %d variable labels\n\n', variable_labels.Count);


%% ==========================================================================
%  SECTION 1: SETUP PATHS AND CREATE OUTPUT DIRECTORIES
%  ==========================================================================
fprintf('SECTION 1: SETTING UP PATHS\n');
fprintf('--------------------------------------------------\n');

base_path = '/volume/projects/CV_NESDA/';
data_path = [base_path 'Data/tabular_data/'];
transition_path_base = [base_path 'Analysis/Transition_Model/Decision_Scores_Mean_Offset/'];
bvftd_path_base = [base_path 'Analysis/bvFTD/Decision_Scores_bvFTD/'];
results_path = [base_path 'Analysis/Transition_Model/Decision_Scores_Mean_Offset/Results_Figures/'];

% Diagnosis data paths
diagnosis_hc_file = [base_path 'Data/NESDA_Waves/Wave_1/DynStd_Preparation/NESDA_HC.csv'];
diagnosis_patients_file = [base_path 'Data/NESDA_Waves/Wave_1/DynStd_Preparation/NESDA_Patients.csv'];

if ~exist(results_path, 'dir')
    mkdir(results_path);
end

fig_path = [results_path 'Figures/'];
data_out_path = [results_path 'Data/'];
if ~exist(fig_path, 'dir'), mkdir(fig_path); end
if ~exist(data_out_path, 'dir'), mkdir(data_out_path); end

fprintf('  Output directory: %s\n', results_path);
fprintf('  Figure output: %s\n', fig_path);
fprintf('  Data output: %s\n\n', data_out_path);

diary([results_path 'Priority_4_1_to_4_5_Complete_Analysis_Log_OOCV26_27.txt']);
fprintf('Logging to: %sPriority_4_1_to_4_5_Complete_Analysis_Log_OOCV26_27.txt\n\n', results_path);

%% ==========================================================================
%  SECTION 2: LOAD NESDA CLINICAL DATA
%  ==========================================================================
fprintf('---------------------------------------------------\n');
fprintf('SECTION 2: LOADING NESDA CLINICAL DATA\n');
fprintf('---------------------------------------------------\n\n');

nesda_file = [data_path 'NESDA_tabular_combined_data.csv'];
fprintf('Loading: %s\n', nesda_file);

if ~exist(nesda_file, 'file')
    error('ERROR: NESDA clinical data file not found: %s', nesda_file);
end

nesda_data = readtable(nesda_file, 'Delimiter', ',', 'VariableNamingRule', 'preserve');

fprintf('  Data loaded: [%d × %d] TABLE\n', height(nesda_data), width(nesda_data));
varnames = nesda_data.Properties.VariableNames;
fprintf('  First 5 variables: %s\n\n', strjoin(varnames(1:min(5,length(varnames))), ', '));

fprintf('CHECKING FOR KEY VARIABLES:\n');
fprintf('--------------------------------------------------\n');

id_vars = {'pident', 'PIDENT', 'ID', 'SubjectID', 'subject_id'};
id_var = '';
for v = 1:length(id_vars)
    if ismember(id_vars{v}, nesda_data.Properties.VariableNames)
        id_var = id_vars{v};
        fprintf('  ID variable found: %s\n', id_var);
        break;
    end
end
if isempty(id_var)
    error('ERROR: No ID variable found! Searched for: %s', strjoin(id_vars, ', '));
end

sample_ids = nesda_data.(id_var);
if isnumeric(sample_ids)
    fprintf('    Sample IDs (first 5): %d, %d, %d, %d, %d\n', ...
        sample_ids(1), sample_ids(2), sample_ids(3), sample_ids(4), sample_ids(5));
elseif iscell(sample_ids)
    fprintf('    Sample IDs (first 5): %s, %s, %s, %s, %s\n', ...
        sample_ids{1}, sample_ids{2}, sample_ids{3}, sample_ids{4}, sample_ids{5});
end

fprintf('\n');

%% ==========================================================================
%  SECTION 2B: DEFINE ALL 40+ CLINICAL VARIABLES
%  ==========================================================================
fprintf('---------------------------------------------------\n');
fprintf('SECTION 2B: CHECKING CLINICAL VARIABLES\n');
fprintf('---------------------------------------------------\n\n');

symptom_vars = {'aids', 'aidssev', 'aids_mood_cognition', 'aids_anxiety_arousal', ...
                'aidsatyp', 'aidsmel', 'abaiscal', 'abaisev', 'abaisom', 'abaisub', 'aauditsc'};

age_onset_vars = {'AD2962xAO', 'AD2963xAO', 'AD3004AO'};

% NEW: Recency variables (OPTION 6)
recency_vars = {'AD2962xRE', 'AD2963xRE', 'AD3004RE'};

clinical_history_vars = {'acidep10', 'acidep11', 'acidep13', 'acidep14', ...
                        'aanxy21', 'aanxy22', 'ANDPBOXSX', 'acontrol', ...
                        'afamhdep', 'appfmuse#', 'atca_ddd', 'assri_ddd', 'aotherad_ddd'};

childhood_adversity_vars = {'ACTI_total', 'ACLEI', 'aseparation', 'adeathparent', 'adivorce'};

demographic_vars = {'Age', 'Sexe', 'abmi', 'aedu', 'amarpart', 'aarea', 'aLCAsubtype'};

% CORRECTED: Medication FREQUENCY variables (_fr suffix: 0=No, 1=Infrequent, 2=Frequent)
medication_frequency_vars = {'assri_fr', 'abenzo_fr', 'atca_fr', 'apsychotropic_fr', ...
                             'aother_ad_fr', 'aantipsychotic_fr', 'ahypnotic_sedative_fr', ...
                             'aanxiolytic_fr', 'aother_psychotropic_fr'};

% CORRECTED: Medication BINARY variables (NO _fr suffix: 0=No, 1=Yes)
medication_binary_vars = {'assri', 'abenzo', 'atca', 'apsychotropic', ...
                          'aother_ad', 'aantipsychotic', 'ahypnotic_sedative', ...
                          'aanxiolytic', 'aother_psychotropic'};

% Medication DDD variables (continuous dose)
medication_ddd_vars = {'appfmuse#', 'assri_ddd', 'atca_ddd', 'aotherad_ddd', 'aother_ad_ddd'};

% TASK 5.3: NEW - BENDEP scales (3 NEW VARIABLES)
bendep_vars = {'asumbd1', 'asumbd2', 'asumbd3'};

%% ==========================================================================
%  SECTION 2C: CONVERT CELL ARRAY VARIABLES TO NUMERIC
%  ==========================================================================
fprintf('\n---------------------------------------------------\n');
fprintf('SECTION 2C: CONVERTING CELL ARRAYS TO NUMERIC\n');
fprintf('---------------------------------------------------\n\n');

fprintf('CONVERTING AGE OF ONSET VARIABLES:\n');
for i = 1:length(age_onset_vars)
    if ismember(age_onset_vars{i}, nesda_data.Properties.VariableNames)
        var_data = nesda_data.(age_onset_vars{i});
        if iscell(var_data)
            numeric_data = NaN(height(nesda_data), 1);
            for j = 1:length(var_data)
                if ~isempty(var_data{j}) && ~strcmp(var_data{j}, '')
                    if isnumeric(var_data{j})
                        numeric_data(j) = var_data{j};
                    else
                        temp = str2double(var_data{j});
                        if ~isnan(temp)
                            numeric_data(j) = temp;
                        end
                    end
                end
            end
            nesda_data.(age_onset_vars{i}) = numeric_data;
            fprintf('  %s: %d values converted (%.1f%% valid)\n', ...
                age_onset_vars{i}, sum(~isnan(numeric_data)), ...
                100*sum(~isnan(numeric_data))/height(nesda_data));
        end
    end
end
fprintf('\n');

% NEW: Convert recency variables (OPTION 6)
fprintf('CONVERTING RECENCY VARIABLES:\n');
for i = 1:length(recency_vars)
    if ismember(recency_vars{i}, nesda_data.Properties.VariableNames)
        var_data = nesda_data.(recency_vars{i});
        if iscell(var_data)
            numeric_data = NaN(height(nesda_data), 1);
            for j = 1:length(var_data)
                if ~isempty(var_data{j}) && ~strcmp(var_data{j}, '')
                    if isnumeric(var_data{j})
                        numeric_data(j) = var_data{j};
                    else
                        temp = str2double(var_data{j});
                        if ~isnan(temp)
                            numeric_data(j) = temp;
                        end
                    end
                end
            end
            nesda_data.(recency_vars{i}) = numeric_data;
            fprintf('  %s: %d values converted (%.1f%% valid)\n', ...
                recency_vars{i}, sum(~isnan(numeric_data)), ...
                100*sum(~isnan(numeric_data))/height(nesda_data));
        end
    end
end
fprintf('\n');

fprintf('CONVERTING MEDICATION DDD VARIABLES:\n');
medication_vars_to_convert = {'atca_ddd', 'assri_ddd', 'aotherad_ddd', 'aother_ad_ddd'};
for i = 1:length(medication_vars_to_convert)
    if ismember(medication_vars_to_convert{i}, nesda_data.Properties.VariableNames)
        var_data = nesda_data.(medication_vars_to_convert{i});
        if iscell(var_data)
            numeric_data = NaN(height(nesda_data), 1);
            for j = 1:length(var_data)
                if ~isempty(var_data{j}) && ~strcmp(var_data{j}, '')
                    if isnumeric(var_data{j})
                        numeric_data(j) = var_data{j};
                    else
                        temp = str2double(var_data{j});
                        if ~isnan(temp)
                            numeric_data(j) = temp;
                        end
                    end
                end
            end
            nesda_data.(medication_vars_to_convert{i}) = numeric_data;
            fprintf('  %s: %d values converted (%.1f%% valid)\n', ...
                medication_vars_to_convert{i}, sum(~isnan(numeric_data)), ...
                100*sum(~isnan(numeric_data))/height(nesda_data));
        end
    end
end
fprintf('\n');

% TASK 5.3: Convert BENDEP variables
fprintf('CONVERTING BENDEP VARIABLES:\n');
for i = 1:length(bendep_vars)
    if ismember(bendep_vars{i}, nesda_data.Properties.VariableNames)
        var_data = nesda_data.(bendep_vars{i});
        if iscell(var_data)
            numeric_data = NaN(height(nesda_data), 1);
            for j = 1:length(var_data)
                if ~isempty(var_data{j}) && ~strcmp(var_data{j}, '')
                    if isnumeric(var_data{j})
                        numeric_data(j) = var_data{j};
                    else
                        temp = str2double(var_data{j});
                        if ~isnan(temp)
                            numeric_data(j) = temp;
                        end
                    end
                end
            end
            nesda_data.(bendep_vars{i}) = numeric_data;
            fprintf('  %s: %d values converted (%.1f%% valid)\n', ...
                bendep_vars{i}, sum(~isnan(numeric_data)), ...
                100*sum(~isnan(numeric_data))/height(nesda_data));
        end
    end
end
fprintf('\n');

available_symptom_vars = {};
for i = 1:length(symptom_vars)
    if ismember(symptom_vars{i}, varnames)
        available_symptom_vars{end+1} = symptom_vars{i};
    end
end
fprintf('SYMPTOM SEVERITY VARIABLES (%d vars):\n', length(symptom_vars));
fprintf('  Found: %d/%d variables\n', length(available_symptom_vars), length(symptom_vars));
if ~isempty(available_symptom_vars)
    fprintf('  Variables: %s\n', strjoin(available_symptom_vars, ', '));
    if isnumeric(nesda_data.(available_symptom_vars{1}))
        sample_vals = nesda_data.(available_symptom_vars{1})(1:min(5, height(nesda_data)));
        fprintf('  Sample data (%s, first 5): %s\n', available_symptom_vars{1}, mat2str(sample_vals'));
    end
end
fprintf('\n');

available_age_onset_vars = {};
for i = 1:length(age_onset_vars)
    if ismember(age_onset_vars{i}, varnames)
        available_age_onset_vars{end+1} = age_onset_vars{i};
    end
end
fprintf('AGE OF ONSET VARIABLES (3 vars):\n');
fprintf('  Found: %d/%d variables\n', length(available_age_onset_vars), length(age_onset_vars));
if ~isempty(available_age_onset_vars)
    fprintf('  Variables: %s\n', strjoin(available_age_onset_vars, ', '));
    if isnumeric(nesda_data.(available_age_onset_vars{1}))
        sample_vals = nesda_data.(available_age_onset_vars{1})(1:min(5, height(nesda_data)));
        fprintf('  Sample data (%s, first 5): %s\n', available_age_onset_vars{1}, mat2str(sample_vals'));
    end
end
fprintf('\n');

% NEW: Check recency variables (OPTION 6)
available_recency_vars = {};
for i = 1:length(recency_vars)
    if ismember(recency_vars{i}, varnames)
        available_recency_vars{end+1} = recency_vars{i};
    end
end
fprintf('RECENCY VARIABLES (3 vars) - NEW:\n');
fprintf('  Found: %d/%d variables\n', length(available_recency_vars), length(recency_vars));
if ~isempty(available_recency_vars)
    fprintf('  Variables: %s\n', strjoin(available_recency_vars, ', '));
    if isnumeric(nesda_data.(available_recency_vars{1}))
        sample_vals = nesda_data.(available_recency_vars{1})(1:min(5, height(nesda_data)));
        fprintf('  Sample data (%s, first 5): %s\n', available_recency_vars{1}, mat2str(sample_vals'));
    end
end
fprintf('\n');

available_clinical_history_vars = {};
for i = 1:length(clinical_history_vars)
    if ismember(clinical_history_vars{i}, varnames)
        available_clinical_history_vars{end+1} = clinical_history_vars{i};
    end
end
fprintf('CLINICAL HISTORY VARIABLES (13 vars):\n');
fprintf('  Found: %d/%d variables\n', length(available_clinical_history_vars), length(clinical_history_vars));
if ~isempty(available_clinical_history_vars)
    fprintf('  Variables: %s\n', strjoin(available_clinical_history_vars, ', '));
    if isnumeric(nesda_data.(available_clinical_history_vars{1}))
        sample_vals = nesda_data.(available_clinical_history_vars{1})(1:min(5, height(nesda_data)));
        fprintf('  Sample data (%s, first 5): %s\n', available_clinical_history_vars{1}, mat2str(sample_vals'));
    end
end
fprintf('\n');

available_childhood_vars = {};
for i = 1:length(childhood_adversity_vars)
    if ismember(childhood_adversity_vars{i}, varnames)
        available_childhood_vars{end+1} = childhood_adversity_vars{i};
    end
end
fprintf('CHILDHOOD ADVERSITY VARIABLES (5 vars):\n');
fprintf('  Found: %d/%d variables\n', length(available_childhood_vars), length(childhood_adversity_vars));
if ~isempty(available_childhood_vars)
    fprintf('  Variables: %s\n', strjoin(available_childhood_vars, ', '));
    if isnumeric(nesda_data.(available_childhood_vars{1}))
        sample_vals = nesda_data.(available_childhood_vars{1})(1:min(5, height(nesda_data)));
        fprintf('  Sample data (%s, first 5): %s\n', available_childhood_vars{1}, mat2str(sample_vals'));
    end
end
fprintf('\n');

%% ==========================================================================
%  SECTION 2D: CALCULATE ILLNESS DURATION (NEW)
%  ==========================================================================
fprintf('---------------------------------------------------\n');
fprintf('SECTION 2D: CALCULATING ILLNESS DURATION\n');
fprintf('---------------------------------------------------\n\n');

fprintf('NEW VARIABLE: Illness Duration = Age - Age of Onset\n\n');

illness_duration_vars = {};
if ismember('Age', nesda_data.Properties.VariableNames)
    age_data = nesda_data.Age;

    for i = 1:length(age_onset_vars)
        if ismember(age_onset_vars{i}, nesda_data.Properties.VariableNames)
            age_onset_data = nesda_data.(age_onset_vars{i});
            duration_var_name = strrep(age_onset_vars{i}, 'AO', 'Duration');
            illness_duration = age_data - age_onset_data;
            nesda_data.(duration_var_name) = illness_duration;
            illness_duration_vars{end+1} = duration_var_name;

            valid_duration = sum(~isnan(illness_duration));
            fprintf('  %s: %d valid cases (%.1f%%)\n', ...
                duration_var_name, valid_duration, ...
                100*valid_duration/height(nesda_data));

            valid_idx = find(~isnan(illness_duration), 5, 'first');
            if ~isempty(valid_idx)
                fprintf('    Sample values (first 5): ');
                for j = 1:length(valid_idx)
                    fprintf('%.1f', illness_duration(valid_idx(j)));
                    if j < length(valid_idx)
                        fprintf(', ');
                    end
                end
                fprintf(' years\n');
            end
        end
    end
else
    fprintf('  Age variable not found - cannot calculate illness duration\n');
end

fprintf('\n');

%% ==========================================================================
%  SECTION 3: LOAD TRANSITION DECISION SCORES
%  ==========================================================================
fprintf('---------------------------------------------------\n');
fprintf('SECTION 3: LOADING TRANSITION DECISION SCORES\n');
fprintf('---------------------------------------------------\n\n');

transition_file_26 = [transition_path_base 'PRS_TransPred_A32_OOCV-26_Predictions_Cl_1PT_vs_NT.csv'];
fprintf('Loading Version A (OOCV-26): %s\n', transition_file_26);

if ~exist(transition_file_26, 'file')
    error('ERROR: Transition OOCV-26 file not found: %s', transition_file_26);
end

% Try tab-delimited first
try
transition_26_tbl = readtable(transition_file_26, 'VariableNamingRule', 'preserve');
% Manually set variable names if they weren't read correctly
if startsWith(transition_26_tbl.Properties.VariableNames{1}, 'Var')
    expected_names = {'Cases', 'PRED_LABEL', 'Mean_Score', 'Std_Score', 'Ens_Prob1', 'Ens_Prob_1', 'PercRank_Score'};
    n_cols = width(transition_26_tbl);
    transition_26_tbl.Properties.VariableNames = expected_names(1:n_cols);
end
fprintf('  OOCV-26 loaded successfully!\n');
catch
    % Fall back to comma-delimited
    transition_26_tbl = readtable(transition_file_26, 'Delimiter', ',', ...
        'ReadVariableNames', true, 'VariableNamingRule', 'preserve');
    fprintf('  OOCV-26 loaded successfully (Comma-delimited)!\n');
end

fprintf('  Dimensions: [%d subjects × %d columns]\n', height(transition_26_tbl), width(transition_26_tbl));
fprintf('  Column names: %s\n', strjoin(transition_26_tbl.Properties.VariableNames, ', '));

transition_ids_26 = transition_26_tbl{:,1};
fprintf('  Subject IDs extracted from column 1\n');

% Case-insensitive search for Mean_Score
varnames_lower = lower(transition_26_tbl.Properties.VariableNames);
decision_col_idx = find(contains(varnames_lower, 'mean') & contains(varnames_lower, 'score'));

if isempty(decision_col_idx)
    error('ERROR: Cannot find Mean_Score column in OOCV-26. Available columns: %s', ...
        strjoin(transition_26_tbl.Properties.VariableNames, ', '));
end

fprintf('  Decision scores extracted from column %d: %s\n', ...
    decision_col_idx(1), transition_26_tbl.Properties.VariableNames{decision_col_idx(1)});

transition_scores_26 = transition_26_tbl{:,decision_col_idx(1)};
n_before_exclusion = length(transition_scores_26);
% IMPROVED OUTLIER FILTER: Exclude DS==99 OR |DS|>10
outlier_mask_26 = (transition_scores_26 == 99) | (abs(transition_scores_26) > 10);
transition_scores_26(outlier_mask_26) = NaN;
n_excluded = sum(isnan(transition_scores_26)) - sum(isnan(transition_26_tbl{:,decision_col_idx(1)}));

fprintf('  Decision scores extracted from column: %s\n', ...
    transition_26_tbl.Properties.VariableNames{decision_col_idx(1)});
if n_excluded > 0
    fprintf('  Excluded %d subjects with decision score = 99 (missing value code)\n', n_excluded);
end
fprintf('    Valid scores: %d/%d\n', sum(~isnan(transition_scores_26)), n_before_exclusion);
fprintf('    Mean ± SD: %.3f ± %.3f\n\n', mean(transition_scores_26, 'omitnan'), std(transition_scores_26, 'omitnan'));

transition_file_27 = [transition_path_base 'PRS_TransPred_A32_OOCV-27_Predictions_Cl_1PT_vs_NT.csv'];
fprintf('Loading Version B (OOCV-27): %s\n', transition_file_27);

if ~exist(transition_file_27, 'file')
    error('ERROR: Transition OOCV-27 file not found: %s', transition_file_27);
end

try
 transition_27_tbl = readtable(transition_file_27, 'VariableNamingRule', 'preserve');
% Manually set variable names if they weren't read correctly
if startsWith(transition_27_tbl.Properties.VariableNames{1}, 'Var')
    expected_names = {'Cases', 'PRED_LABEL', 'Mean_Score', 'Std_Score', 'Ens_Prob1', 'Ens_Prob_1', 'PercRank_Score'};
    n_cols = width(transition_27_tbl);
    transition_27_tbl.Properties.VariableNames = expected_names(1:n_cols);
end
fprintf('  OOCV-27 loaded successfully!\n');
catch
    transition_27_tbl = readtable(transition_file_27, 'Delimiter', ',', 'VariableNamingRule', 'preserve');
    fprintf('  OOCV-27 loaded successfully (Comma-delimited)!\n');
end

fprintf('  Dimensions: [%d subjects × %d columns]\n', height(transition_27_tbl), width(transition_27_tbl));

transition_ids_27 = transition_27_tbl{:,1};
decision_col_idx = find(contains(transition_27_tbl.Properties.VariableNames, 'Mean_Score', 'IgnoreCase', true));
if isempty(decision_col_idx)
    decision_col_idx = find(contains(transition_27_tbl.Properties.VariableNames, 'Decision', 'IgnoreCase', true));
end
transition_scores_27 = transition_27_tbl{:,decision_col_idx(1)};

n_before = length(transition_scores_27);
% IMPROVED OUTLIER FILTER: Exclude DS==99 OR |DS|>10
outlier_mask_27 = (transition_scores_27 == 99) | (abs(transition_scores_27) > 10);
transition_scores_27(outlier_mask_27) = NaN;
n_excluded = sum(isnan(transition_scores_27)) - sum(isnan(transition_27_tbl{:,decision_col_idx(1)}));

fprintf('  Decision scores extracted\n');
if n_excluded > 0
    fprintf('  Excluded %d subjects with decision score = 99 (missing value code)\n', n_excluded);
end
fprintf('    Valid scores: %d/%d\n', sum(~isnan(transition_scores_27)), n_before);
fprintf('    Mean ± SD: %.3f ± %.3f\n\n', mean(transition_scores_27, 'omitnan'), std(transition_scores_27, 'omitnan'));

%% ==========================================================================
%  SECTION 4: LOAD bvFTD DECISION SCORES
%  ==========================================================================
fprintf('---------------------------------------------------\n');
fprintf('SECTION 4: LOADING bvFTD DECISION SCORES\n');
fprintf('---------------------------------------------------\n\n');

bvftd_file = [bvftd_path_base 'ClassModel_bvFTD-HC_A1_OOCV-6_Predictions_Cl_1bvFTD_vs_HC.csv'];
fprintf('Loading bvFTD (OOCV-6): %s\n', bvftd_file);

if ~exist(bvftd_file, 'file')
    error('ERROR: bvFTD file not found: %s', bvftd_file);
end

try
bvftd_tbl = readtable(bvftd_file, 'VariableNamingRule', 'preserve');
% Manually set variable names if they weren't read correctly
if startsWith(bvftd_tbl.Properties.VariableNames{1}, 'Var')
    expected_names = {'Cases', 'PRED_LABEL', 'Mean_Score', 'Std_Score', 'Ens_Prob1', 'Ens_Prob_1', 'PercRank_Score'};
    n_cols = width(bvftd_tbl);
    bvftd_tbl.Properties.VariableNames = expected_names(1:n_cols);
end
fprintf('  bvFTD loaded successfully!\n');
catch
    bvftd_tbl = readtable(bvftd_file, 'Delimiter', ',', 'VariableNamingRule', 'preserve');
    fprintf('  bvFTD loaded successfully (Comma-delimited)!\n');
end

fprintf('  Dimensions: [%d subjects × %d columns]\n', height(bvftd_tbl), width(bvftd_tbl));

bvftd_ids = bvftd_tbl{:,1};
decision_col_idx = find(contains(bvftd_tbl.Properties.VariableNames, 'Mean_Score', 'IgnoreCase', true));
if isempty(decision_col_idx)
    decision_col_idx = find(contains(bvftd_tbl.Properties.VariableNames, 'Decision', 'IgnoreCase', true));
end
bvftd_scores = bvftd_tbl{:,decision_col_idx(1)};

n_before = length(bvftd_scores);
% IMPROVED OUTLIER FILTER: Exclude DS==99 OR |DS|>10
outlier_mask_bvftd = (bvftd_scores == 99) | (abs(bvftd_scores) > 10);
bvftd_scores(outlier_mask_bvftd) = NaN;
n_excluded = sum(isnan(bvftd_scores)) - sum(isnan(bvftd_tbl{:,decision_col_idx(1)}));

fprintf('  Decision scores extracted\n');
if n_excluded > 0
    fprintf('  Excluded %d subjects with decision score = 99 (missing value code)\n', n_excluded);
end
fprintf('    Valid scores: %d/%d\n', sum(~isnan(bvftd_scores)), n_before);
fprintf('    Mean ± SD: %.3f ± %.3f\n\n', mean(bvftd_scores, 'omitnan'), std(bvftd_scores, 'omitnan'));

%% ==========================================================================
%  SECTION 5: MERGE DATA AND CREATE ANALYSIS DATASET
%  ==========================================================================
fprintf('---------------------------------------------------\n');
fprintf('SECTION 5: MERGING DATASETS\n');
fprintf('---------------------------------------------------\n\n');

nesda_ids = nesda_data.(id_var);
if isnumeric(transition_ids_26) && iscell(nesda_ids)
    nesda_ids = cellfun(@str2double, nesda_ids);
elseif iscell(transition_ids_26) && isnumeric(nesda_ids)
    nesda_ids = arrayfun(@num2str, nesda_ids, 'UniformOutput', false);
end

fprintf('Matching subjects across datasets...\n');
[~, idx_nesda_26, idx_trans_26] = intersect(nesda_ids, transition_ids_26);
fprintf('  Transition-26 matched: %d subjects\n', length(idx_nesda_26));

[~, idx_nesda_27, idx_trans_27] = intersect(nesda_ids, transition_ids_27);
fprintf('  Transition-27 matched: %d subjects\n', length(idx_nesda_27));

[~, idx_nesda_bvftd, idx_bvftd] = intersect(nesda_ids, bvftd_ids);
fprintf('  bvFTD matched: %d subjects\n\n', length(idx_nesda_bvftd));

fprintf('Creating analysis dataset...\n');
analysis_data = nesda_data;
analysis_data.Transition_26 = NaN(height(analysis_data), 1);
analysis_data.Transition_27 = NaN(height(analysis_data), 1);
analysis_data.bvFTD = NaN(height(analysis_data), 1);

analysis_data.Transition_26(idx_nesda_26) = transition_scores_26(idx_trans_26);
analysis_data.Transition_27(idx_nesda_27) = transition_scores_27(idx_trans_27);
analysis_data.bvFTD(idx_nesda_bvftd) = bvftd_scores(idx_bvftd);

fprintf('  Analysis dataset created: [%d subjects × %d variables]\n', ...
    height(analysis_data), width(analysis_data));
fprintf('  With Transition-26: %d (%.1f%%)\n', ...
    sum(~isnan(analysis_data.Transition_26)), ...
    100*sum(~isnan(analysis_data.Transition_26))/height(analysis_data));
fprintf('  With Transition-27: %d (%.1f%%)\n', ...
    sum(~isnan(analysis_data.Transition_27)), ...
    100*sum(~isnan(analysis_data.Transition_27))/height(analysis_data));
fprintf('  With bvFTD: %d (%.1f%%)\n\n', ...
    sum(~isnan(analysis_data.bvFTD)), ...
    100*sum(~isnan(analysis_data.bvFTD))/height(analysis_data));

%% ==========================================================================
%  SECTION 5B: LOAD AND MERGE DIAGNOSIS GROUP (FOR MEDICATION ANALYSIS)
%  ==========================================================================
fprintf('---------------------------------------------------\n');
fprintf('SECTION 5B: LOADING DIAGNOSIS GROUP DATA\n');
fprintf('---------------------------------------------------\n\n');

fprintf('Loading HC diagnosis data...\n');
if exist(diagnosis_hc_file, 'file')
    hc_data = readtable(diagnosis_hc_file, 'VariableNamingRule', 'preserve');
    fprintf('  HC data loaded: [%d subjects]\n', height(hc_data));
else
    fprintf('  WARNING: HC file not found: %s\n', diagnosis_hc_file);
    hc_data = table();
end

fprintf('Loading Patients diagnosis data...\n');
if exist(diagnosis_patients_file, 'file')
    patients_data = readtable(diagnosis_patients_file, 'VariableNamingRule', 'preserve');
    fprintf('  Patients data loaded: [%d subjects]\n', height(patients_data));
else
    fprintf('  WARNING: Patients file not found: %s\n', diagnosis_patients_file);
    patients_data = table();
end

% Combine HC and Patients data
if ~isempty(hc_data) && ~isempty(patients_data)
    % Add diagnosis_group column if not present
    if ~ismember('diagnosis_group', hc_data.Properties.VariableNames)
        hc_data.diagnosis_group = repmat({'HC'}, height(hc_data), 1);
    end

    % Combine
    diagnosis_data = [hc_data; patients_data];
    fprintf('  Combined diagnosis data: [%d subjects]\n', height(diagnosis_data));

    % Merge with analysis_data by pident
    diagnosis_id_var = 'pident';
    if ~ismember(diagnosis_id_var, diagnosis_data.Properties.VariableNames)
        fprintf('  ERROR: pident not found in diagnosis data\n');
    else
        % Match IDs
        diagnosis_ids = diagnosis_data.(diagnosis_id_var);

        % Convert IDs to same format
        if isnumeric(nesda_ids) && iscell(diagnosis_ids)
            diagnosis_ids = cellfun(@str2double, diagnosis_ids);
        elseif iscell(nesda_ids) && isnumeric(diagnosis_ids)
            diagnosis_ids = arrayfun(@num2str, diagnosis_ids, 'UniformOutput', false);
        end

        % Find matching subjects
        [~, idx_analysis, idx_diagnosis] = intersect(nesda_ids, diagnosis_ids);
        fprintf('  Matched %d subjects with diagnosis data\n', length(idx_analysis));

        % Add diagnosis_group to analysis_data
        analysis_data.diagnosis_group = repmat({''}, height(analysis_data), 1);
        analysis_data.diagnosis_group(idx_analysis) = diagnosis_data.diagnosis_group(idx_diagnosis);

        % Count by diagnosis group
        unique_groups = unique(analysis_data.diagnosis_group);
        fprintf('  Diagnosis groups:\n');
        for i = 1:length(unique_groups)
            if ~isempty(unique_groups{i})
                n_group = sum(strcmp(analysis_data.diagnosis_group, unique_groups{i}));
                fprintf('    %s: %d subjects\n', unique_groups{i}, n_group);
            end
        end
    end
else
    fprintf('  WARNING: Could not load diagnosis data - medication analysis will use all subjects\n');
    analysis_data.diagnosis_group = repmat({''}, height(analysis_data), 1);
end

%% ==========================================================================
%  SECTION 5C: CREATE PATIENT-ONLY DATASET (FILTER OUT HCs)
%  ==========================================================================
fprintf('---------------------------------------------------\n');
fprintf('SECTION 5C: FILTERING FOR PATIENTS ONLY\n');
fprintf('---------------------------------------------------\n\n');

% Create patient-only filter (exclude HC)
if ismember('diagnosis_group', analysis_data.Properties.VariableNames)
    patient_mask = ~strcmp(analysis_data.diagnosis_group, '') & ...
                   ~strcmp(analysis_data.diagnosis_group, 'HC');

    fprintf('CREATING PATIENT-ONLY DATASET:\n');
    fprintf('  Total subjects: %d\n', height(analysis_data));
    fprintf('  Healthy Controls (HC): %d\n', sum(strcmp(analysis_data.diagnosis_group, 'HC')));
    fprintf('  Patients (non-HC): %d\n', sum(patient_mask));
    fprintf('  Missing diagnosis: %d\n\n', sum(strcmp(analysis_data.diagnosis_group, '')));

    % Store full dataset for reference
    analysis_data_full = analysis_data;

    % Override analysis_data with patient-only data
    analysis_data = analysis_data(patient_mask, :);

    fprintf('  *** All subsequent analyses will use PATIENTS ONLY ***\n');
    fprintf('  New analysis_data dimensions: [%d × %d]\n\n', ...
        height(analysis_data), width(analysis_data));

    % Show patient diagnosis groups
    unique_diag = unique(analysis_data.diagnosis_group);
    fprintf('  Patient diagnosis groups:\n');
    for i = 1:length(unique_diag)
        if ~isempty(unique_diag{i}) && ~strcmp(unique_diag{i}, 'HC')
            n_diag = sum(strcmp(analysis_data.diagnosis_group, unique_diag{i}));
            fprintf('    %s: %d (%.1f%%)\n', unique_diag{i}, n_diag, ...
                100*n_diag/height(analysis_data));
        end
    end
    fprintf('\n');
else
    fprintf('WARNING: diagnosis_group variable not found!\n');
    fprintf('         Cannot filter HCs - will analyze all subjects\n\n');
    analysis_data_full = analysis_data;
end

fprintf('SECTION 5C COMPLETE\n\n');

fprintf('\n');

%% ==========================================================================
%  HELPER FUNCTIONS
%  ==========================================================================
ci_r = @(r, n) [tanh(atanh(r) - 1.96/sqrt(n-3)), tanh(atanh(r) + 1.96/sqrt(n-3))];

%% ==========================================================================
%  SECTION 6: PRIORITY 4.1 - METABOLIC SUBTYPES & BMI
%  ==========================================================================
fprintf('---------------------------------------------------\n');
fprintf('|         PRIORITY 4.1: METABOLIC & BMI            |\n');
fprintf('---------------------------------------------------\n\n');

results_4_1 = struct();

if ismember('aLCAsubtype', analysis_data.Properties.VariableNames)
    fprintf('ANALYZING METABOLIC SUBTYPES (aLCAsubtype)...\n');

    subtypes = analysis_data.aLCAsubtype;
    subtypes_for_analysis = subtypes;
    subtypes_for_analysis(subtypes == -2) = NaN;
    n_excluded_subtype = sum(subtypes == -2);
    if n_excluded_subtype > 0
        fprintf('  Excluded %d subjects with aLCAsubtype = -2 (not subtyped)\n', n_excluded_subtype);
    end

    valid_idx = ~isnan(subtypes_for_analysis) & ~isnan(analysis_data.Transition_26);

    unique_subtypes = unique(subtypes_for_analysis(~isnan(subtypes_for_analysis)));
    fprintf('  Unique subtypes (after exclusion): %s\n', mat2str(unique_subtypes));
    fprintf('  Valid cases: %d\n\n', sum(valid_idx));

    fprintf('  Testing group differences:\n');

    [p_26, tbl_26, stats_26] = anova1(analysis_data.Transition_26(valid_idx), ...
        subtypes_for_analysis(valid_idx), 'off');
    fprintf('    Transition-26: F=%.3f, p=%.4f', tbl_26{2,5}, p_26);
    if p_26 < 0.05
        fprintf(' SIGNIFICANT\n');
    else
        fprintf('\n');
    end
    results_4_1.metabolic_transition_26_p = p_26;

    valid_idx_27 = ~isnan(subtypes_for_analysis) & ~isnan(analysis_data.Transition_27);
    [p_27, tbl_27, stats_27] = anova1(analysis_data.Transition_27(valid_idx_27), ...
        subtypes_for_analysis(valid_idx_27), 'off');
    fprintf('    Transition-27: F=%.3f, p=%.4f', tbl_27{2,5}, p_27);
    if p_27 < 0.05
        fprintf(' SIGNIFICANT\n');
    else
        fprintf('\n');
    end
    results_4_1.metabolic_transition_27_p = p_27;

    valid_idx_bvftd = ~isnan(subtypes_for_analysis) & ~isnan(analysis_data.bvFTD);
    [p_bvftd, tbl_bvftd, stats_bvftd] = anova1(analysis_data.bvFTD(valid_idx_bvftd), ...
        subtypes_for_analysis(valid_idx_bvftd), 'off');
    fprintf('    bvFTD: F=%.3f, p=%.4f', tbl_bvftd{2,5}, p_bvftd);
    if p_bvftd < 0.05
        fprintf(' SIGNIFICANT\n');
    else
        fprintf('\n');
    end
    results_4_1.metabolic_bvftd_p = p_bvftd;

    figure('Position', [100 100 1200 400]);

    subplot(1,3,1);
    boxplot(analysis_data.Transition_26(valid_idx), subtypes_for_analysis(valid_idx), ...
        'Colors', [0.2 0.4 0.8], 'Symbol', 'k.');
    ylabel('Transition-26 Score', 'FontWeight', 'bold');
    xlabel('Metabolic Subtype', 'FontWeight', 'bold');
    title(sprintf('Transition-26\np=%.4f', p_26), 'FontWeight', 'bold');
    grid on;

    subplot(1,3,2);
    boxplot(analysis_data.Transition_27(valid_idx_27), subtypes_for_analysis(valid_idx_27), ...
        'Colors', [0.8 0.4 0.2], 'Symbol', 'k.');
    ylabel('Transition-27 Score', 'FontWeight', 'bold');
    xlabel('Metabolic Subtype', 'FontWeight', 'bold');
    title(sprintf('Transition-27\np=%.4f', p_27), 'FontWeight', 'bold');
    grid on;

    subplot(1,3,3);
    boxplot(analysis_data.bvFTD(valid_idx_bvftd), subtypes_for_analysis(valid_idx_bvftd), ...
        'Colors', [0.8 0.2 0.2], 'Symbol', 'k.');
    ylabel('bvFTD Score', 'FontWeight', 'bold');
    xlabel('Metabolic Subtype', 'FontWeight', 'bold');
    title(sprintf('bvFTD\np=%.4f', p_bvftd), 'FontWeight', 'bold');
    grid on;

    saveas(gcf, [fig_path 'Fig_4_1_Metabolic_Subtypes.png']);
    saveas(gcf, [fig_path 'Fig_4_1_Metabolic_Subtypes.fig']);
    fprintf('\n  Saved: Fig_4_1_Metabolic_Subtypes.png/.fig\n\n');
end

if ismember('abmi', analysis_data.Properties.VariableNames)
    fprintf('ANALYZING BMI CORRELATIONS...\n');

    bmi = analysis_data.abmi;

    valid_bmi_26 = ~isnan(bmi) & ~isnan(analysis_data.Transition_26);
    [r_bmi_26, p_bmi_26] = corr(bmi(valid_bmi_26), analysis_data.Transition_26(valid_bmi_26));
    ci_26 = ci_r(r_bmi_26, sum(valid_bmi_26));
    fprintf('  Transition-26: r=%.3f [%.3f, %.3f], p=%.4f (n=%d)', r_bmi_26, ci_26(1), ci_26(2), p_bmi_26, sum(valid_bmi_26));
    if p_bmi_26 < 0.05
        fprintf(' SIGNIFICANT\n');
    else
        fprintf('\n');
    end
    results_4_1.bmi_transition_26_r = r_bmi_26;
    results_4_1.bmi_transition_26_p = p_bmi_26;

    valid_bmi_27 = ~isnan(bmi) & ~isnan(analysis_data.Transition_27);
    [r_bmi_27, p_bmi_27] = corr(bmi(valid_bmi_27), analysis_data.Transition_27(valid_bmi_27));
    ci_27 = ci_r(r_bmi_27, sum(valid_bmi_27));
    fprintf('  Transition-27: r=%.3f [%.3f, %.3f], p=%.4f (n=%d)', r_bmi_27, ci_27(1), ci_27(2), p_bmi_27, sum(valid_bmi_27));
    if p_bmi_27 < 0.05
        fprintf(' SIGNIFICANT\n');
    else
        fprintf('\n');
    end
    results_4_1.bmi_transition_27_r = r_bmi_27;
    results_4_1.bmi_transition_27_p = p_bmi_27;

    valid_bmi_bvftd = ~isnan(bmi) & ~isnan(analysis_data.bvFTD);
    [r_bmi_bvftd, p_bmi_bvftd] = corr(bmi(valid_bmi_bvftd), analysis_data.bvFTD(valid_bmi_bvftd));
    ci_bvftd = ci_r(r_bmi_bvftd, sum(valid_bmi_bvftd));
    fprintf('  bvFTD: r=%.3f [%.3f, %.3f], p=%.4f (n=%d)', r_bmi_bvftd, ci_bvftd(1), ci_bvftd(2), p_bmi_bvftd, sum(valid_bmi_bvftd));
    if p_bmi_bvftd < 0.05
        fprintf(' SIGNIFICANT\n');
    else
        fprintf('\n');
    end
    results_4_1.bmi_bvftd_r = r_bmi_bvftd;
    results_4_1.bmi_bvftd_p = p_bmi_bvftd;

    figure('Position', [100 100 1200 400]);

    subplot(1,3,1);
    scatter(bmi(valid_bmi_26), analysis_data.Transition_26(valid_bmi_26), 50, ...
        [0.2 0.4 0.8], 'filled', 'MarkerFaceAlpha', 0.5);
    hold on;
    p_fit = polyfit(bmi(valid_bmi_26), analysis_data.Transition_26(valid_bmi_26), 1);
    plot(bmi(valid_bmi_26), polyval(p_fit, bmi(valid_bmi_26)), 'r-', 'LineWidth', 2);
    xlabel('BMI (kg/m²)', 'FontWeight', 'bold');
    ylabel('Transition-26 Score', 'FontWeight', 'bold');
    title(sprintf('r=%.3f, p=%.4f', r_bmi_26, p_bmi_26), 'FontWeight', 'bold');
    grid on;

    subplot(1,3,2);
    scatter(bmi(valid_bmi_27), analysis_data.Transition_27(valid_bmi_27), 50, ...
        [0.8 0.4 0.2], 'filled', 'MarkerFaceAlpha', 0.5);
    hold on;
    p_fit = polyfit(bmi(valid_bmi_27), analysis_data.Transition_27(valid_bmi_27), 1);
    plot(bmi(valid_bmi_27), polyval(p_fit, bmi(valid_bmi_27)), 'r-', 'LineWidth', 2);
    xlabel('BMI (kg/m²)', 'FontWeight', 'bold');
    ylabel('Transition-27 Score', 'FontWeight', 'bold');
    title(sprintf('r=%.3f, p=%.4f', r_bmi_27, p_bmi_27), 'FontWeight', 'bold');
    grid on;

    subplot(1,3,3);
    scatter(bmi(valid_bmi_bvftd), analysis_data.bvFTD(valid_bmi_bvftd), 50, ...
        [0.8 0.2 0.2], 'filled', 'MarkerFaceAlpha', 0.5);
    hold on;
    p_fit = polyfit(bmi(valid_bmi_bvftd), analysis_data.bvFTD(valid_bmi_bvftd), 1);
    plot(bmi(valid_bmi_bvftd), polyval(p_fit, bmi(valid_bmi_bvftd)), 'r-', 'LineWidth', 2);
    xlabel('BMI (kg/m²)', 'FontWeight', 'bold');
    ylabel('bvFTD Score', 'FontWeight', 'bold');
    title(sprintf('r=%.3f, p=%.4f', r_bmi_bvftd, p_bmi_bvftd), 'FontWeight', 'bold');
    grid on;

    saveas(gcf, [fig_path 'Fig_4_1_BMI_Correlations.png']);
    saveas(gcf, [fig_path 'Fig_4_1_BMI_Correlations.fig']);
    fprintf('\n  Saved: Fig_4_1_BMI_Correlations.png/.fig\n\n');
end

fprintf('PRIORITY 4.1 COMPLETE\n\n');

%% Helper functions at the end
function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end

function cmap = redblue(m)
    if nargin < 1
        m = size(get(gcf,'colormap'),1);
    end

    if mod(m,2) == 0
        m1 = m/2;
        r = [(0:m1-1)'/max(m1-1,1); ones(m1,1)];
        g = [(0:m1-1)'/max(m1-1,1); (m1-1:-1:0)'/max(m1-1,1)];
        b = [ones(m1,1); (m1-1:-1:0)'/max(m1-1,1)];
    else
        m1 = floor(m/2);
        r = [(0:m1-1)'/max(m1,1); ones(m-m1,1)];
        g = [(0:m1-1)'/max(m1,1); (m-m1-1:-1:0)'/max(m-m1-1,1)];
        b = [ones(m1,1); (m-m1-1:-1:0)'/max(m-m1-1,1)];
    end

    cmap = [r g b];
end

function label = get_label_safe(varname, label_map)
    % Safe label getter with error handling
    try
        if ischar(varname) || isstring(varname)
            varname = char(varname);
            if label_map.isKey(varname)
                label = label_map(varname);
            else
                label = varname;
            end
        else
            label = varname;
        end
    catch
        % If anything fails, just return the original variable name
        label = varname;
    end
end
