function dpfData = readAuroraData600A(fullFilePath)
%%
% This is a limited function, as I do not have the time at the moment
% to write a function to read in all of the metadata
%
% This function will:
% 1. Go to *** Force and Length Signals vs Time ***
% 2. Put the column names in a an array of cells
% 3. Put the units in an array of cells
% 4. Put the data into a matrix
%
%
%%

% Several sections
%
% Setup Parameters
% Calibration Parameters
% Test Protocol Parameters
% Force and Length Signals vs Time
%
% Comment '***'
% 
%----------------------------------------
% Beginning (A/D Sampling rate on wards)
%----------------------------------------
%
%   field, numerical-value, unit    
%   field, numerical-value
%   field, string-value
%
%
% Field names:
% : trim names before ':'
% : trim before '('
% : trim leading/trailing spaces
% : trim repeated internal spaces to 1
% :fill spaces with '_'
%
% I can identify type by:
% - get all text after ':'
% - trim all white space
% - Is there a space? Then there is a unit and this is a number
%   
%   struct.field_name = value
%   struct.field_name.unit
%  
% - If not, is there a character? Then this is a string
% - If not, then this is a value
%
%----------------------------------------
% Calibration Table
%----------------------------------------
%
% No ':'
% No "*"
% After 
%  -Removing all tabs
%  -collapsing all subsequent spaces to 1
%
%   Header: several fields separated by ' '
%   Units: several fields separated by 
%   
%