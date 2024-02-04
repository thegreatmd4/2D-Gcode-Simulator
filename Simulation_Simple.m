clc; clear;

Width = 2500; Height = 1500;                    % Size of BB

%xy_gcode = splitlines(fileread('W_Simplified.gcode'));     % Read GCode
[filename, pathname] = uigetfile({'*.gcode'},'Select the GCODE file');
if isequal(filename,0)
   disp('User selected Cancel')
else
   disp(['User selected ', fullfile(pathname, filename)])
   xy_gcode = splitlines(fileread(fullfile(pathname, filename)));
end

if filename(1)=="R"
    color = 'r';
elseif filename(1)=="G"
    color = 'g';
else
    color = 'w';
end

if ~exist("filename","var")
    FirstRun = 1;
else
    FirstRun = 0;
end

xy_gcode = xy_gcode(17:end-2);                  % Ignore Initialization

nl = length(xy_gcode);                          % # of Commands
xy_Commands = zeros(nl,3);                      % Convert Commands
for i=1:nl
    if contains(xy_gcode(i),'X')
        xy_Commands(i,1) = uint32(str2double(extractBetween(xy_gcode(i),'X',' Y')));
    else
        xy_Commands(i,1) = NaN;
    end
    if contains(xy_gcode(i),'Y')
        xy_Commands(i,2) = uint32(str2double(extractBetween(xy_gcode(i),'Y',';')));
    else
        xy_Commands(i,2) = NaN;
    end
    if contains(xy_gcode(i),'Z')
        xy_Commands(i,3) = uint32(str2double(extractBetween(xy_gcode(i),'Z',';')));
    end
end

slsr_Commands = zeros(nl,3);                    % Calc Length of Strings
slsr_Commands(:,1) = uint32(sqrt(xy_Commands(:,1).^2+xy_Commands(:,2).^2));
slsr_Commands(:,2) = uint32(sqrt((Width-xy_Commands(:,1)).^2+xy_Commands(:,2).^2));
slsr_Commands(:,3) = xy_Commands(:,3);

if FirstRun
    figure('Name','Simulation')
end

for i=1:nl-1
    subplot(211)                                % Plot Lenght of Strings
        plot([0 xy_Commands(i,1)+1],[0 xy_Commands(i,2)+1])
        hold on                                 % Wait for other String
        xlim([0 Width]); ylim([0 Height])       % Define Size
        title('String Lengths - R⚙B⚙SKETCH')
        xlabel('Width'); ylabel('Height');
        set(gca,'YDir','reverse')               % Reverse Y Axis Direction
        sl = string(slsr_Commands(i,1));        % Len. of left  String
        sr = string(slsr_Commands(i,2));        % Len. of right String
        text(100, 100, sl);
        text(Width-250, 100, sr);
        grid minor
        plot([Width xy_Commands(i,1)+1],[0 xy_Commands(i,2)+1])
        %pbaspect([2.5 1.5 1])
        hold off                                % Go to next Step

    subplot(212)                                % Plot Drawn Results
        set(gca,'Color',[39/255,76/255,67/255]) % Blackboard Color
        line([xy_Commands(i,1)+1 xy_Commands(i+1,1)+1], ...
             [xy_Commands(i,2)+1 xy_Commands(i+1,2)+1],'Color',color)
        xlim([0 Width]); ylim([0 Height])       % Define Size
        title(['Drawn Shape: ' filename])
        xlabel('Width'); ylabel('Height')
        set(gca,'YDir','reverse')               % Reverse Y Axis Direction
        %pbaspect([2.5 1.5 1])                  % Adjust Aspect Ratio
        hold on
        grid minor
    pause(0.001)
end


