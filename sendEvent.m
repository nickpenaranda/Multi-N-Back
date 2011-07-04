function sendEvent(evNum)
    global wlabEventOut;
    addr = 888;
    delay = 0.006;

    if(~exist('GetTetTime','file'))
        disp('!!WARNING!! GetTETTime not found: Eyetracking markers are NOT being recorded.');
        wlabEventOut = vertcat(wlabEventOut,[evNum GetSecs()]);
    else
        wlabEventOut = vertcat(wlabEventOut,[evNum GetSecs() GetTetTime()]);
    end

    if(~exist('lptwrite','file'))
        disp('!!WARNING!! lptwrite not found: Markers are NOT being sent to EEG.');
    else
        lptwrite(addr,evNum);
        WaitSecs(delay);
        lptwrite(addr,0);
    end
    
    %disp(['##DEBUG## sendEvent: ' num2str(evNum) ' (' num2str(evNum,'%X') ')']);
    end

    