function eeg_set = fun01_mat2set(cfg, subj_dir, file_name)

if isempty(cfg)
    project_dir = '/media/DATA/avitale/cmi_eeg'
    %project_dir = 'D:\IIT\_PROJECT\CMI_EEG_PREProcess'
    %project_dir = 'C:\Users\Utente\Desktop\CMI_EEG_PREProcess'
    
    subj_dir = 'NDARME930DE7'
    %subj_dir = 'NDARDL511UND'
    
end

if isempty(file_name)
    file_name = 'RestingState.mat';   
    % or 
    %file_name = 'Video-DM.mat';
    %file_name = 'desme.mat';
end

% - - - - - - -  - - - - - - - -
if strcmp(file_name, 'RestingState.mat'); 
    suffix = 'rs.set';
    trigger_id = [ ];
    % 90: start of Resting EEG paradigm
    % 20: eyes open start
    % 30: eyes closed start

elseif strcmp(file_name, 'desme.mat')
    suffix = 'desme.set';
    trigger_id = [ ];
    % 8_ = Start of Video: usually is video 3
    % 10_ = Stop of Video 
end


% = = = = = = = = = = == = = = = = 
% PARAMETERS
do_tmp = 0;  % temporary file locations
do_save_eeg_set = 1;


% = = = = = = = = = = == = = = = = 
%0: OPEN EEGLAB in NO GUI modality:
fprintf('... \n add toolbox');

eeglab_dir = fullfile(project_dir, 'tool', 'eeglab_20201226');
cd(eeglab_dir);
eeglab('nogui');


% = = = = = = = = = = == = = = = = 
%1: SUBJ DATA DIR
 
try
    subj_data_dir = fullfile(project_dir, 'data', subj_dir)
    if do_tmp
        subj_data_dir = fullfile(project_dir, 'data_prep')
    end
    cd(subj_data_dir);
    disp(pwd)
    disp(dir)

% = = = = = = = = = = == = = = = = 
%2: LOAD .mat (without eeglab functions) 
    if do_tmp
        file_name = [ subj_dir '_' file_name ]
    else
        cd(fullfile(subj_data_dir,'EEG', 'raw', 'mat_format'))
    end

    fprintf(['...loading \n' file_name ])
    load(file_name, 'EEG')
    eeg_raw = EEG; %EEG = [];
    sample_rate = eeg_raw.srate;
    

%3: ADD CHANNEL INFO:
    eeg_raw =pop_chanedit(eeg_raw, ...
            'load',{fullfile(project_dir, 'GSN-HydroCel-129.sfp'),'filetype','sfp'});
            %'load',{fullfile(project_dir, 'data', 'GSN-HydroCel-129.sfp'),'filetype','sfp'});


% =========================================================
%4: create LATENCY (and latency_sec) column in the event field
% =========================================================
    n_event = length(eeg_raw.event)
                      
    %sample_field = extractfield(eeg_raw.event, 'sample')';
    for i_event = 1:n_event 
        % latency
        eeg_raw.event(i_event).latency = eeg_raw.event(i_event).sample;
        % latency_sec
        eeg_raw.event(i_event).latency_sec = (eeg_raw.event(i_event).sample -1 )/ sample_rate;                
    end
            
    % make urevent field
    eeg_raw = eeg_checkset(eeg_raw, 'makeur')

    %disp(eeg_raw.event)


%5:  REMOVE junk/interval data = = = = = = = =  == = = = = = = 
    % BEFORE the first trigger
    % and AFTER the last trigger
%    trigger1_sample = []; % ONSET
%    trigger2_sample = []; % OFFSET

    if 
%    for i_event = 1:length(eeg_input.event)
%        if strcmp(eeg_input.event(i_event).type, trigger_tmp{1,1})
%            trigger1_sample = [ trigger1_sample; eeg_input.event(i_event).sample ];
%        elseif strcmp(eeg_input.event(i_event).type, trigger_tmp{1,2})
%            trigger2_sample = [ trigger2_sample; eeg_input.event(i_event).sample ];
%        end
%    end

%  TO DO = = = = = = = =  == = = = = = = 


if do_save_eeg_set
    disp('...saving .set file')
        cd(fullfile(project_dir, 'data_prep'))
        save_name = [ subj_dir '_' suffix ] 
        pop_saveset( eeg_raw, 'filename', save_name) 
end

catch ME
    disp(ME)
end

disp('...end');
