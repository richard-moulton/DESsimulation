function SModel = xmdParse(varargin)
%XMDPARSE Parse a IDES XMD model file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   File:           xmdParse.m
%   Author:     AJ Marasco
%   Version:    beta
%   Date:       22 April 2019
%
%   Package: This file is part of the DESFrame package.
%
%   Description: Reads an IDES model file (.xmd) and generates the model 
%       structure for use in simulations.
%
%   Usage:
%       xmdParse() - Opens a gui for the user to select an appropriate .xmd file and
%       parses it.
%
%       xmdParse(sFilename) - opens the file <sFilename> and parses it. sFilename is a
%       MATLAB string (char array) and can be either a full path to a file, or a simply
%       the name of a file in the current working director.
%
%   Outputs: Information about the model in a format TBD.
%
%   See also: 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% ARGUMENT CHECKING
narginchk(0,1);
%% SOURCE FILE HANDLING
% User may select a file from the gui, or provide a file name. The file name, full file
% path, date loaded, and date modified are all tracked for auto-updating if the source
% model is updated after the last load date.
sourcefile = struct('filename',[],'path',[],'loaddate',[],'moddate',[]);
switch nargin
    % 0 arguments, open gui and get file from user input
    case 0
        [filename,path] = uigetfile('*.xmd');
        if(~filename)
            error('DESFrame:XMDParse:UserCancel',...
                'I hope that was as good for you as it was for me.');
        end
        [path,filename,extension] = fileparts([path,filename]);
    % 1 argument, assume it is a filename with or without full path.
    case 1
        [path,filename,extension] = fileparts(varargin{1});
end
if(~strcmp(extension,'.xmd'))
    error('DESFrame:XMDParse:UnsupportedFileType',...
        'Unsupported file type %s. Only .xmd files are currently supported.',extension);
end
if(isempty(path)|~path)
    path = pwd;
end
sourcefile.filename = filename;
sourcefile.path = path;
sourcefile.loaddate = now();
sourcefile.fullfilename = fullfile(path,[filename,extension]);
dirInfo = dir(sourcefile.fullfilename);
sourcefile.moddate = dirInfo.datenum;

%% BEGIN FILE READ
try
    docNode = xmlread(sourcefile.fullfilename);
catch
    error('Failed to read XML file: %s.',sourcefile.fullfilename);
end

% The model node is the main node of interest. It contains a child element (data), which
% contains a an array of children that are either states, events or transitions.
numStates = 0;
numEvents = 0;
numTransitions = 0;
modelNode = findChildNode(docNode,'model');
dataNode = findChildNode(modelNode,'data');
% We now have to loop through all the children nodes and extract the states, events and
% transitions.
currNode = dataNode.getFirstChild;
while(~isempty(currNode))
    % getNodeName returns a java.lang.String, so we need to conver that to a matlab string
    % (character vector) first
    currNodeName = char(currNode.getNodeName);
    propertyNode = findChildNode(currNode,'properties');
    nameNode = findChildNode(currNode,'name');
    switch currNodeName
        case 'state'
            fprintf('Found a state!\n');
            fprintf('State number: %d\n', str2double(char(currNode.getAttribute('id'))));
            %todo: ensure properties node is found and handle errors
            if(hasChildNode(propertyNode,'initial'))
                fprintf('\t State is the initial state!\n');
            end
            if(hasChildNode(propertyNode,'marked'))
                fprintf('\t State is marked!\n');
            end
            %todo: ensure name node is found and handle errors
            fprintf('State is named: %s\n', nameNode.getTextContent);
            numStates = numStates + 1;
        case 'event'
            fprintf('Found an event!\n');
            fprintf('Event number: %d\n', str2double(char(currNode.getAttribute('id'))));
            %todo: ensure properties node is found and handle errors
            if(hasChildNode(propertyNode,'controllable'))
                fprintf('\t Event is controllable!\n');
            end
            if(hasChildNode(propertyNode,'observable'))
                fprintf('\t Event is observable!\n');
            end
            %todo: ensure name node is found and handle errors
            fprintf('Event is named: %s\n', nameNode.getTextContent);
            numEvents = numEvents + 1;
        case 'transition'
            % Transitions have no properties, only attributes
            fprintf('Found a transition!\n');
            fprintf('Transition number: %d\n', str2double(char(currNode.getAttribute('id'))));
            fprintf('\t Transition from state %d to %d on event %d\n',...
                str2double(char(currNode.getAttribute('source'))),...
                str2double(char(currNode.getAttribute('target'))),...
                str2double(char(currNode.getAttribute('event'))));
            numTransitions = numTransitions + 1;
    end
    currNode = currNode.getNextSibling;
end
SModel.States = numStates;
SModel.Events = numEvents;
SModel.Transitions = numTransitions;


    function foundNode = findChildNode(parentNode,sNodeName)
        fc = parentNode.getFirstChild;
        while(~isempty(fc) && ~strcmp(fc.getNodeName,sNodeName))
            fc = fc.getNextSibling;
        end
        if(isempty(fc))
            foundNode = 0;
        else
            foundNode = fc;
            return;
        end
    end
    
    function bNodeHasChild = hasChildNode(parentNode,sNodeName)
        bNodeHasChild = false;
        fc = parentNode.getFirstChild;
        while(~isempty(fc) && ~strcmp(fc.getNodeName,sNodeName))
            fc = fc.getNextSibling;
        end
        if(~isempty(fc))
            bNodeHasChild = true;
        end
    end
end