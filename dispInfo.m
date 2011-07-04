function dispInfo(screen,text,color,fontsize,font,image)
%function dispInfo(screen,text,color,fontsize,font)
%  Displays pre-formatted text information on a PTB screen using the given
%  paramaters then waits for a keypress or mouse click to dismiss.  Intended
%  for use as a way to display instructions and other non-time-critical 
%  information within PTB experiments.
%
%  ARGUMENTS
%  screen                   PTB screen pointer to display information on
%  text                     Pre-formatted text (lines separated by \n) to
%                           display.  Text will be center-justified
%  color                    Vector containing RGB triplet of desired color
%  fontsize,font            Size (in points) and name of font of text
%  image                    Image to display below text
    
    if(~exist('color','var'))
        color = [255, 255, 255];
    end
    if(exist('fontsize','var') && ~isempty(fontsize))
        oldSize = Screen('TextSize',screen,fontsize);
    end
    if(exist('font','var') && ~isempty(fontsize))
        oldFont = Screen('TextFont',screen,font);    
    end
    
    if(exist('image','var'))
        imgData = imread(image);
        imgTex = Screen('MakeTexture',screen,imgData);
        [x,y,textBounds] = DrawFormattedText(screen,text,'center','center');
        
    else
        DrawFormattedText(screen,text,'center','center',color, [], [], [], 1.15);
    end
    Screen('Flip',screen);

    if(exist('oldSize','var'))
        Screen('TextSize',screen,oldSize);
    end
    if(exist('oldFont','var'))
        Screen('TextFont',screen,oldFont);
    end
    
    bButtonsDown = true;
    while(bButtonsDown)
        [x,y,buttons] = GetMouse;
        [keyIsDown] = KbCheck;
        if(~keyIsDown && ~any(buttons))
            bButtonsDown = false;
        else
            WaitSecs(.005);
        end
    end
    
    bContinue = true;
    while(bContinue)
        [x,y,buttons] = GetMouse;
        [keyIsDown] = KbCheck;
        if(keyIsDown || any(buttons))
            bContinue = false;
        else
            WaitSecs(.005);
        end
    end
    
    bButtonsDown = true;
    while(bButtonsDown)
        [x,y,buttons] = GetMouse;
        [keyIsDown] = KbCheck;
        if(~keyIsDown && ~any(buttons))
            bButtonsDown = false;
        else
            WaitSecs(.005);
        end
    end
end