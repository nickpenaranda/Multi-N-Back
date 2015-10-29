function data = Multi_N_Back(subID,mode,numBack,practice)
    RandStream.setGlobalStream(RandStream('mt19937ar','seed',sum(100*clock)));
    
    AssertOpenGL;
    
    if(~exist('practice','var') || isempty(practice))
        practice = false;
    end
    
    Screen('Preference', 'SkipSyncTests', 1); 
    
    D_BACKGROUND_COLOR = [128, 128, 128]; % Gray
    D_TEXT_COLOR = [255, 255, 255]; % White
    D_STIM_FONT = 'Times New Roman';
    D_STIM_FONTSIZE = 36;
    D_PROB_POSITIVE_TRIAL = 0.5;
    if(~practice)
        D_NUM_TRIALS = 100; % Total trials will be this + numBack
        D_ISI = 1.0; % Inter-stimulus interval, "blank time"
        D_STIM_TIME = 0.5; % Stimulus duration
        D_RESP_TIME = 2.0; % Response window
        % Trial duration = D_ISI + D_RESP_TIME
    else
        D_NUM_TRIALS = 10;
        D_ISI = 2.0;
        D_STIM_TIME = 1.5; 
        D_RESP_TIME = 3.0;
    end
    
    D_WINDOWED = false; % If true, will run experiment in a window
    D_DEV = false;    % If true, will bypass sync tests (bad!) and enable
                     % other silly things.
    
    D_HEADERS = {'Subject ID','Mode','Trial Number','Stimulus','Location Index', ...
        'Location X','Location Y','Trial Type','Response','Feedback','Response Time'};
    
    if(D_WINDOWED)
        D_SCREEN_NUM = 0;
        screen_rect = Screen('Rect',0);
        [mx,my] = RectCenter(screen_rect);
        D_WINDOW_WIDTH = 800;
        D_WINDOW_HEIGHT = 600;
        D_WINDOW_SIZE = [mx-D_WINDOW_WIDTH/2,my-D_WINDOW_HEIGHT/2, ...
                         mx+D_WINDOW_WIDTH/2,my+D_WINDOW_HEIGHT/2];
    else
        screens = Screen('Screens');
        D_SCREEN_NUM = max(screens);
        D_WINDOW_SIZE = []; % Full screen
    end
    
    D_VERBAL_MODE = 1;
    D_SPATIAL_MODE = 2;

    D_STIM = {'A','B','C','D','E','G','H','K','L','M','N','P', ...
              'Q','R','S','T','V','W','X','Y','Z'}; % 21 Letters
    D_STIM_TYPE = 'Letters';
    
%     D_STIM = {'Alpha','Bravo','Charlie','Delta','Echo','Golf','Hotel', ...
%         'Kilo','Lima','Mike','November','Papa','Quebec','Romeo', ...
%         'Sierra','Tango','Victor','Whiskey','X-ray','Yankee','Zulu'};
%     D_STIM_TYPE = 'Phonetic Letters';

%     D_STIM = {'CAT','PEN','CAR','DOOR','MOP','BAG','FORK', ...
%              'OPEN','HUG','TAKE','STOP','READ','LOOK','WISH', ...
%              'SOFT','RED','BIG','EASY','DRY','GOOD','NEW'}; % 21 Words:
%              7 nouns, 7 verbs, 7 adjectives
%     D_STIM_TYPE = 'Words';
    
    D_LOCATIONS = []; % Location definitions deferred until we have a PTB
                      % window
                      
    % Marker codes
    evBlockStartBase = 100;
    evBlockEndBase = 200;
        
    evLoadingStim = 10;
    evNegativeStim = 11;
    evPositiveStim = 12;
    
    evRespTimeout = 20;
    evRespNegative = 21;
    evRespPositive = 22;
    evRespInvalid = 23;

    if(~exist('subID','var'))
        subID = inputdlg('Enter subject ID','Subject Information');
        if(isempty(subID))
            disp('Aborting...');
            return;
        end
        subID = subID{1};
    end
    
    if(~exist('mode','var') || isempty(mode))
        mode = questdlg('Select a mode:', ...
            'Mode selection', D_STIM_TYPE, 'Locations', 'Both', D_STIM_TYPE);
        if(isempty(mode))
            disp('Aborting...');
            return;
        end
    end
    
    if(~exist('numBack','var') || isempty(numBack))
        numBack = 2;
        disp(['parameter ''numBack'' not specified; default to '  ...
            num2str(numBack)]);
    end
    
    if(D_DEV)
        Screen('Preference', 'SkipSyncTests',1);
    end
    
    try
        if(D_DEV)
            ListenChar(1);
        else
            ListenChar(2);
            HideCursor;
        end
        
        screens = Screen('Screens');
        [windowPtr,rect] = Screen('OpenWindow',D_SCREEN_NUM, ...
            D_BACKGROUND_COLOR, D_WINDOW_SIZE);
        [scrWidth, scrHeight] = Screen('WindowSize',windowPtr);
        
        Screen('BlendFunction',windowPtr,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
        
        Screen('TextSize',windowPtr,D_STIM_FONTSIZE);
        Screen('TextFont',windowPtr,D_STIM_FONT);
        
        % Load correct/incorrect graphics
        rCorrect = [];
        rIncorrect = [];
        try
            [rCorrect,mCorrect,aCorrect] = imread('Correct.png');
            [rIncorrect,mIncorrect,aIncorrect] = imread('Incorrect.png');
        end
        if(~isempty(rCorrect) && ~isempty(rIncorrect))
            bFeedbackGFX = true;
            tCorrect = Screen('MakeTexture',windowPtr,cat(3,rCorrect,aCorrect));
            tIncorrect = Screen('MakeTexture',windowPtr,cat(3,rIncorrect,aIncorrect));
        else
            bFeedbackGFX = false;
        end
        
        % Define locations
        [mx,my] = RectCenter(rect);
        D_LOCATIONS = round([ ... % 21 Locations; 3x7 grid
            mx/4, my/2;     mx/4, my;       mx/4, 3*my/2; ...
            mx/2, my/2;     mx/2, my;       mx/2, 3*my/2; ...
            3*mx/4, my/2;   3*mx/4, my;     3*mx/4, 3*my/2; ...
            mx, my/2;       mx, my;         mx, 3*my/2; ...
            5*mx/4, my/2;   5*mx/4, my;     5*mx/4, 3*my/2; ...
            3*mx/2, my/2;   3*mx/2, my;     3*mx/2, 3*my/2; ...
            7*mx/4, my/2;   7*mx/4, my;     7*mx/4, 3*my/2]);
        
        % Define offsets for stimuli
        D_OFFSETS = [];
        n = 1;
        for stim = D_STIM
            rect = Screen('TextBounds',windowPtr,stim{1});
            [D_OFFSETS(n,1),D_OFFSETS(n,2)] = RectCenter(rect);
            n = n + 1;
        end
        D_OFFSETS = D_OFFSETS * -1;
        
        % Instructions
        showInstructions(windowPtr);
        
        trialHist = cell(D_NUM_TRIALS + numBack,1);
        data = cell(D_NUM_TRIALS + numBack + 1,length(D_HEADERS));
        for n=1:length(D_HEADERS)
            data{1,n} = D_HEADERS{n};
        end
        
        lastStim = 0;
        switch(mode)
            case D_STIM_TYPE
                evConditionTerm = 10;
            case 'Locations'
                evConditionTerm = 20;
            case 'Both'
                evConditionTerm = 30;
        end
        
        evBlockStart = evBlockStartBase + ...
            evConditionTerm + numBack;
        
        sendEvent(evBlockStart);
        for trialNum=1:D_NUM_TRIALS + numBack
            % Populate this trial and record in history
            x = rand();
            if(trialNum <= numBack || x > D_PROB_POSITIVE_TRIAL)
                bReroll = true;
                while(bReroll)
                    trialHist{trialNum} = [ ...
                        randi(length(D_STIM)), ...
                        randi(length(D_LOCATIONS))];
                    if(trialNum <= numBack)
                        trialType = 'loading';
                        bReroll = false;
                    elseif(~isequal(mode,'Both'))
                        trialType = 'negative';
                        switch mode
                            case D_STIM_TYPE
                                if(~isequal(trialHist{trialNum}(1),trialHist{trialNum - numBack}(1)))
                                    bReroll = false;
                                end
                            case 'Locations'
                                if(~isequal(trialHist{trialNum}(2),trialHist{trialNum - numBack}(2)))
                                    bReroll = false;
                                end
                        end
                    else
                        y = rand();
                        if(y > .75) % 25% chance that dim A is random but dim B is the same
                            trialHist{trialNum} = [ ...
                                randi(length(D_STIM)), ...
                                trialHist{trialNum - numBack}(2)];
                            if(~isequal(trialHist{trialNum}(1),trialHist{trialNum - numBack}(1)))
                                bReroll = false;
                            end
                        elseif(y > .5) % 25% chance that dim B is random but dim A is the same
                            trialHist{trialNum} = [ ...
                                trialHist{trialNum - numBack}(1), ...
                                randi(length(D_LOCATIONS))];
                            if(~isequal(trialHist{trialNum}(2),trialHist{trialNum - numBack}(2)))
                                bReroll = false;
                            end
                        end
                        trialType = 'negative';
                    end
                end
            else % Positive trial
                trialHist{trialNum} = trialHist{trialNum - numBack};
                trialType = 'positive';
                switch mode
                    case D_STIM_TYPE
                        trialHist{trialNum}(2) = randi(length(D_LOCATIONS));
                    case 'Locations'
                        trialHist{trialNum}(1) = randi(length(D_STIM));
                    case 'Both'
                        % Do nothing
                    otherwise
                        exBadMode = MException( ...
                            'Multi_N_Back:badMode','Bad mode: %s',mode);
                        throw(exBadMode);
                end
            end
            
            % Render this trial
            stim = D_STIM{trialHist{trialNum}(1)};
            offset = D_OFFSETS(trialHist{trialNum}(1),:);
            location = D_LOCATIONS(trialHist{trialNum}(2),:);
            
            DrawFormattedText(windowPtr, [num2str(numBack) '-back: ' mode], ...
                'center',0,D_TEXT_COLOR);
            Screen('DrawText', windowPtr, stim, ...
                location(1) + offset(1), location(2) + offset(2), ...
                D_TEXT_COLOR);
            
            if(lastStim)
                [VBLTimestamp lastStim] = ...
                    Screen('Flip',windowPtr,lastStim + D_RESP_TIME + D_ISI);
            else % ASAP
                [VBLTimestamp lastStim] = ...
                    Screen('Flip',windowPtr);
            end
            % Send onset marker
            switch trialType
                case 'loading'
                    sendEvent(evLoadingStim);
                case 'negative'
                    sendEvent(evNegativeStim);
                case 'positive'
                    sendEvent(evPositiveStim);
            end
            
            % Repeatedly poll for input, clear screen after D_STIM_TIME
            secs = GetSecs();
            bInput = 0;
            bCleared = false;
            while(~bInput && secs < (lastStim + D_RESP_TIME))
                if(~bCleared && secs > lastStim + D_STIM_TIME)
                    DrawFormattedText(windowPtr, [num2str(numBack) '-back: ' mode], ...
                        'center',0,D_TEXT_COLOR);
                    Screen('Flip',windowPtr);
                    bCleared = true;
                end
                [bInput, secs, keyCode] = KbCheck();
                WaitSecs(.001);
            end
            
            % Interpret input
            if(bInput)
                cc = KbName(keyCode);
                if(iscell(cc))
                    cc = cc{1};
                end
                switch cc
                    case 'esc'
                        disp('Exiting...');
                        break;
                    case 'f'
                        response = 'negative';
                        sendEvent(evRespNegative);
                    case 'j'
                        response = 'positive';
                        sendEvent(evRespPositive);
                    otherwise
                        fprintf('WARNING: Bad response ''%s''\n', cc);
                        response = 'none';
                        sendEvent(evRespInvalid);
                end
            else
                response = 'none';
                sendEvent(evRespTimeout);
            end
                
            % Determine if input was correct
            if(isequal(trialType,response)) % Yes
                feedback = 'correct';
            elseif(isequal(trialType,'loading') && ...  % Loading, no feedback and
                   isequal(response,'none')) % no response
                feedback = 'none';
            else
                feedback = 'incorrect';
            end
            
            % Render feedback
            DrawFormattedText(windowPtr, [num2str(numBack) '-back: ' mode], ...
                'center',0,D_TEXT_COLOR);
            switch feedback
                case 'correct'
                    if(~practice)
                        if(~bFeedbackGFX)
                            DrawFormattedText(windowPtr,'CORRECT', ...
                                'center','center',[0, 255, 0]);
                        else
                            Screen('DrawTexture',windowPtr,tCorrect);
                        end
                    else
                        if(isequal(trialType,'positive'))
                            sFeedback = [ ...
                                'This screen was the same as the screen ' num2str(numBack) ...
                                ' screen(s) back.'];
                        else
                            sFeedback = [ ...
                                'This screen was different than the screen ' num2str(numBack) ...
                                ' screen(s) back.'];
                        end
                        if(~bFeedbackGFX)
                            DrawFormattedText(windowPtr,['CORRECT\n\n' ...
                                WrapString(sFeedback,50)],'center','center', ...
                                [0, 255, 0]);
                        else
                            Screen('DrawTexture',windowPtr,tCorrect);
                            DrawFormattedText(windowPtr,WrapString(sFeedback,50), ...
                                'center',my+150,[255, 255, 255]);
                        end
                    end
                case 'incorrect'
                    if(~practice)
                        if(~bFeedbackGFX)
                            DrawFormattedText(windowPtr,'INCORRECT', ...
                                'center','center',[255, 0, 0]);
                        else
                            Screen('DrawTexture',windowPtr,tIncorrect);
                        end
                    else
                        if(isequal(trialType,'loading'))
                            sFeedback = [ ...
                                'There was nothing to compare this screen to, ' ...
                                'so you should not have pressed either key.'];
                        elseif(isequal(trialType,'negative'))
                            sFeedback = [ ...
                                'This screen did not match the screen ' num2str(numBack) ...
                                ' screen(s) back, so you should have pressed "F"'];
                        else
                            sFeedback = [ ...
                                'This screen matched the screen ' num2str(numBack) ...
                                ' screen(s) back, so you should have pressed "J"'];
                        end
                        if(~bFeedbackGFX)
                            DrawFormattedText(windowPtr,['INCORRECT\n\n' ...
                                WrapString(sFeedback,50)],'center','center', ...
                                [255, 0, 0]);
                        else
                            Screen('DrawTexture',windowPtr,tIncorrect);
                            DrawFormattedText(windowPtr,WrapString(sFeedback,50), ...
                                'center',my+150,[255,255,255]);
                        end
                    end
            end
            Screen('Flip',windowPtr);
            
            % Record trial in data
            data{trialNum+1,1} = subID;
            data{trialNum+1,2} = mode;
            data{trialNum+1,3} = trialNum;
            data{trialNum+1,4} = stim;
            data{trialNum+1,5} = trialHist{trialNum}(2);
            data{trialNum+1,6} = location(1)/scrWidth;
            data{trialNum+1,7} = location(2)/scrHeight;
            data{trialNum+1,8} = trialType;
            data{trialNum+1,9} = response;
            data{trialNum+1,10} = feedback;
            data{trialNum+1,11} = secs - lastStim;
            
        end
        
        evBlockEnd = evBlockEndBase + ...
            evConditionTerm + numBack;
        sendEvent(evBlockEnd);
        close();
    catch ME
        close();
        rethrow(ME);
    end
        
    function close()
        ShowCursor;
        ListenChar(0);
        Screen('CloseAll');
        if(D_DEV)
            Screen('Preference','SkipSyncTests',0);
        end
    end

    function showInstructions(windowPtr)
        nStr = {'one','two','three','four','five','six','seven','eight','nine', ...
            'ten'};

        switch mode
            case D_STIM_TYPE
                sMode = ['You will be comparing the ' upper(D_STIM_TYPE) ...
                    ' themselves in this part of the study.  You should ' ...
                    'try your best to ignore the locations of the ' lower(D_STIM_TYPE) ...
                    '.'];
            case 'Locations'
                sMode = ['You will be comparing the LOCATIONS of the ' ...
                    lower(D_STIM_TYPE) ' in this part of the study.  You ' ...
                    'should try your best to ignore the ' lower(D_STIM_TYPE) ...
                    ' themselves.'];
            case 'Both'
                sMode = ['You will be comparing both the LOCATIONS and the ' ...
                    upper(D_STIM_TYPE) ' in this part of the study.  Try to ' ...
                    'pay attention to both equally.'];
        end
        switch numBack
            case 1
                sNumBack = ['You will be performing the 1-BACK.  Remember that ' ...
                    'this means you are comparing each screen to the previous ' ...
                    'screen, or "one back" from the current screen.'];
            otherwise
                sNumBack = ['You will be performing the ' num2str(numBack) '-BACK.  Remember that ' ...
                    'this means you are comparing each screen to the screen ' ...
                    '"' nStr{numBack} ' back" from the current screen.'];
        end
        
        sKeys = ['Remember: Press the "F" key when the current screen does ' ...
            'NOT match and press the "J" key when it does.  Place your left ' ...
            'and right index fingers on these keys now.'];
        
        if(practice)
            instructions = [WrapString(sMode,50) '\n\n' WrapString(sNumBack,50) '\n\n' ...
                WrapString(sKeys,50) '\n\n Press any key to continue.'];
        else
            instructions = [WrapString(sMode,50) '\n\n' WrapString(sNumBack,50) '\n\n' ...
                WrapString(sKeys,50) '\n\n Press any key to begin the experiment.'];
        end
        
        dispInfo(windowPtr,instructions,D_TEXT_COLOR,18);
        if(practice)
            pracExtra = ['Because this is practice, you will do fewer ' ...
                'screens and you will have longer to answer for each screen. ' ...
                'You will also be given a little more feedback after each screen.'];
            dispInfo(windowPtr,[WrapString(pracExtra,50) ...
                '\n\nPress any key to begin practice'],D_TEXT_COLOR,18);
        end
        Screen('Flip',windowPtr);
        WaitSecs(1);
    end
end
