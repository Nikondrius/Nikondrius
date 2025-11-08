%% ==========================================================================
%  SYNTHETIC NESDA DATA GENERATOR
%  ==========================================================================
%  Author: Claude AI Assistant
%  Date: November 8, 2025
%  Purpose: Generate realistic synthetic NESDA data for testing without
%           exposing real patient data
%
%  OUTPUTS:
%  - NESDA_tabular_combined_data.csv (n=300 with realistic correlations)
%  - PRS_TransPred_A32_OOCV-26_Predictions_Cl_1PT_vs_NT.csv
%  - PRS_TransPred_A32_OOCV-27_Predictions_Cl_1PT_vs_NT.csv
%  - bvFTD Decision Scores CSV
%  - NESDA_HC.csv (100 healthy controls)
%  - NESDA_Patients.csv (200 patients: Depression/Anxiety/Comorbid)
%  ==========================================================================

clear; clc; close all;
fprintf('==========================================================\n');
fprintf('  SYNTHETIC NESDA DATA GENERATOR\n');
fprintf('==========================================================\n\n');

%% ==========================================================================
%  CONFIGURATION
%  ==========================================================================
rng(42); % For reproducibility

n_total = 300;
n_hc = 100;
n_depression = 100;
n_anxiety = 50;
n_comorbid = 50;

% Output path
output_path = '/volume/projects/CV_NESDA/Analysis/Transition_Model/NESDA_Data/SYNTHETIC/';
if ~exist(output_path, 'dir')
    mkdir(output_path);
    fprintf('Created output directory: %s\n', output_path);
end

fprintf('Configuration:\n');
fprintf('  Total subjects: %d\n', n_total);
fprintf('  Healthy Controls: %d\n', n_hc);
fprintf('  Depression: %d\n', n_depression);
fprintf('  Anxiety: %d\n', n_anxiety);
fprintf('  Comorbid: %d\n\n', n_comorbid);

%% ==========================================================================
%  GENERATE BASE DEMOGRAPHICS
%  ==========================================================================
fprintf('Generating base demographics...\n');

pident = (1:n_total)';

% Age: 18-75 years
Age = 18 + (75-18) * rand(n_total, 1);

% Sex: 1=Male, 2=Female (60% female in depression, 50% overall)
Sexe = ones(n_total, 1);
Sexe(1:n_hc) = 1 + (rand(n_hc, 1) > 0.5); % HC: 50% F
Sexe(n_hc+1:n_hc+n_depression) = 1 + (rand(n_depression, 1) > 0.4); % Depression: 60% F
Sexe(n_hc+n_depression+1:n_hc+n_depression+n_anxiety) = 1 + (rand(n_anxiety, 1) > 0.35); % Anxiety: 65% F
Sexe(n_hc+n_depression+n_anxiety+1:end) = 1 + (rand(n_comorbid, 1) > 0.3); % Comorbid: 70% F

% BMI: 18-35 kg/m²
abmi = 18 + (35-18) * rand(n_total, 1);

% Education: 8-20 years
aedu = 8 + (20-8) * rand(n_total, 1);

% Marital Status: 0=Single, 1=Partnered
amarpart = rand(n_total, 1) > 0.4; % 60% partnered

% Metabolic Subtype: 1, 2, or 3
aLCAsubtype = randi([1, 3], n_total, 1);

%% ==========================================================================
%  GENERATE SYMPTOM SEVERITY (WITH GROUP DIFFERENCES)
%  ==========================================================================
fprintf('Generating symptom severity variables...\n');

% Initialize all symptoms
aids = zeros(n_total, 1);
aids_mood_cognition = zeros(n_total, 1);
aids_anxiety_arousal = zeros(n_total, 1);
abaiscal = zeros(n_total, 1);
aauditsc = zeros(n_total, 1);

% HC: Low symptoms
aids(1:n_hc) = 0 + 10 * rand(n_hc, 1); % 0-10
aids_mood_cognition(1:n_hc) = 0 + 5 * rand(n_hc, 1); % 0-5
aids_anxiety_arousal(1:n_hc) = 0 + 5 * rand(n_hc, 1); % 0-5
abaiscal(1:n_hc) = 0 + 8 * rand(n_hc, 1); % 0-8
aauditsc(1:n_hc) = 0 + 5 * rand(n_hc, 1); % 0-5

% Depression: High depression, moderate anxiety
aids(n_hc+1:n_hc+n_depression) = 30 + 30 * rand(n_depression, 1); % 30-60
aids_mood_cognition(n_hc+1:n_hc+n_depression) = 15 + 15 * rand(n_depression, 1); % 15-30
aids_anxiety_arousal(n_hc+1:n_hc+n_depression) = 10 + 10 * rand(n_depression, 1); % 10-20
abaiscal(n_hc+1:n_hc+n_depression) = 10 + 20 * rand(n_depression, 1); % 10-30
aauditsc(n_hc+1:n_hc+n_depression) = 5 + 15 * rand(n_depression, 1); % 5-20

% Anxiety: Moderate depression, high anxiety
aids(n_hc+n_depression+1:n_hc+n_depression+n_anxiety) = 20 + 25 * rand(n_anxiety, 1); % 20-45
aids_mood_cognition(n_hc+n_depression+1:n_hc+n_depression+n_anxiety) = 10 + 12 * rand(n_anxiety, 1); % 10-22
aids_anxiety_arousal(n_hc+n_depression+1:n_hc+n_depression+n_anxiety) = 15 + 12 * rand(n_anxiety, 1); % 15-27
abaiscal(n_hc+n_depression+1:n_hc+n_depression+n_anxiety) = 25 + 25 * rand(n_anxiety, 1); % 25-50
aauditsc(n_hc+n_depression+1:n_hc+n_depression+n_anxiety) = 3 + 10 * rand(n_anxiety, 1); % 3-13

% Comorbid: High both
aids(n_hc+n_depression+n_anxiety+1:end) = 40 + 35 * rand(n_comorbid, 1); % 40-75
aids_mood_cognition(n_hc+n_depression+n_anxiety+1:end) = 20 + 15 * rand(n_comorbid, 1); % 20-35
aids_anxiety_arousal(n_hc+n_depression+n_anxiety+1:end) = 15 + 12 * rand(n_comorbid, 1); % 15-27
abaiscal(n_hc+n_depression+n_anxiety+1:end) = 30 + 28 * rand(n_comorbid, 1); % 30-58
aauditsc(n_hc+n_depression+n_anxiety+1:end) = 8 + 20 * rand(n_comorbid, 1); % 8-28

% Derived variables
aidssev = floor(aids / 21); % 0-3 severity
aidssev(aidssev > 3) = 3;
aidsatyp = aids > 40; % Atypical if severe
aidsmel = aids > 35 & aids_mood_cognition > 20; % Melancholic
abaisev = floor(abaiscal / 21); % 0-3 severity
abaisev(abaisev > 3) = 3;
abaisom = abaiscal > 30; % Somatic anxiety
abaisub = abaiscal > 25; % Subjective anxiety

%% ==========================================================================
%  GENERATE AGE OF ONSET AND RECENCY (PATIENTS ONLY)
%  ==========================================================================
fprintf('Generating age of onset and recency variables...\n');

AD2962xAO = NaN(n_total, 1); % MDD age of onset
AD2963xAO = NaN(n_total, 1); % Dysthymia age of onset
AD3004AO = NaN(n_total, 1); % Any depression age of onset

AD2962xRE = NaN(n_total, 1); % MDD recency
AD2963xRE = NaN(n_total, 1); % Dysthymia recency
AD3004RE = NaN(n_total, 1); % Any depression recency

% Only for patients (not HC)
patient_idx = (n_hc+1):n_total;

for i = patient_idx'
    % Age of onset: typically 10-40 years, correlated with current age
    ao = 10 + min(Age(i)-10, 30) * rand();
    AD3004AO(i) = ao;

    if i <= n_hc + n_depression || i > n_hc + n_depression + n_anxiety
        % Depression or comorbid → MDD onset
        AD2962xAO(i) = ao + 5*randn(); % With some noise
        AD2962xAO(i) = max(10, min(Age(i)-1, AD2962xAO(i)));
    end

    if i > n_hc + n_depression % Anxiety or comorbid
        % Some have dysthymia
        if rand() > 0.6
            AD2963xAO(i) = ao + 3*randn();
            AD2963xAO(i) = max(10, min(Age(i)-1, AD2963xAO(i)));
        end
    end

    % Recency: 0-50 years since last episode
    recency = (Age(i) - ao) * rand();
    AD3004RE(i) = recency;

    if ~isnan(AD2962xAO(i))
        AD2962xRE(i) = recency + 5*randn();
        AD2962xRE(i) = max(0, min(50, AD2962xRE(i)));
    end

    if ~isnan(AD2963xAO(i))
        AD2963xRE(i) = recency + 3*randn();
        AD2963xRE(i) = max(0, min(50, AD2963xRE(i)));
    end
end

%% ==========================================================================
%  GENERATE CLINICAL HISTORY (PATIENTS ONLY)
%  ==========================================================================
fprintf('Generating clinical history variables...\n');

acidep10 = zeros(n_total, 1); % N depressive episodes
acidep11 = zeros(n_total, 1); % Months current episode
acidep13 = zeros(n_total, 1); % N remitted episodes
acidep14 = zeros(n_total, 1); % N chronic episodes
aanxy21 = NaN(n_total, 1); % Age first anxiety
aanxy22 = zeros(n_total, 1); % N anxiety episodes
ANDPBOXSX = zeros(n_total, 1); % N depressive symptoms lifetime
acontrol = 5 + 5*rand(n_total, 1); % Perceived control (5-10)
afamhdep = randi([0, 3], n_total, 1); % Family history (0-3)
appfmuse_hash = zeros(n_total, 1); % N medications

% Patients only
for i = patient_idx'
    acidep10(i) = randi([1, 10]); % 1-10 episodes
    acidep11(i) = randi([1, 36]); % 1-36 months
    acidep13(i) = randi([0, floor(acidep10(i)/2)]); % Some remitted
    acidep14(i) = randi([0, floor(acidep10(i)/3)]); % Some chronic

    if i > n_hc + n_depression % Anxiety patients
        aanxy21(i) = 10 + (Age(i)-10) * rand();
        aanxy22(i) = randi([1, 8]);
    end

    ANDPBOXSX(i) = randi([10, 50]); % Lifetime symptoms
    acontrol(i) = 2 + 6*rand(); % Lower control in patients
    appfmuse_hash(i) = randi([0, 5]); % 0-5 medications
end

%% ==========================================================================
%  GENERATE MEDICATION VARIABLES (PATIENTS ONLY)
%  ==========================================================================
fprintf('Generating medication variables...\n');

% Initialize all medication variables
assri_fr = zeros(n_total, 1); % SSRI frequency (0/1/2)
abenzo_fr = zeros(n_total, 1); % Benzo frequency (0/1/2)
atca_fr = zeros(n_total, 1); % TCA frequency (0/1/2)

assri = zeros(n_total, 1); % SSRI binary
abenzo = zeros(n_total, 1); % Benzo binary
atca = zeros(n_total, 1); % TCA binary

assri_ddd = zeros(n_total, 1); % SSRI dose
atca_ddd = zeros(n_total, 1); % TCA dose
aotherad_ddd = zeros(n_total, 1); % Other antidep dose

% Patients only - medication use correlated with symptom severity
for i = patient_idx'
    % Probability of medication increases with symptom severity
    med_prob = min(0.9, aids(i) / 60); % 0-90% based on depression

    if rand() < med_prob
        assri(i) = 1;
        assri_fr(i) = randi([1, 2]); % 1=infrequent, 2=frequent
        assri_ddd(i) = 0.5 + 2.5*rand(); % 0.5-3 DDD
    end

    if rand() < med_prob * 0.5 % 50% of those on meds also use benzos
        abenzo(i) = 1;
        abenzo_fr(i) = randi([1, 2]);
    end

    if rand() < med_prob * 0.3 % 30% on TCAs
        atca(i) = 1;
        atca_fr(i) = randi([1, 2]);
        atca_ddd(i) = 0.5 + 2*rand(); % 0.5-2.5 DDD
    end

    if rand() < med_prob * 0.2 % 20% other antidepressants
        aotherad_ddd(i) = 0.3 + 1.5*rand();
    end
end

%% ==========================================================================
%  GENERATE BENDEP SCALES (PATIENTS ONLY)
%  ==========================================================================
fprintf('Generating BENDEP scales...\n');

asumbd1 = zeros(n_total, 1); % Problematic use (0-10)
asumbd2 = zeros(n_total, 1); % Preoccupation (0-10)
asumbd3 = zeros(n_total, 1); % Lack of compliance (0-10)

% Only for patients on medication
for i = patient_idx'
    if assri(i) == 1 || atca(i) == 1 || abenzo(i) == 1
        asumbd1(i) = randi([0, 10]);
        asumbd2(i) = randi([0, 10]);
        asumbd3(i) = randi([0, 10]);
    end
end

%% ==========================================================================
%  GENERATE CHILDHOOD ADVERSITY
%  ==========================================================================
fprintf('Generating childhood adversity variables...\n');

ACTI_total = 10 + 40*rand(n_total, 1); % 10-50
ACLEI = 5 + 25*rand(n_total, 1); % 5-30
aseparation = rand(n_total, 1) > 0.7; % 30% had parental separation
adeathparent = rand(n_total, 1) > 0.9; % 10% parental death
adivorce = rand(n_total, 1) > 0.75; % 25% parental divorce

% Higher adversity in patients
ACTI_total(patient_idx) = ACTI_total(patient_idx) + 15*rand(length(patient_idx), 1);
ACLEI(patient_idx) = ACLEI(patient_idx) + 8*rand(length(patient_idx), 1);

%% ==========================================================================
%  CREATE REALISTIC CORRELATIONS
%  ==========================================================================
fprintf('Injecting realistic correlations...\n');

% Correlation 1: aids ↔ Age of Onset (r ≈ 0.3)
% Lower age of onset → higher current severity
for i = patient_idx'
    if ~isnan(AD3004AO(i))
        correlation_effect = -0.3 * (AD3004AO(i) - mean(AD3004AO(patient_idx), 'omitnan')) / std(AD3004AO(patient_idx), 'omitnan');
        aids(i) = aids(i) + 10 * correlation_effect + 5*randn();
        aids(i) = max(0, min(84, aids(i)));
    end
end

% Correlation 2: Medication DDD ↔ Symptom severity (r ≈ 0.4)
for i = patient_idx'
    if assri(i) == 1
        correlation_effect = 0.4 * (aids(i) - mean(aids(patient_idx))) / std(aids(patient_idx));
        assri_ddd(i) = assri_ddd(i) + 0.8 * correlation_effect;
        assri_ddd(i) = max(0, min(5, assri_ddd(i)));
    end
end

%% ==========================================================================
%  GENERATE DECISION SCORES WITH REALISTIC DISTRIBUTIONS
%  ==========================================================================
fprintf('Generating decision scores...\n');

% Transition-26 scores
% Mean: higher in patients, correlates with recency
Transition_26 = NaN(n_total, 1);
Transition_26(1:n_hc) = -2 + 3*randn(n_hc, 1); % HC: mean ≈ -2
Transition_26(patient_idx) = 0.5 + 2.5*randn(length(patient_idx), 1); % Patients: mean ≈ 0.5

% Add recency correlation (r ≈ 0.25)
for i = patient_idx'
    if ~isnan(AD3004RE(i))
        recency_effect = 0.25 * (AD3004RE(i) - mean(AD3004RE(patient_idx), 'omitnan')) / std(AD3004RE(patient_idx), 'omitnan');
        Transition_26(i) = Transition_26(i) + 0.8 * recency_effect;
    end
end

% Transition-27 (site-agnostic - slightly different distribution)
Transition_27 = Transition_26 + 0.3*randn(n_total, 1);

% bvFTD scores (different pattern)
bvFTD = -1 + 2.5*randn(n_total, 1);
bvFTD(patient_idx) = bvFTD(patient_idx) + 0.8*randn(length(patient_idx), 1);

% Add z-scores
Transition_26_Std = (Transition_26 - mean(Transition_26, 'omitnan')) / std(Transition_26, 'omitnan');
Transition_27_Std = (Transition_27 - mean(Transition_27, 'omitnan')) / std(Transition_27, 'omitnan');
bvFTD_Std = (bvFTD - mean(bvFTD, 'omitnan')) / std(bvFTD, 'omitnan');

% Predicted labels (binary: 1=Patient-like, 0=HC-like)
Transition_26_Label = Transition_26 > 0;
Transition_27_Label = Transition_27 > 0;
bvFTD_Label = bvFTD > 0;

%% ==========================================================================
%  CREATE MAIN TABULAR DATA FILE
%  ==========================================================================
fprintf('\nCreating main tabular data file...\n');

% Variable names must match exact spelling from original script
nesda_table = table(pident, Age, Sexe, abmi, aedu, amarpart, aLCAsubtype, ...
    aids, aidssev, aids_mood_cognition, aids_anxiety_arousal, ...
    aidsatyp, aidsmel, abaiscal, abaisev, abaisom, abaisub, aauditsc, ...
    AD2962xAO, AD2963xAO, AD3004AO, ...
    AD2962xRE, AD2963xRE, AD3004RE, ...
    acidep10, acidep11, acidep13, acidep14, ...
    aanxy21, aanxy22, ANDPBOXSX, acontrol, afamhdep, appfmuse_hash, ...
    assri_fr, abenzo_fr, atca_fr, ...
    assri, abenzo, atca, ...
    assri_ddd, atca_ddd, aotherad_ddd, ...
    asumbd1, asumbd2, asumbd3, ...
    ACTI_total, ACLEI, aseparation, adeathparent, adivorce, ...
    'VariableNames', {'pident', 'Age', 'Sexe', 'abmi', 'aedu', 'amarpart', 'aLCAsubtype', ...
    'aids', 'aidssev', 'aids_mood_cognition', 'aids_anxiety_arousal', ...
    'aidsatyp', 'aidsmel', 'abaiscal', 'abaisev', 'abaisom', 'abaisub', 'aauditsc', ...
    'AD2962xAO', 'AD2963xAO', 'AD3004AO', ...
    'AD2962xRE', 'AD2963xRE', 'AD3004RE', ...
    'acidep10', 'acidep11', 'acidep13', 'acidep14', ...
    'aanxy21', 'aanxy22', 'ANDPBOXSX', 'acontrol', 'afamhdep', 'appfmuse#', ...
    'assri_fr', 'abenzo_fr', 'atca_fr', ...
    'assri', 'abenzo', 'atca', ...
    'assri_ddd', 'atca_ddd', 'aotherad_ddd', ...
    'asumbd1', 'asumbd2', 'asumbd3', ...
    'ACTI_total', 'ACLEI', 'aseparation', 'adeathparent', 'adivorce'});

writetable(nesda_table, [output_path 'NESDA_tabular_combined_data.csv']);
fprintf('  ✓ Saved: NESDA_tabular_combined_data.csv (%d × %d)\n', height(nesda_table), width(nesda_table));

%% ==========================================================================
%  CREATE DECISION SCORE FILES
%  ==========================================================================
fprintf('\nCreating decision score files...\n');

% Transition-26
trans26_table = table(pident, Transition_26_Label, Transition_26, Transition_26_Std, ...
    'VariableNames', {'Cases', 'PRED_LABEL', 'Mean_Score', 'Std_Score'});
writetable(trans26_table, [output_path 'PRS_TransPred_A32_OOCV-26_Predictions_Cl_1PT_vs_NT.csv']);
fprintf('  ✓ Saved: PRS_TransPred_A32_OOCV-26_Predictions_Cl_1PT_vs_NT.csv\n');

% Transition-27
trans27_table = table(pident, Transition_27_Label, Transition_27, Transition_27_Std, ...
    'VariableNames', {'Cases', 'PRED_LABEL', 'Mean_Score', 'Std_Score'});
writetable(trans27_table, [output_path 'PRS_TransPred_A32_OOCV-27_Predictions_Cl_1PT_vs_NT.csv']);
fprintf('  ✓ Saved: PRS_TransPred_A32_OOCV-27_Predictions_Cl_1PT_vs_NT.csv\n');

% bvFTD
bvftd_table = table(pident, bvFTD_Label, bvFTD, bvFTD_Std, ...
    'VariableNames', {'Cases', 'PRED_LABEL', 'Mean_Score', 'Std_Score'});
writetable(bvftd_table, [output_path 'ClassModel_bvFTD-HC_A1_OOCV-6_Predictions_Cl_1bvFTD_vs_HC.csv']);
fprintf('  ✓ Saved: ClassModel_bvFTD-HC_A1_OOCV-6_Predictions_Cl_1bvFTD_vs_HC.csv\n');

%% ==========================================================================
%  CREATE DIAGNOSIS GROUP FILES
%  ==========================================================================
fprintf('\nCreating diagnosis group files...\n');

% HC file
hc_table = table(pident(1:n_hc), repmat({'HC'}, n_hc, 1), ...
    'VariableNames', {'pident', 'diagnosis_group'});
writetable(hc_table, [output_path 'NESDA_HC.csv']);
fprintf('  ✓ Saved: NESDA_HC.csv (n=%d)\n', n_hc);

% Patients file
diagnosis_group = cell(n_total - n_hc, 1);
diagnosis_group(1:n_depression) = {'Depression'};
diagnosis_group(n_depression+1:n_depression+n_anxiety) = {'Anxiety'};
diagnosis_group(n_depression+n_anxiety+1:end) = {'Comorbid'};

patients_table = table(pident(n_hc+1:end), diagnosis_group, ...
    'VariableNames', {'pident', 'diagnosis_group'});
writetable(patients_table, [output_path 'NESDA_Patients.csv']);
fprintf('  ✓ Saved: NESDA_Patients.csv (n=%d)\n', n_total - n_hc);
fprintf('    Depression: %d\n', n_depression);
fprintf('    Anxiety: %d\n', n_anxiety);
fprintf('    Comorbid: %d\n', n_comorbid);

%% ==========================================================================
%  SUMMARY STATISTICS
%  ==========================================================================
fprintf('\n==========================================================\n');
fprintf('  SYNTHETIC DATA GENERATION COMPLETE\n');
fprintf('==========================================================\n\n');

fprintf('DATASET SUMMARY:\n');
fprintf('  Total subjects: %d\n', n_total);
fprintf('  HC: %d (%.1f%%)\n', n_hc, 100*n_hc/n_total);
fprintf('  Patients: %d (%.1f%%)\n\n', n_total-n_hc, 100*(n_total-n_hc)/n_total);

fprintf('SYMPTOM SEVERITY (mean ± SD):\n');
fprintf('  HC Depression (IDS): %.1f ± %.1f\n', mean(aids(1:n_hc)), std(aids(1:n_hc)));
fprintf('  Patient Depression (IDS): %.1f ± %.1f\n', mean(aids(patient_idx)), std(aids(patient_idx)));
fprintf('  HC Anxiety (BAI): %.1f ± %.1f\n', mean(abaiscal(1:n_hc)), std(abaiscal(1:n_hc)));
fprintf('  Patient Anxiety (BAI): %.1f ± %.1f\n\n', mean(abaiscal(patient_idx)), std(abaiscal(patient_idx)));

fprintf('MEDICATION USE (patients only):\n');
fprintf('  SSRI: %d (%.1f%%)\n', sum(assri(patient_idx)), 100*mean(assri(patient_idx)));
fprintf('  Benzodiazepines: %d (%.1f%%)\n', sum(abenzo(patient_idx)), 100*mean(abenzo(patient_idx)));
fprintf('  TCAs: %d (%.1f%%)\n\n', sum(atca(patient_idx)), 100*mean(atca(patient_idx)));

fprintf('DECISION SCORES (mean ± SD):\n');
fprintf('  Transition-26:\n');
fprintf('    HC: %.2f ± %.2f\n', mean(Transition_26(1:n_hc)), std(Transition_26(1:n_hc)));
fprintf('    Patients: %.2f ± %.2f\n', mean(Transition_26(patient_idx)), std(Transition_26(patient_idx)));
fprintf('  bvFTD:\n');
fprintf('    HC: %.2f ± %.2f\n', mean(bvFTD(1:n_hc)), std(bvFTD(1:n_hc)));
fprintf('    Patients: %.2f ± %.2f\n\n', mean(bvFTD(patient_idx)), std(bvFTD(patient_idx)));

fprintf('CORRELATIONS (patients only):\n');
valid_ao = ~isnan(AD3004AO(patient_idx));
if sum(valid_ao) > 30
    [r_ao_aids, p_ao_aids] = corr(AD3004AO(patient_idx(valid_ao)), aids(patient_idx(valid_ao)));
    fprintf('  Age of Onset ↔ Depression Severity: r=%.3f, p=%.4f\n', r_ao_aids, p_ao_aids);
end

valid_rec = ~isnan(AD3004RE(patient_idx));
if sum(valid_rec) > 30
    [r_rec_ds, p_rec_ds] = corr(AD3004RE(patient_idx(valid_rec)), Transition_26(patient_idx(valid_rec)));
    fprintf('  Recency ↔ Transition-26: r=%.3f, p=%.4f\n', r_rec_ds, p_rec_ds);
end

med_patients = patient_idx(assri(patient_idx) == 1);
if length(med_patients) > 30
    [r_med_aids, p_med_aids] = corr(aids(med_patients), assri_ddd(med_patients));
    fprintf('  Depression ↔ SSRI Dose: r=%.3f, p=%.4f\n\n', r_med_aids, p_med_aids);
end

fprintf('All files saved to: %s\n', output_path);
fprintf('==========================================================\n');
