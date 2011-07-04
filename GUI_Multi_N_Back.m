function varargout = GUI_Multi_N_Back(varargin)
% GUI_MULTI_N_BACK M-file for GUI_Multi_N_Back.fig
%      GUI_MULTI_N_BACK, by itself, creates a new GUI_MULTI_N_BACK or raises the existing
%      singleton*.
%
%      H = GUI_MULTI_N_BACK returns the handle to a new GUI_MULTI_N_BACK or the handle to
%      the existing singleton*.
%
%      GUI_MULTI_N_BACK('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI_MULTI_N_BACK.M with the given input arguments.
%
%      GUI_MULTI_N_BACK('Property','Value',...) creates a new GUI_MULTI_N_BACK or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GUI_Multi_N_Back_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GUI_Multi_N_Back_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GUI_Multi_N_Back

% Last Modified by GUIDE v2.5 03-Jul-2011 12:22:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_Multi_N_Back_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_Multi_N_Back_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before GUI_Multi_N_Back is made visible.
function GUI_Multi_N_Back_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GUI_Multi_N_Back (see VARARGIN)

% Choose default command line output for GUI_Multi_N_Back
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GUI_Multi_N_Back wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GUI_Multi_N_Back_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function txtSubID_Callback(hObject, eventdata, handles)


function txtSubID_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function slideN_Callback(hObject, eventdata, handles)
    v = get(hObject,'Value');
    set(hObject,'Value',round(v));
    set(handles.txtN,'String',['n = ' num2str(round(v))]);
    guidata(hObject,handles);

function slideN_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function boxPractice_Callback(hObject, eventdata, handles)

function btnGo_Callback(hObject, eventdata, handles)
    n = get(handles.slideN,'Value');
    subID = get(handles.txtSubID,'String');
    if(get(handles.radLetters,'Value'))
        mode = 'Letters';
    elseif(get(handles.radLocations,'Value'))
        mode = 'Locations';
    else
        mode = 'Both';
    end
    if(get(handles.boxPractice,'Value'))
        practice = true;
    else
        practice = false;
    end
    
    runExperiment(subID,mode,n,practice);
    msgbox('Please inform your experimenter','Section complete');

function btnRun123_Callback(hObject, eventdata, handles)
    subID = get(handles.txtSubID,'String');
    if(get(handles.radLetters,'Value'))
        mode = 'Letters';
    elseif(get(handles.radLocations,'Value'))
        mode = 'Locations';
    else
        mode = 'Both';
    end
    
    if(get(handles.boxPractice,'Value'))
        practice = true;
    else
        practice = false;
    end
    
    for n=1:3
        runExperiment(subID,mode,n,practice);
    end
    msgbox('Please inform your experimenter','Section complete');

function btnRun321_Callback(hObject, eventdata, handles)
    subID = get(handles.txtSubID,'String');
    if(get(handles.radLetters,'Value'))
        mode = 'Letters';
    elseif(get(handles.radLocations,'Value'))
        mode = 'Locations';
    else
        mode = 'Both';
    end
    
    if(get(handles.boxPractice,'Value'))
        practice = true;
    else
        practice = false;
    end
    
    for n=[3 2 1] % Hack?
        runExperiment(subID,mode,n,practice);
    end
    msgbox('Please inform your experimenter','Section complete');

function runExperiment(subID,mode,n,practice)
    if(~practice)
        filenameBase = ['data\' subID '_' mode '_' num2str(n,'%02d')];
        filename = [filenameBase '.xls'];
        sPractice = 'yes';
    else
        filename = 'n/a';
        sPractice = 'no';
    end
    
    fprintf('Running experiment with the following parameters:\n');
    fprintf('  Participant #: %s\n', subID);
    fprintf('              n: %d\n', n);
    fprintf('           mode: %s\n', mode);
    fprintf('      practice?: %s\n', sPractice);
    fprintf('       filename: %s\n', filename);
    
    data = Multi_N_Back(subID,mode,n,practice);
    
    if(~practice)
        bTry = true;
        n = 1;
        
        while(exist(filename,'file'))
            filename = [filenameBase '_' num2str(n,'%03d') '.xls'];
            n = n + 1;
        end
            
        while(bTry)
            try
                xlswrite(filename,data);
                fprintf('Data written to %s\n', filename);
                bTry = false;
            catch ME
                filename = [filenameBase '_' num2str(n,'%03d') '.xls'];
                n = n + 1;
                fprintf('Error writing to %s:\nAttempting alternate filename %s\n', ME.message,filename);
            end
        end
    end
