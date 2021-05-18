clear all

subj_list = { ...
            % 5yo - - - - - - - - - - - - -  
            %'NDARME930DE7'; 
            %'NDARDL511UND';
            %'NDARGB441VVD';
            %'NDARRZ199KNG';
            %'NDARYL272HDW';
            
            % 20yo - - - - - - - - - - - - -  
            
            }

%cfg.do_server = 1; cfg.do_local = 0;
cfg.do_server = 0; cfg.do_local = 1;

for i_subj = 1:length(subj_list)
    %i_subj=2
    subj_name = subj_list{i_subj}
    fun01b_mat2set(cfg, subj_name, 'RestingState.mat');
end


%%
function fun01b_mat2set(cfg, subj_name, file_name)
%function eeg_set = fun01b_mat2set(cfg, subj_name, file_name)

%if isempty(cfg)
    if cfg.do_server
        project_dir = '/media/DATA/avitale/cmi_eeg'
    elseif cfg.do_local
        %project_dir = 'D:\IIT\_PROJECT\CMI_EEG_PREProcess'
        project_dir = 'C:\Users\Utente\Desktop\CMI_EEG_PREProcess'
    end
%end
save_dir = fullfile(project_dir, 'data_set')

if isempty(subj_name)
    subj_name = 'NDARME930DE7'
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
    trigger_id = {'90  '; '20  '; '30  '};
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
    subj_data_dir = fullfile(project_dir, 'data', subj_name)
    if do_tmp
        subj_data_dir = fullfile(project_dir, 'data_prep')
    end
    cd(subj_data_dir);
    disp(pwd)
    disp(dir)

% = = = = = = = = = = == = = = = = 
%2: LOAD .mat (without eeglab functions) 
    if do_tmp
        file_name = [ subj_name '_' file_name ]
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
    event_cell = {};
    %sample_field = extractfield(eeg_raw.event, 'sample')';
    for i_event = 1:n_event 
        event_cell{i_event,1} = eeg_raw.event(i_event).type
        % latency
        eeg_raw.event(i_event).latency = eeg_raw.event(i_event).sample;
        % latency_sec
        eeg_raw.event(i_event).latency_sec = (eeg_raw.event(i_event).sample -1 )/ sample_rate;                
    end
            
    % make urevent field
    eeg_raw = eeg_checkset(eeg_raw, 'makeur')
    %pop_saveset(eeg_raw)
    
    %disp(eeg_raw.event)

% = = = = = = = = = = == = = = = = 
%5:  REMOVE junk/interval data 
    % BEFORE the first valid trigger
    % and AFTER the last trigger
%    trigger1_sample = []; % ONSET
%    trigger2_sample = []; % OFFSET
    sample_onset = []; sample_offset = [];

    if strcmp(file_name, 'RestingState.mat')
        for i_event = 1:length(event_cell)
            if strcmp(event_cell{i_event,1}, trigger_id{2}) || ...
               strcmp(event_cell{i_event,1}, trigger_id{3})
                if strcmp(event_cell{i_event-1,1}, trigger_id{1})
                    sample_onset = eeg_raw.event(i_event).sample;
                
                elseif ~strcmp(event_cell{i_event+1,1}, trigger_id{2}) && ...
                       ~strcmp(event_cell{i_event+1,1}, trigger_id{3})
                    sample_offset = eeg_raw.event(i_event+1).sample;
                end
            end
        end
        
    %elseif strcmp(file_name, 'desme.mat')
        % TO DO !!!
    end
                    
    eeg_raw = pop_select( eeg_raw, 'point',[sample_onset-1  sample_offset] );
    %EEG = pop_select( EEG, 'point',[sample_onset-1  sample_offset-1] );
    
    
% = = = = = = = = = = == = = = = = 
% SAVE .set file
if do_save_eeg_set
    fprintf('... \n saving .set file')
    if ~exist(save_dir); mkdir(save_dir); end
            
    cd(save_dir)
    save_name = [ subj_name '_' suffix ] 
    pop_saveset( eeg_raw, 'filename', save_name); 
end

catch ME
    disp(ME)
end

disp('...end');
end