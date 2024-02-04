clc; clear;

Width = 1500; Height = 1500;                            % Size of Blackboard

%% Read the GCODE and Initialize the Settings
%xy_gcode = splitlines(fileread('W_Chalk.gcode'));      % Read GCode
[filename, pathname] = uigetfile({'*.gcode'},'Select the GCODE file');
if isequal(filename,0)
   disp('User selected Cancel')
else
   disp(['User selected ', fullfile(pathname, filename)])
   xy_gcode = splitlines(fileread(fullfile(pathname, filename)));
end

if filename(1)=="R"                                     % Assign color to chalk
    color = 'r';
elseif filename(1)=="G"
    color = 'g';
else
    color = 'w';
end

if ~exist("filename","var")                             % Check if it's first time
    FirstRun = 1;                                       % Open new figure
else
    FirstRun = 0;                                       % Draw on existing figure
end

%% Process GCODE and convert to Commands
xy_gcode = xy_gcode(1:end-2);                           % Ignore Initialization lines in gcode

nl = length(xy_gcode);                                  % # of Lines
xy_Commands = zeros(nl,3);                              % Convert gcode to Commands
for i=1:nl
    if contains(xy_gcode(i),'X')
        xy_Commands(i,1) = uint32(str2double(extractBetween(xy_gcode(i),'X',' Y')));
    else
        xy_Commands(i,1) = NaN;
    end
    if contains(xy_gcode(i),'Y')
        xy_Commands(i,2) = uint32(str2double(extractBetween(xy_gcode(i),'Y',' Z')));
    else
        xy_Commands(i,2) = NaN;
    end
    if contains(xy_gcode(i),'Z')
        xy_Commands(i,3) = uint32(str2double(extractBetween(xy_gcode(i),'Z',';')));
    end
end

%% Convert (x,y) Coord.Sys. to (Sl,Sr) Coord.Sys.
SlSr_Commands = zeros(nl,3);                            % Calc Length of Strings
Sl_Offset = [-125.50 -160.93];                          % Place of attach of left  rope
Sr_Offset = [  54.50 -160.93];                          % Place of attach of right rope

for i=1:nl
    EndEffPos = xy_Commands(i,1:2);                     % EndEffector Position (x,y)
    Pos_Sl = EndEffPos + Sl_Offset;                     % Left Rope Effect Pos.(x,y)
    Pos_Sr = EndEffPos + Sr_Offset;                     % Righ Rope Effect Pos.(x,y)
    z = xy_Commands(i,3);                               % Chlk Pos. (z)
    SlLen = sqrt(Pos_Sl(1)^2+Pos_Sl(2)^2);              % Len. of Rope Left
    SrLen = sqrt((Width-Pos_Sr(1))^2+Pos_Sr(2)^2);      % Len. of Rope Right
    SlSr_Commands(i,:) = [SlLen SrLen z];               % Augment Len. in (sl,sr) coor.sys.
end

%% Calc. The Speeds

Speeds = zeros(nl,2);                                   % Vector for Speeds
maxSpeed = 2000;                                        % Max Allowed Speed
for i=1:nl-1
    sl = SlSr_Commands(i+1,1);                          % Current length of left rope
    sr = SlSr_Commands(i+1,2);                          % Current length of right rope
    sl_last = SlSr_Commands(i,1);                       % Prevoius length of left rope
    sr_last = SlSr_Commands(i,2);                       % Prevoius length of right rope
    delta_L = sl-sl_last;                               % Change of left rope
    delta_R = sr-sr_last;                               % Change of right rope

    if abs(delta_L)>abs(delta_R)                        % If left moves more, 
        Speeds(i,1) = maxSpeed;                         % high speed left
        Speeds(i,2) = abs(delta_R/delta_L)*maxSpeed;    % low speed right

    else                                                % If right moves more,
        Speeds(i,2) = maxSpeed;                         % high speed right
        Speeds(i,1) = abs(delta_L/delta_R)*maxSpeed;    % low speed left
    end
end

%% Graphical Simulation
if FirstRun                                                     % Open new figure or draw on exist.
    figure('Name','Simulation')
end

for i=1:nl-1
    %% Show the current pose of the plotter
    subplot(211)                                                % Plot Lenght of Strings
        plot([0 xy_Commands(i,1)+Sl_Offset(1)],[0 xy_Commands(i,2)+Sl_Offset(2)])         % SL
        hold on                                                 % Wait for other String
        xlim([0 Width]); ylim([0 Height])                       % Define Size
        title('String Lengths - R⚙B⚙SKETCH')
        xlabel('Width'); ylabel('Height');
        set(gca,'YDir','reverse')                               % Reverse Y Axis Direction                      
        text(100, 100, string(SlSr_Commands(i,1)));             % Len. of left  String
        text(Width-250, 100, string(SlSr_Commands(i,2)));       % Len. of right String
        text(100, 250, string(Speeds(i,1)));                    % Spd. of left  String
        text(Width-250, 250, string(Speeds(i,2)));              % Spd. of right String
        grid minor
        plot([Width xy_Commands(i,1)+Sr_Offset(1)],[0 xy_Commands(i,2)+Sr_Offset(2)])     % SR
        %pbaspect([2.5 1.5 1])
        if ~isnan(xy_Commands(i,1))
            rectangle('Position',[xy_Commands(i,1)+Sl_Offset(1)-35.5 xy_Commands(i,2)+Sl_Offset(2) 250 200])    % Plotter
            plot([xy_Commands(i,1)-35.5 xy_Commands(i,1)-35.5],[xy_Commands(i,2)+39 Height-100])                % 3rd rope
            rectangle('Position',[xy_Commands(i,1)-75-35.5 Height-100 150 100])                                 % Sliding Cart
            viscircles([xy_Commands(i,1) xy_Commands(i,2)],5,'Color',color);
            text(xy_Commands(i,1)+5,xy_Commands(i,2),{xy_Commands(i,3)})
        end
        hold off                                                % Go to next Step

    %% Draw on the board
    subplot(212)                                                % Plot Drawn Results
        set(gca,'Color',[39/255,76/255,67/255])                 % Blackboard Color
        line([xy_Commands(i,1)+1 xy_Commands(i+1,1)+1], ...
             [xy_Commands(i,2)+1 xy_Commands(i+1,2)+1],'Color',color)
        xlim([0 Width]); ylim([0 Height])                       % Define Size
        title(['Drawn Shape: ' filename])
        xlabel('Width'); ylabel('Height')
        set(gca,'YDir','reverse')                               % Reverse Y Axis Direction
        %pbaspect([2.5 1.5 1])                                  % Adjust Aspect Ratio
        hold on
        grid minor
    pause(0.01)
end




