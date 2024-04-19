


%=====================================================================
% Set paths for EEGLAB AND FIELDTRIP
eeglab_path = '/Users/dhewitt/Analysis/eeglab2023.0/'; addpath(eeglab_path);
% %=====================================================================
%sub  = {'02', '03', '04', '05', '06', '08', '09', '10', '11', '12', '13', '14', '15', '16','17','19', '20','21','22','24','25','26','27','28','29','30'};
sub  = {'02'};
dir  = '/Users/dhewitt/Data/pps/';

%=====================================================================

for iSub=1:numel(sub)
    currentSubject = sub{iSub};

     rawWname = [fullfile(dir, ['P', currentSubject, '/P', currentSubject, '_allepoched_2702.set'])]; %%% these are in the wrong way round, but the script works.
     procWname = [fullfile(dir, ['P', currentSubject, '/P', currentSubject, '_allepoched_cleaned_2702.set'])];
     csvOutname = [fullfile(dir, ['P', currentSubject, '/P', currentSubject, '_newEVT.csv'])];

    %rawWname = [fullfile(dir, ['P', currentSubject, '_allepoched_2702.set'])]; %%% these are in the wrong way round, but the script works.
    %procWname = [fullfile(dir, ['P', currentSubject, '_allepoched_cleaned_2702.set'])];
    %csvOutname = [fullfile(dir, ['P', currentSubject,  '_newEVT.csv'])];

    rEEG = pop_loadset(rawWname);
    nEEG = pop_loadset(procWname);

    nEEG_urevent = cellstr(num2str([nEEG.event.urevent]'));
    rEEG_urevent = cellstr(num2str([rEEG.event.urevent]'));

    indices_not_in_nEEG = find(~ismember(rEEG_urevent, nEEG_urevent));

    % Making a new table with only the indices not in nEEG
    is_in_nEEG_array = ones(size(rEEG.event));
    is_in_nEEG_array(indices_not_in_nEEG) = 0;

    %-----

    % Making a new event file

    newEventFile = struct2table(rEEG.event);

    conditionNumbers = cellfun(@(x) x(end:end), newEventFile.type, 'UniformOutput', false);
    newEventFile.Block = conditionNumbers;
    newEventFile.type = cellfun(@(x) x(1:end-1), newEventFile.type, 'UniformOutput', false);

    newEventFile.Include = is_in_nEEG_array'; % logical for if the trial was included or rejected

    % Getting rid of things we don't need
    idx_to_remove = contains(newEventFile.type, {'objAppear', 'etFixation', 'objDisappear'});
    newEventFile = newEventFile(~idx_to_remove, :);

    fields_to_remove = {'duration', 'channel', 'bvtime', 'visible', 'code', 'bvmknum', 'urevent'};
    newEventFile = removevars(newEventFile, fields_to_remove);

    %-----

    cue_idx = ismember(newEventFile.type, {'middle', 'left', 'right'});
    cueTable = newEventFile(cue_idx, :);

    pain_idx = ismember(newEventFile.type, {'PCollShock', 'PCollNoShock', 'nPCollNoShock'});
    painTable = newEventFile(pain_idx, :);
    painTable = removevars(painTable, {'latency', 'Block','Include'});
    painTable.Properties.VariableNames{'type'} = 'pain';

    newEventFile = outerjoin(cueTable, painTable, 'MergeKeys', true);

    %-----

    % Saving the table
    writetable(newEventFile, csvOutname);

    %-----
end

