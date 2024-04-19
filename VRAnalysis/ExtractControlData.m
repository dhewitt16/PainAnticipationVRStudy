
dir  = '/Users/dhewitt/Data/pps/';
subs = {'30'};


for i=1:numel(subs)
    currentSubject = subs{i};
    currentDirectory = [dir 'P' currentSubject];
    file2load = ([currentDirectory '/P' currentSubject '__Control_Data__.json']); %%some files like 2 have an extra _ before __Control_Data
    outname = ([currentDirectory '/P' currentSubject '_Extractednew']);

    if exist("file2load") == 0
        disp(['File ' file2load ' does not exist']);
        return
    end

    getTimestampsVR(file2load,outname,false);

end
