clc; clear;

Width = 2500; Height = 1500;                    % Size of BB

%SlSr_gcode = splitlines(fileread('W_Converted.gcode'));     % Read GCode
[filename, pathname] = uigetfile({'*.gcode'},'Select the GCODE file');
if isequal(filename,0)
   disp('User selected Cancel')
else
   disp(['User selected ', fullfile(pathname, filename)])
   SlSr_gcode = splitlines(fileread(fullfile(pathname, filename)));
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

SlSr_gcode = SlSr_gcode(1:end-2);                  % Ignore Initialization

nl = length(SlSr_gcode);                          % # of Commands
slsr_Commands = zeros(nl,3);
for i=1:nl
    if contains(SlSr_gcode(i),'SL')
        slsr_Commands(i,1) = uint32(str2double(extractBetween(SlSr_gcode(i),'SL',' SR')));
    else
        slsr_Commands(i,1) = NaN;
    end
    if contains(SlSr_gcode(i),'SR')
        slsr_Commands(i,2) = uint32(str2double(extractBetween(SlSr_gcode(i),'SR',' Z')));
    else
        slsr_Commands(i,2) = NaN;
    end
    if contains(SlSr_gcode(i),'Z')
        slsr_Commands(i,3) = uint32(str2double(extractBetween(SlSr_gcode(i),'Z',';')));
    end
end

xy_Commands = zeros(nl,3);
xy_Commands(:,1) = ((slsr_Commands(:,1).^2-slsr_Commands(:,2).^2)/Width+Width)/2;
xy_Commands(:,2) = sqrt(slsr_Commands(:,1).^2-xy_Commands(:,1).^2);
xy_Commands(:,3) = slsr_Commands(:,3);



if FirstRun
    figure('Name','Simulation')
end

for i=1:nl-1
    subplot(211)                                % Plot Lenght of Strings
        plot([0 xy_Commands(i,1)-54+1],[0 xy_Commands(i,2)-161+1]) %SL
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
        plot([Width xy_Commands(i,1)+125+1],[0 xy_Commands(i,2)-161+1]) % SR
        %pbaspect([2.5 1.5 1])
        if ~isnan(xy_Commands(i,1))
            rectangle('Position',[xy_Commands(i,1)-54-45+1 xy_Commands(i,2)-161+1 250 200]) % Plotter
            plot([xy_Commands(i,1)+35 xy_Commands(i,1)+35],[xy_Commands(i,2)+39 Height-100])% 3rd rope
            rectangle('Position',[xy_Commands(i,1)-45+1 Height-100 150 100])                % Sliding Cart
            viscircles([xy_Commands(i,1) xy_Commands(i,2)],5,'Color',color);
            text(xy_Commands(i,1)+5,xy_Commands(i,2),{xy_Commands(i,3)})
        end
        hold off                                % Go to next Step

    subplot(212)                                % Plot Drawn Results
        set(gca,'Color',[39/255,76/255,67/255]) % Blackboard Color
        rectangle('Position',[300 260 1800 1100])   % Drawing Area
        line([xy_Commands(i,1)+1 xy_Commands(i+1,1)+1], ...
             [xy_Commands(i,2)+1 xy_Commands(i+1,2)+1],'Color',color)
        xlim([0 Width]); ylim([0 Height])       % Define Size
        title(['Drawn Shape: ' filename])
        xlabel('Width'); ylabel('Height')
        set(gca,'YDir','reverse')               % Reverse Y Axis Direction
        %pbaspect([2.5 1.5 1])                  % Adjust Aspect Ratio
        hold on
        grid minor
        pause(0.01)
end


