%% app_VentPosition - PlumeTraP
% GUI to pick the esitmated vent position
% Author: Riccardo Simionato. Date: April 2024
% Structure: PlumeTraP --> app_VentPosition

classdef app_VentPosition < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure       matlab.ui.Figure
        ConfirmButton  matlab.ui.control.StateButton
        UIAxesVentPos  matlab.ui.control.UIAxes
        Label          matlab.ui.control.Label
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            outFolder_orig = evalin('base','outFolder_orig');
            imageList_orig = evalin('base','imageList_orig');
            outFolder_proc = evalin('base','outFolder_proc');
            imageList_proc = evalin('base','imageList_proc');
            mantrack = evalin('base','mantrack');

            img_end = imread(fullfile(outFolder_orig,imageList_orig(length(imageList_orig)).name));

            if mantrack == 0
                img_end_log = logical(imread(fullfile(outFolder_proc,...
                    imageList_proc(length(imageList_proc)).name)));
                [row,~] = find(img_end_log);

                imshow(img_end,'Parent',app.UIAxesVentPos);
                pixel.vent_pos_y = max(row);
                pixel.vent_pos_x = round((find(img_end_log(max(row),:),1,'last')+...
                    find(img_end_log(max(row),:),1))/2); % find vent pixel position
                VentPos = images.roi.Point(app.UIAxesVentPos,'Position',[pixel.vent_pos_x,pixel.vent_pos_y],...
                    'Color','r','LineWidth',0.5);
            elseif mantrack == 1
                [h,w,~] = size(img_end);
                imshow(img_end,'Parent',app.UIAxesVentPos);
                pixel.vent_pos_y = h/2;
                pixel.vent_pos_x = w/2;
                VentPos = images.roi.Point(app.UIAxesVentPos,'Position',[pixel.vent_pos_x,pixel.vent_pos_y],...
                    'Color','r','LineWidth',0.5);
            end

            assignin('base','VentPos',VentPos)
        end

        % Value changed function: ConfirmButton
        function ConfirmButtonValueChanged(app, event)
            VentPos = evalin('base','VentPos');
            VentPos_x = round(VentPos.Position(1));
            VentPos_y = round(VentPos.Position(2));
            assignin('base','VentPos_x',VentPos_x)
            assignin('base','VentPos_y',VentPos_y)
            delete(app)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1300 800];
            app.UIFigure.Name = 'Vent Position';

            % Create Label
            app.Label = uilabel(app.UIFigure);
            app.Label.Position = [290 716 274 22];
            app.Label.Text = 'Use zoom in (to the right) to modify it if necessary.';

            % Create UIAxesVentPos
            app.UIAxesVentPos = uiaxes(app.UIFigure);
            title(app.UIAxesVentPos, 'Pick vent position')
            app.UIAxesVentPos.LabelFontSizeMultiplier = 1;
            app.UIAxesVentPos.XColor = 'none';
            app.UIAxesVentPos.XTick = [];
            app.UIAxesVentPos.YColor = 'none';
            app.UIAxesVentPos.YTick = [];
            app.UIAxesVentPos.ZColor = 'none';
            app.UIAxesVentPos.TitleHorizontalAlignment = 'left';
            app.UIAxesVentPos.FontSize = 18;
            app.UIAxesVentPos.TitleFontSizeMultiplier = 1;
            app.UIAxesVentPos.Position = [55 27 1223 714];

            % Create ConfirmButton
            app.ConfirmButton = uibutton(app.UIFigure, 'state');
            app.ConfirmButton.ValueChangedFcn = createCallbackFcn(app, @ConfirmButtonValueChanged, true);
            app.ConfirmButton.Text = 'Confirm';
            app.ConfirmButton.BackgroundColor = [0.9412 0.9804 1];
            app.ConfirmButton.Position = [1175 9 100 23];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app_VentPosition

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end