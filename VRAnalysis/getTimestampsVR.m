%% This function takes the input as a .json file, with full directory and extension, 
% and returns a .csv file containing the trial conditions, cues, and
% timestamps. 
% Use is getTimestampsVR('/Users/dhewitt/Data/pps/P02/P02___Control_Data__.json','/Users/dhewitt/Data/pps/P02/P02_Extracted',true)
% Updated to correct the number of trials in cond and extn blocks 15/4

function [condTable] = getTimestampsVR(input, output, dispOption)
%  GETTIMESTAMPSVR Brief summary of this function.
%
% Detailed explanation of this function.
fileName = input; % filename in JSON extension
str = fileread(fileName); % dedicated for reading files as text
data = jsondecode(str); % Using the jsondecode function to parse JSON from string

% Define the target string you want to search for
targetString = 'start_new_trial_condition';

c=1;
for i=1:numel(data.o8Y6VNWF7orzDfPGCrJh)
    structContents = data.o8Y6VNWF7orzDfPGCrJh{i,1};
    if isfield(structContents, targetString)
        matchingValues{c,1} = structContents;
        c=c+1;
    end
end

% Create empty cell arrays to store values from the fields
numTrials = numel(matchingValues);
start_new_trial_condition = cell(numTrials, 1);
set_using_cue = cell(numTrials, 1);
%set_speed_condition = cell(numTrials, 1);
timestamp = cell(numTrials, 1);

% Extract values from the structs and populate the cell arrays
for i = 1:numTrials
    structContents = matchingValues{i};

    % Check if the field exists before accessing it
    if isfield(structContents, 'start_new_trial_condition')
        start_new_trial_condition{i} = structContents.start_new_trial_condition;
    end

    if isfield(structContents, 'set_using_cue')
        set_using_cue{i} = structContents.set_using_cue;
    end

    % if isfield(structContents, 'set_speed_condition')
    %     set_speed_condition{i} = structContents.set_speed_condition;
    % end

    if isfield(structContents, 'timestamp')
        timestamp{i} = structContents.timestamp;
    end
end

if numTrials == 360
    condorder = sort([repelem([1,3],72)'; repelem([2,4],108)']);
    values = [1:72,1:108,1:72,1:108]';
else
    disp('Some blocks missing - trial numbers not added - check data log')
    condorder = zeros(numTrials,2);
    values = ones(numTrials,2);
end

% Create a table from the cell arrays
%T = table(start_new_trial_condition, set_using_cue, set_speed_condition,
%timestamp);
T = table(values, condorder, start_new_trial_condition, set_using_cue, timestamp);

% Use the format function to control the display format of the 'timestamp'
% column
format long  % Display timestamps in long format
T.timestamp = cell2mat(T.timestamp);  % Convert cell array to a numeric array

% Display the table
if dispOption == true
    disp(T);
else
    disp('Table Created')
end

fileName = [output '.csv'];

writetable(T, fileName);

end