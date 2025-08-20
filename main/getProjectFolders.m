%%
% SPDX-FileCopyrightText: 2023 Matthew Millard <millard.matthew@gmail.com>
%
% SPDX-License-Identifier: MIT
%
% If you use this code in your work please cite the pre-print of this paper
% or the most recent peer-reviewed version of this paper:
%
%    Matthew Millard, David W. Franklin, Walter Herzog. 
%    A three filament mechanistic model of musculotendon force and impedance. 
%    bioRxiv 2023.03.27.534347; doi: https://doi.org/10.1101/2023.03.27.534347 
%
%%

function projectFolders = getProjectFolders(rootProjectDirectoryFullPath)

currDir = pwd();

%check the root directory
cd(rootProjectDirectoryFullPath);
rootDirContents = dir();


flag_rootDirPathValid = 0;
for i=1:1:length(rootDirContents)
    if(strcmp(rootDirContents(i).name,'.rootDirectory') && ...
       rootDirContents(i).isdir == 0)
        flag_rootDirPathValid = 1;
    end
end
cd(currDir);

assert(flag_rootDirPathValid==1, ['Error: the rootProjectDirectoryFullPath ',...
    'does not appear to be the root project directory because it is missing ',...
    'hidden file (.rootDirectory) that marks it as the root project directory.']);

projectFolders.root = rootProjectDirectoryFullPath;

projectFolders.main =  fullfile(rootProjectDirectoryFullPath,'main');

projectFolders.data      = fullfile(rootProjectDirectoryFullPath,'data'        );   
projectFolders.data_600A = fullfile(rootProjectDirectoryFullPath,'data','600A');   
projectFolders.data_610A = fullfile(rootProjectDirectoryFullPath,'data','610A');   

projectFolders.common = fullfile(rootProjectDirectoryFullPath,'common');   

projectFolders.postprocessing = fullfile(rootProjectDirectoryFullPath,'postprocessing');   


projectFolders.aurora600A = fullfile(rootProjectDirectoryFullPath,'aurora600A');   
projectFolders.aurora600ACompiled = fullfile(rootProjectDirectoryFullPath,'aurora600ACompiled');   

projectFolders.aurora610A = fullfile(rootProjectDirectoryFullPath,'aurora610A');   

projectFolders.output         = fullfile(rootProjectDirectoryFullPath,'output'        );  
projectFolders.output_plots   = fullfile(rootProjectDirectoryFullPath,'output','plots');  
projectFolders.output_structs = fullfile(rootProjectDirectoryFullPath,'output','structs');  


