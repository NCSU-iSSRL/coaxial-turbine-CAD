% function to auto generate a solidworks macro to import qblade geometry
% first, export blade geometry from qblade in .txt format
% however many span-wise selections that are exported are how many cross-sections will be generated
% use ~20 span-wise stations
% use 20-30 chord-wise points

% if macro isn't working, make sure that the curve through XYZ closes,
% i.e., the first and last points are the same

clear;clc;
bladeCoords = importfile('C:\Users\cmmcguir\OneDrive - North Carolina State University\iSSRL\Research\coaxial-turbine-CAD\gulf_stream_turbine\QBlade_blades\txt\downstream_003.txt');

crossSectionStations = unique(bladeCoords(:,3));

runTimeStamp = datestr(now, 'YYYY_mm_DD_HH_MM_ss');
macroFilename = sprintf('macro_%s.txt',runTimeStamp);
fid = fopen(macroFilename, 'w');

setupMacro(fid)
for q = 1:length(crossSectionStations)
    addSubFuncCall(fid, q);
end
endMainFunc(fid)

for q = 1:length(crossSectionStations)
    z_coord = crossSectionStations(q);
    xyz_coords = bladeCoords(bladeCoords(:,3) == z_coord,:);

    addCurveThroughPointsMacro(fid, xyz_coords, q)
    addSketchForCurve(fid,q,z_coord)
    endSub(fid)
end



disp('Generated as:')
disp(macroFilename)
disp('Copy the contents of this file to a macro created in Solidworks, then run.')
fclose("all");
%% functions
function bladeCoords = importfile(filename, startRow, endRow)
%IMPORTFILE Import numeric data from a text file as a matrix.
%   THIRD = IMPORTFILE(FILENAME)
%   Reads data from text file FILENAME for the default selection.
%
%   THIRD = IMPORTFILE(FILENAME, STARTROW, ENDROW)
%   Reads data from rows STARTROW through ENDROW of text file FILENAME.
%
% Example:
%   Third = importfile('Third.txt', 3, 8391);
%
%    See also TEXTSCAN.

% Auto-generated by MATLAB on 2024/01/10 15:57:47

%% Initialize variables.
if nargin<=2
    startRow = 3;
    endRow = inf;
end

%% Format for each line of text:
%   column1: double (%f)
%	column2: double (%f)
%   column3: double (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%14f%24f%f%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this code. If an error occurs for a different file, try regenerating the code from the Import Tool.
textscan(fileID, '%[^\n\r]', startRow(1)-1, 'WhiteSpace', '', 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', '', 'WhiteSpace', '', 'TextType', 'string', 'EmptyValue', NaN, 'ReturnOnError', false, 'EndOfLine', '\r\n');
for block=2:length(startRow)
    frewind(fileID);
    textscan(fileID, '%[^\n\r]', startRow(block)-1, 'WhiteSpace', '', 'ReturnOnError', false);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', '', 'WhiteSpace', '', 'TextType', 'string', 'EmptyValue', NaN, 'ReturnOnError', false, 'EndOfLine', '\r\n');
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post processing code is included. To generate code which works for unimportable data, select unimportable cells in a file and regenerate the script.

%% Create output variable
bladeCoords = [dataArray{1:end-1}];
end

function setupMacro(fid)
    % fprintf(fid,['Dim swApp As Object\nDim Part As Object\nDim boolstatus As Boolean\n' ...
    %     'Dim longstatus As Long, longwarnings As Long\n\nSub main()\n\nSet swApp = Application.SldWorks\n\n' ...
    %     'Set Part = swApp.ActiveDoc\nDim COSMOSWORKSObj As Object\nDim CWAddinCallBackObj As Object\n' ...
    %     'Set CWAddinCallBackObj = swApp.GetAddInObject("CosmosWorks.CosmosWorks")\n' ...
    %     'Set COSMOSWORKSObj = CWAddinCallBackObj.COSMOSWORKS\n']);

    fprintf(fid,['Dim swApp As Object\nDim Part As Object\nDim boolstatus As Boolean\n' ...
        'Dim longstatus As Long, longwarnings As Long\n\nSub main()\n']);
end

function addSubFuncCall(fid, q)
    fprintf(fid,'main%d\n', q);
end

function endMainFunc(fid)
    fprintf(fid,'End Sub\n\n');
end

function addCurveThroughPointsMacro(fid, xyz_coords, q)
    fprintf(fid, ['Sub main%d()\n\nSet swApp = Application.SldWorks\n\n' ...
        'Set Part = swApp.ActiveDoc\nDim COSMOSWORKSObj As Object\nDim CWAddinCallBackObj As Object\n' ...
        'Set CWAddinCallBackObj = swApp.GetAddInObject("CosmosWorks.CosmosWorks")\n' ...
        'Set COSMOSWORKSObj = CWAddinCallBackObj.COSMOSWORKS\n'], q);

    fprintf(fid,'Part.InsertCurveFileBegin\n');
    for q = 1:length(xyz_coords)-1
        fprintf(fid,'boolstatus = Part.InsertCurveFilePoint(%f, %f, %f)\n', xyz_coords(q,1), xyz_coords(q,2), xyz_coords(q,3));
    end
    fprintf(fid,'boolstatus = Part.InsertCurveFileEnd()\n');
end

function addSketchForCurve(fid,sketchNum,z_coord)
    fprintf(fid,'boolstatus = Part.SelectedFeatureProperties(0, 0, 0, 0, 0, 0, 0, 1, 0, "Curve%d")\n',sketchNum);
    fprintf(fid,'boolstatus = Part.Extension.SelectByID2("Front Plane", "PLANE", 0, 0, 0, False, 0, Nothing, 0)\n');
    fprintf(fid,['Dim myRefPlane%d As Object\n' ...
        'Set myRefPlane%d = Part.FeatureManager.InsertRefPlane(8, %f, 0, 0, 0, 0)\n' ...
        'myRefPlane%d.Select2 True, 1\n'],sketchNum,sketchNum,z_coord,sketchNum);
    fprintf(fid,'Part.SketchManager.InsertSketch True\n');
    fprintf(fid,'boolstatus = Part.Extension.SelectByID2("Curve%d", "REFERENCECURVES", 0, 0, 0, False, 0, Nothing, 0)\n',sketchNum);
    fprintf(fid,['boolstatus = Part.SketchManager.SketchUseEdge3(False, False)\n' ...
        'Part.ClearSelection2 True\n' ...
        'Part.SketchManager.InsertSketch True\n\n\n']);
end

function endSub(fid)
    fprintf(fid,['Set CWAddinCallBackObj = Nothing\n' ...
        'Set COSMOSWORKSObj = Nothing\n' ...
        'End Sub\n\n']);
end