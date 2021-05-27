function mat2set_epoched_data(cfg)

% FUNCTION 
% import a 3d matrix (with dimension: channel, timepoint, trial)
% into a structure readable from eeglab (.set format)

% INPUT:
%  cfg: CONFIGURATION structure with this mandatory fields:
%     .project_dir         : where data, code and other folder are stored 
%     .subj_id =           : whit the subject ID (i.e.:) 'NDARAA898JB2_20180329'
%     .cond_id =           : specific condition of interest:  i.e: 'f' for face processing
%     .eeglab_dir          : folder with all the eeglab functions (i.e: EEG\eeglab_20201226')
%     
%     .chanloc_struct      : structure with channel locations details
%                            (i.e.: EGI_129_chanloc_struct.mat)
%
%     .sample_rate         : in Hz (i.e: 1000); 
%     .n_sample            : number of timepoint (second dimension of the 3d matrix);
%     .time_min_sec        : epoch onset in second (i.e.: -0.2);

      % OPTIONAL - - - - - - - - - 
%     .continuous = 0;  % if 0 -> epoched data (3d matrix)
%     .chan_file           : .sfp file with channel location for 128 EGI layout


% OUTPUT:
%   the function will save one .set file for each field of the data with:
%   subj_ID +  field condition in the data structure 
%   example:  NDARAA898JB2_20180329_FaceInverted.set

% by andrea.vitale@gmail.com 20210527
%% 
% 

    %clear all
    %cfg = [];
    
    if isempty(cfg)
        cfg = [];
        %cfg.continuous = 0;  % if 0 -> epoched data (3d matrix)
        cfg.project_dir         = 'D:\IIT\_PROJECT\ABC_CT_EEG'
        cfg.subj_id             = 'NDARAA898JB2_20180329'
        cfg.cond_id             = 'f'
        
        cfg.eeglab_dir          = 'D:\IIT\EEG\eeglab_20201226'
        cfg.chanloc_struct      = 'EGI_129_chanloc_struct.mat'
        
        cfg.sample_rate         = 1000; 
        cfg.n_sample            = 700;
        cfg.time_min_sec        = -0.2;
    end
    
    
%% ADD TOOLBOX

    % EEGLAB GUI:
    cd(cfg.eeglab_dir)
    eeglab
    
    do_chan_location = 1
    do_import_epoch = 1
    do_save = 0
    do_save_concat = 1
    
    
%% LOAD SUBJECT DATA
% and import in eeglab structure

    cd(fullfile(cfg.project_dir,'data'))
    data_struct = load([ cfg.subj_id '_' cfg.cond_id '.mat' ])
    
    
    struct_field = fieldnames(data_struct)
    
    for i_data = 1:length(struct_field)
        %data_tmp = data_struct.struct_field(i_data)
        eval([ 'data_tmp = data_struct.' struct_field{i_data} ';']);
        
        
        %% IMPORT 3d DATA INTO EEGLAB STRUCTURE - - - - - - - - - - -  - - - -
        eeg_struct = pop_importdata('dataformat','matlab','nbchan',0, 'data', data_tmp, ...
                             'setname', struct_field{i_data}, ...
                             'srate', cfg.sample_rate, 'pnts', cfg.n_sample, 'xmin', cfg.time_min_sec);
                             %'data','D:\\IIT\\_PROJECT\\ABC_CT_EEG\\data\\FaceInverted.mat',
        
        if do_chan_location
            
            load(fullfile(cfg.project_dir, 'data', cfg.chanloc_struct))
            n_chan = eeg_struct.nbchan;
            
            % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            % some more clever way of sub-selecting the channel has to be implemented
            % once we know the correct location of the channels
            chanloc_struct = chanloc_struct(1:n_chan);
            
            eeg_struct.chanlocs = chanloc_struct;        
            figure; topoplot([],eeg_struct.chanlocs, 'style', 'blank',  'electrodes', 'labelpoint', 'chaninfo', eeg_struct.chaninfo);
        end
        
        if do_import_epoch
            n_epoch = size(data_tmp,3);
            epoch_array = [];
            cond_cell = {};
            for i_epoch = 1:n_epoch
%                 epoch_array(i_epoch,1) = i_epoch;
%                 epoch_array(i_epoch,2) = i_data;
                
                %cond_array(i_epoch,1) = i_data;
                cond_cell{i_epoch,1} = struct_field{i_data};
            end
            
%             epoch_field = { 'epoch_array', 'cond_array'}
%             eeg_struct = pop_importepoch(eeg_struct, epoch_array, epoch_field)
            
            epoch_field = {'cond_cell'}
            eeg_struct = pop_importepoch(eeg_struct, cond_cell, epoch_field)
            %eeg_struct = pop_importepoch(eeg_struct, 'filename', epoch_array, 'fieldlist', epoch_field)
                        
%             % convert in txt format;
%             epoch_table = table(epoch_array, cond_array)
%             writetable(epoch_table,'epoch_tmp.txt');
%             %type epoch_tmp.txt
                                
        if do_save
            save_name = [ cfg.subj_id '_' struct_field{i_data} ]
            disp('saving...')
            pop_saveset(eeg_struct, 'filename', save_name)
        end
        
        if do_save_concat 
            save_name = [ cfg.subj_id '_' cfg.cond_id ]
            if i_data > 1
                eeg_concat = pop_mergeset( eeg_concat, eeg_struct); %keepall
            else
                eeg_concat = eeg_struct;
            end
            if i_data == length(struct_field)
                pop_saveset(eeg_concat, 'filename', save_name)
            end
        end                        
    end
end
%% 
