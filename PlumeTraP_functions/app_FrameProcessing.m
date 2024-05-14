%% app_FrameProcessing - PlumeTraP
% GUI to choose the thresholds and processing parameters for binarization
% Author: Riccardo Simionato. Date: May 2024
% Structure: PlumeTraP --> app_FrameProcessing

classdef app_FrameProcessing < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        TabGroup                     matlab.ui.container.TabGroup
        ROIselectionTab              matlab.ui.container.Tab
        NextButton                   matlab.ui.control.StateButton
        Label                        matlab.ui.control.Label
        UIAxesROI                    matlab.ui.control.UIAxes
        ImageprocessingthresholdTab  matlab.ui.container.Tab
        frameSpinner                  matlab.ui.control.Spinner
        infoLabel3                    matlab.ui.control.Label
        infoLabel2                    matlab.ui.control.Label
        infoLabel1                    matlab.ui.control.Label
        rgbuseLegendLabel             matlab.ui.control.Label
        brAllLabel                    matlab.ui.control.Label
        bAllLabel                     matlab.ui.control.Label
        rgbuseAllSwitch               matlab.ui.control.Switch
        brBkgLabel                    matlab.ui.control.Label
        bBkgLabel                     matlab.ui.control.Label
        rgbuseBkgSwitch               matlab.ui.control.Switch
        DonotsubtractbackgroundCheckBox  matlab.ui.control.CheckBox
        SwitchtomanualtrackingButton  matlab.ui.control.StateButton
        SelectthresholdsforimageprocessingLabel  matlab.ui.control.Label
        ThBackSlider                 matlab.ui.control.Slider
        Thresholdluminancevaluebackgroundonly100Label  matlab.ui.control.Label
        ThAllSlider                  matlab.ui.control.Slider
        Thresholdluminancevalue100Label  matlab.ui.control.Label
        RunButton                    matlab.ui.control.StateButton
        BackButton                   matlab.ui.control.StateButton
        UIAxes6                      matlab.ui.control.UIAxes
        UIAxes5                      matlab.ui.control.UIAxes
        UIAxes4                      matlab.ui.control.UIAxes
        UIAxes3                      matlab.ui.control.UIAxes
        UIAxes2                      matlab.ui.control.UIAxes
        UIAxes1                      matlab.ui.control.UIAxes
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            outFolder_orig = evalin('base','outFolder_orig');
            imageList_orig = evalin('base','imageList_orig');
            app.frameSpinner.Limits = [1 length(imageList_orig)];

            img_start = imread(fullfile(outFolder_orig,imageList_orig(1).name));
            [r,~,b] = imsplit(img_start);
            if mean2(b-r) > 5
                app.rgbuseAllSwitch.Value = "br";
                app.rgbuseBkgSwitch.Value = "br";
                app.ThAllSlider.Value = 10;
                app.ThBackSlider.Value = 10;
            else
                app.rgbuseAllSwitch.Value = "b";
                app.rgbuseBkgSwitch.Value = "b";
                app.ThAllSlider.Value = 60;
                app.ThBackSlider.Value = 60;
            end
            th_all = app.ThAllSlider.Value/100;
            th_first = app.ThBackSlider.Value/100;

            i = length(imageList_orig);
            if length(imageList_orig) == 1
                img_precEnd = img_start;
            else
                img_precEnd = imread(fullfile(outFolder_orig,imageList_orig(i-1).name));
            end
            img_end = imread(fullfile(outFolder_orig,imageList_orig(length(imageList_orig)).name));
            [img_height,img_width,~] = size(img_end);
            mask = ones(img_height,img_width);
            [~,~,~,~,img_end_plume_holes] = ...
                image_analysis_app(img_end,img_start,img_precEnd,i,mask,...
                th_first,th_all,app.DonotsubtractbackgroundCheckBox.Value,...
                app.rgbuseBkgSwitch.Value,app.rgbuseAllSwitch.Value);
            [row,col] = find(img_end_plume_holes);

            imshow(img_end,'Parent',app.UIAxesROI);
            if isempty(row) || isempty(col)
                ROI = images.roi.Rectangle(app.UIAxesROI,'Position',[1,1,...
                    img_width,img_height],'Color','r','LineWidth',...
                    0.5,'FaceAlpha',0);
            else
                ROI = images.roi.Rectangle(app.UIAxesROI,'Position',[min(col),min(row),...
                    max(col)-min(col),max(row)-min(row)],'Color','r','LineWidth',...
                    0.5,'FaceAlpha',0);
            end

            assignin('base','ROI',ROI)
            assignin('base','rgbuse_all',app.rgbuseAllSwitch.Value)
            assignin('base','rgbuse_bkg',app.rgbuseBkgSwitch.Value)
        end

        % Value changed function: NextButton
        function NextButtonValueChanged(app, event)
            ROI = evalin('base','ROI');
            outFolder_orig = evalin('base','outFolder_orig');
            imageList_orig = evalin('base','imageList_orig');

            img_start = imread(fullfile(outFolder_orig,imageList_orig(1).name));
            [img_height,img_width,~] = size(img_start);
            mask = createMask(ROI,img_height,img_width);
            assignin('base','mask',mask)

            app.TabGroup.SelectedTab = app.ImageprocessingthresholdTab;

            th_all = app.ThAllSlider.Value/100;
            th_first = app.ThBackSlider.Value/100;
            nousebkgr = app.DonotsubtractbackgroundCheckBox.Value; 
            rgbuse_all =  app.rgbuseAllSwitch.Value;
            rgbuse_bkg = app.rgbuseBkgSwitch.Value;

            i = length(imageList_orig);
            if length(imageList_orig) == 1
                img_precEnd = img_start;
            else
                img_precEnd = imread(fullfile(outFolder_orig,imageList_orig(i-1).name));
            end
            img_end = imread(fullfile(outFolder_orig,imageList_orig(length(imageList_orig)).name));
            [img_start_bin,~,~,~,img_end_plume_holes] = ...
                image_analysis_app(img_end,img_start,img_precEnd,i,mask,th_first,th_all,nousebkgr,rgbuse_bkg,rgbuse_all);
            img2 = imread(fullfile(outFolder_orig,imageList_orig(app.frameSpinner.Value).name));
            [~,~,~,~,img2_plume_holes] = image_analysis_app(img2,...
                img_start,img_start,app.frameSpinner.Value,mask,th_first,th_all,nousebkgr,rgbuse_bkg,rgbuse_all);
            imshow(img_end_plume_holes,'Parent',app.UIAxes6);
            imshow(img_end,'Parent',app.UIAxes3);
            imshow(img2_plume_holes,'Parent',app.UIAxes5);
            imshow(img2,'Parent',app.UIAxes2);
            imshow(img_start_bin,'Parent',app.UIAxes4);
            imshow(img_start,'Parent',app.UIAxes1);

            assignin('base','th_all',th_all)
            assignin('base','th_first',th_first)
        end

        % Selection change function: TabGroup
        function TabGroupSelectionChanged(app, event)
            if app.TabGroup.SelectedTab == app.ImageprocessingthresholdTab
                ROI = evalin('base','ROI');
                outFolder_orig = evalin('base','outFolder_orig');
                imageList_orig = evalin('base','imageList_orig');

                img_start = imread(fullfile(outFolder_orig,imageList_orig(1).name));
                [img_height,img_width,~] = size(img_start);
                mask = createMask(ROI,img_height,img_width);
                assignin('base','mask',mask)

                th_all = app.ThAllSlider.Value/100;
                th_first = app.ThBackSlider.Value/100;
                nousebkgr = app.DonotsubtractbackgroundCheckBox.Value; 
                rgbuse_all =  app.rgbuseAllSwitch.Value;
                rgbuse_bkg = app.rgbuseBkgSwitch.Value;

                i = length(imageList_orig);
                if length(imageList_orig) == 1
                    img_precEnd = img_start;
                else
                    img_precEnd = imread(fullfile(outFolder_orig,imageList_orig(i-1).name));
                end 
                img_end = imread(fullfile(outFolder_orig,imageList_orig(length(imageList_orig)).name)); 
                [img_start_bin,~,~,~,img_end_plume_holes] = ...
                    image_analysis_app(img_end,img_start,img_precEnd,i,mask,th_first,th_all,nousebkgr,rgbuse_bkg,rgbuse_all);
                img2 = imread(fullfile(outFolder_orig,imageList_orig(app.frameSpinner.Value).name));
                [~,~,~,~,img2_plume_holes] = image_analysis_app(img2,...
                    img_start,img_start,app.frameSpinner.Value,mask,th_first,th_all,nousebkgr,rgbuse_bkg,rgbuse_all);
                imshow(img_end_plume_holes,'Parent',app.UIAxes6);
                imshow(img_end,'Parent',app.UIAxes3);
                imshow(img2_plume_holes,'Parent',app.UIAxes5);
                imshow(img2,'Parent',app.UIAxes2);
                imshow(img_start_bin,'Parent',app.UIAxes4);
                imshow(img_start,'Parent',app.UIAxes1);

                assignin('base','th_all',th_all)
                assignin('base','th_first',th_first)
            end
        end

        % Value changed function: ThAllSlider
        function ThAllSliderValueChanged(app, event)
            [~, minIdx] = min(abs(app.ThAllSlider.Value - event.Source.MinorTicks(:)));
            event.Source.Value = event.Source.MinorTicks(minIdx);
            app.ThAllSlider.Value = event.Source.MinorTicks(minIdx);

            th_all = app.ThAllSlider.Value/100;
            th_first = app.ThBackSlider.Value/100;
            nousebkgr = app.DonotsubtractbackgroundCheckBox.Value; 
            rgbuse_all =  app.rgbuseAllSwitch.Value;
            rgbuse_bkg = app.rgbuseBkgSwitch.Value;

            outFolder_orig = evalin('base','outFolder_orig');
            imageList_orig = evalin('base','imageList_orig');
            mask = evalin('base','mask');
            i = length(imageList_orig);
            img_start = imread(fullfile(outFolder_orig,imageList_orig(1).name));
            if length(imageList_orig) == 1
                img_precEnd = img_start;
            else
                img_precEnd = imread(fullfile(outFolder_orig,imageList_orig(i-1).name));
            end
            img_end = imread(fullfile(outFolder_orig,imageList_orig(length(imageList_orig)).name));
            [img_start_bin,~,~,~,img_end_plume_holes] = ...
                image_analysis_app(img_end,img_start,img_precEnd,i,mask,th_first,th_all,nousebkgr,rgbuse_bkg,rgbuse_all);
            img2 = imread(fullfile(outFolder_orig,imageList_orig(app.frameSpinner.Value).name));
            [~,~,~,~,img2_plume_holes] = image_analysis_app(img2,...
                img_start,img_start,app.frameSpinner.Value,mask,th_first,th_all,nousebkgr,rgbuse_bkg,rgbuse_all);
            imshow(img_end_plume_holes,'Parent',app.UIAxes6);
            imshow(img_end,'Parent',app.UIAxes3);
            imshow(img2_plume_holes,'Parent',app.UIAxes5);
            imshow(img2,'Parent',app.UIAxes2);
            imshow(img_start_bin,'Parent',app.UIAxes4);
            imshow(img_start,'Parent',app.UIAxes1);

            assignin('base','th_all',th_all)
            assignin('base','th_first',th_first)
        end

        % Value changed function: ThBackSlider
        function ThBackSliderValueChanged(app, event)
            [~, minIdx] = min(abs(app.ThBackSlider.Value - event.Source.MinorTicks(:)));
            event.Source.Value = event.Source.MinorTicks(minIdx);
            app.ThBackSlider.Value = event.Source.MinorTicks(minIdx);

            th_all = app.ThAllSlider.Value/100;
            th_first = app.ThBackSlider.Value/100;
            nousebkgr = app.DonotsubtractbackgroundCheckBox.Value; 
            rgbuse_all =  app.rgbuseAllSwitch.Value;
            rgbuse_bkg = app.rgbuseBkgSwitch.Value;

            outFolder_orig = evalin('base','outFolder_orig');
            imageList_orig = evalin('base','imageList_orig');
            mask = evalin('base','mask');
            i = length(imageList_orig);
            img_start = imread(fullfile(outFolder_orig,imageList_orig(1).name));
            if length(imageList_orig) == 1
                img_precEnd = img_start;
            else
                img_precEnd = imread(fullfile(outFolder_orig,imageList_orig(i-1).name));
            end
            img_end = imread(fullfile(outFolder_orig,imageList_orig(length(imageList_orig)).name));
            [img_start_bin,~,~,~,img_end_plume_holes] = ...
                image_analysis_app(img_end,img_start,img_precEnd,i,mask,th_first,th_all,nousebkgr,rgbuse_bkg,rgbuse_all);
            img2 = imread(fullfile(outFolder_orig,imageList_orig(app.frameSpinner.Value).name));
            [~,~,~,~,img2_plume_holes] = image_analysis_app(img2,...
                img_start,img_start,app.frameSpinner.Value,mask,th_first,th_all,nousebkgr,rgbuse_bkg,rgbuse_all);
            imshow(img_end_plume_holes,'Parent',app.UIAxes6);
            imshow(img_end,'Parent',app.UIAxes3);
            imshow(img2_plume_holes,'Parent',app.UIAxes5);
            imshow(img2,'Parent',app.UIAxes2);
            imshow(img_start_bin,'Parent',app.UIAxes4);
            imshow(img_start,'Parent',app.UIAxes1);

            assignin('base','th_all',th_all)
            assignin('base','th_first',th_first)
        end

        % Value changed function: DonotsubtractbackgroundCheckBox
        function DonotsubtractbackgroundCheckBoxValueChanged(app, event)
            if app.DonotsubtractbackgroundCheckBox.Value == 1
                app.ThBackSlider.Enable = "off";
                app.Thresholdluminancevaluebackgroundonly100Label.Enable = "off";
                app.bBkgLabel.Enable = "off";
                app.brBkgLabel.Enable = "off";
                app.rgbuseBkgSwitch.Enable = "off";
            elseif app.DonotsubtractbackgroundCheckBox.Value == 0
                app.ThBackSlider.Enable = "on";
                app.Thresholdluminancevaluebackgroundonly100Label.Enable = "on";
                app.bBkgLabel.Enable = "on";
                app.brBkgLabel.Enable = "on";
                app.rgbuseBkgSwitch.Enable = "on";
            end

            th_all = app.ThAllSlider.Value/100;
            th_first = app.ThBackSlider.Value/100;
            nousebkgr = app.DonotsubtractbackgroundCheckBox.Value; 
            rgbuse_all =  app.rgbuseAllSwitch.Value;             rgbuse_bkg = app.rgbuseBkgSwitch.Value;

            outFolder_orig = evalin('base','outFolder_orig');
            imageList_orig = evalin('base','imageList_orig');
            mask = evalin('base','mask');
            i = length(imageList_orig);
            img_start = imread(fullfile(outFolder_orig,imageList_orig(1).name));
            if length(imageList_orig) == 1
                img_precEnd = img_start;
            else
                img_precEnd = imread(fullfile(outFolder_orig,imageList_orig(i-1).name));
            end
            img_end = imread(fullfile(outFolder_orig,imageList_orig(length(imageList_orig)).name));
            [img_start_bin,~,~,~,img_end_plume_holes] = ...
                image_analysis_app(img_end,img_start,img_precEnd,i,mask,th_first,th_all,nousebkgr,rgbuse_bkg,rgbuse_all);
            img2 = imread(fullfile(outFolder_orig,imageList_orig(app.frameSpinner.Value).name));
            [~,~,~,~,img2_plume_holes] = image_analysis_app(img2,...
                img_start,img_start,app.frameSpinner.Value,mask,th_first,th_all,nousebkgr,rgbuse_bkg,rgbuse_all);
            imshow(img_end_plume_holes,'Parent',app.UIAxes6);
            imshow(img_end,'Parent',app.UIAxes3);
            imshow(img2_plume_holes,'Parent',app.UIAxes5);
            imshow(img2,'Parent',app.UIAxes2);
            imshow(img_start_bin,'Parent',app.UIAxes4);
            imshow(img_start,'Parent',app.UIAxes1);

            assignin('base','nousebkgr',app.DonotsubtractbackgroundCheckBox.Value)
        end

        % Value changed function: rgbuseAllSwitch
        function rgbuseAllSwitchValueChanged(app, event)
            if app.rgbuseAllSwitch.Value == "br"
                app.ThAllSlider.Value = 10;
            elseif app.rgbuseAllSwitch.Value == "b"
                app.ThAllSlider.Value = 60;
            end

            th_all = app.ThAllSlider.Value/100;
            th_first = app.ThBackSlider.Value/100;
            nousebkgr = app.DonotsubtractbackgroundCheckBox.Value;
            rgbuse_all =  app.rgbuseAllSwitch.Value;
            rgbuse_bkg = app.rgbuseBkgSwitch.Value;

            outFolder_orig = evalin('base','outFolder_orig');
            imageList_orig = evalin('base','imageList_orig');
            mask = evalin('base','mask');
            i = length(imageList_orig);
            img_start = imread(fullfile(outFolder_orig,imageList_orig(1).name));
            if length(imageList_orig) == 1
                img_precEnd = img_start;
            else
                img_precEnd = imread(fullfile(outFolder_orig,imageList_orig(i-1).name));
            end
            img_end = imread(fullfile(outFolder_orig,imageList_orig(length(imageList_orig)).name));
            [img_start_bin,~,~,~,img_end_plume_holes] = ...
                image_analysis_app(img_end,img_start,img_precEnd,i,mask,th_first,th_all,nousebkgr,rgbuse_bkg,rgbuse_all);
            img2 = imread(fullfile(outFolder_orig,imageList_orig(app.frameSpinner.Value).name));
            [~,~,~,~,img2_plume_holes] = image_analysis_app(img2,...
                img_start,img_start,app.frameSpinner.Value,mask,th_first,th_all,nousebkgr,rgbuse_bkg,rgbuse_all);
            imshow(img_end_plume_holes,'Parent',app.UIAxes6);
            imshow(img_end,'Parent',app.UIAxes3);
            imshow(img2_plume_holes,'Parent',app.UIAxes5);
            imshow(img2,'Parent',app.UIAxes2);
            imshow(img_start_bin,'Parent',app.UIAxes4);
            imshow(img_start,'Parent',app.UIAxes1);

            assignin('base','rgbuse_all',app.rgbuseAllSwitch.Value)
        end

        % Value changed function: rgbuseBkgSwitch
        function rgbuseBkgSwitchValueChanged(app, event)
            if app.rgbuseBkgSwitch.Value == "br"
                app.ThBackSlider.Value = 10;
            elseif app.rgbuseBkgSwitch.Value == "b"
                app.ThBackSlider.Value = 60;
            end

            th_all = app.ThAllSlider.Value/100;
            th_first = app.ThBackSlider.Value/100;
            nousebkgr = app.DonotsubtractbackgroundCheckBox.Value;
            rgbuse_all =  app.rgbuseAllSwitch.Value;
            rgbuse_bkg = app.rgbuseBkgSwitch.Value;

            outFolder_orig = evalin('base','outFolder_orig');
            imageList_orig = evalin('base','imageList_orig');
            mask = evalin('base','mask');
            i = length(imageList_orig);
            img_start = imread(fullfile(outFolder_orig,imageList_orig(1).name));
            if length(imageList_orig) == 1
                img_precEnd = img_start;
            else
                img_precEnd = imread(fullfile(outFolder_orig,imageList_orig(i-1).name));
            end
            img_end = imread(fullfile(outFolder_orig,imageList_orig(length(imageList_orig)).name));
            [img_start_bin,~,~,~,img_end_plume_holes] = ...
                image_analysis_app(img_end,img_start,img_precEnd,i,mask,th_first,th_all,nousebkgr,rgbuse_bkg,rgbuse_all);
            img2 = imread(fullfile(outFolder_orig,imageList_orig(app.frameSpinner.Value).name));
            [~,~,~,~,img2_plume_holes] = image_analysis_app(img2,...
                img_start,img_start,app.frameSpinner.Value,mask,th_first,th_all,nousebkgr,rgbuse_bkg,rgbuse_all);
            imshow(img_end_plume_holes,'Parent',app.UIAxes6);
            imshow(img_end,'Parent',app.UIAxes3);
            imshow(img2_plume_holes,'Parent',app.UIAxes5);
            imshow(img2,'Parent',app.UIAxes2);
            imshow(img_start_bin,'Parent',app.UIAxes4);
            imshow(img_start,'Parent',app.UIAxes1);

            assignin('base','rgbuse_bkg',app.rgbuseBkgSwitch.Value)
        end
        
        % Value changed function: frameSpinner
        function frameSpinnerValueChanged(app, event) %% TODO
            th_all = app.ThAllSlider.Value/100;
            th_first = app.ThBackSlider.Value/100;
            nousebkgr = app.DonotsubtractbackgroundCheckBox.Value;
            rgbuse_all =  app.rgbuseAllSwitch.Value;
            rgbuse_bkg = app.rgbuseBkgSwitch.Value;

            outFolder_orig = evalin('base','outFolder_orig');
            imageList_orig = evalin('base','imageList_orig');
            mask = evalin('base','mask');
            img_start = imread(fullfile(outFolder_orig,imageList_orig(1).name));
            if app.frameSpinner.Value > 1
                img_prec2 = imread(fullfile(outFolder_orig,imageList_orig(app.frameSpinner.Value-1).name));
            else
                img_prec2 = imread(fullfile(outFolder_orig,imageList_orig(app.frameSpinner.Value).name));
            end
            img2 = imread(fullfile(outFolder_orig,imageList_orig(app.frameSpinner.Value).name));
            [~,~,~,~,img2_plume_holes] = image_analysis_app(img2,...
                img_start,img_prec2,app.frameSpinner.Value,mask,th_first,th_all,nousebkgr,rgbuse_bkg,rgbuse_all);
            imshow(img2_plume_holes,'Parent',app.UIAxes5);
            imshow(img2,'Parent',app.UIAxes2);
        end

        % Value changed function: BackButton
        function BackButtonValueChanged(app, event)
            app.TabGroup.SelectedTab = app.ROIselectionTab;
        end

        % Value changed function: RunButton
        function RunButtonValueChanged(app, event)
            ROI = evalin('base','ROI');
            roiPos(1) = round(ROI.Position(1));
            roiPos(2) = round(ROI.Position(2));
            roiPos(3) = round(ROI.Position(3));
            roiPos(4) = round(ROI.Position(4));
            assignin('base','roiPos',roiPos)
            assignin('base','saveprocessedframes',true)
            assignin('base','nousebkgr',app.DonotsubtractbackgroundCheckBox.Value)
            assignin('base','rgbuse_all',app.rgbuseAllSwitch.Value)
            assignin('base','rgbuse_bkg',app.rgbuseBkgSwitch.Value)
            assignin('base','mantrack',false)
            delete(app)
        end

        % Value changed function: SwitchtomanualtrackingButton
        function SwitchtomanualtrackingButtonValueChanged(app, event)
            ROI = evalin('base','ROI');
            roiPos(1) = round(ROI.Position(1));
            roiPos(2) = round(ROI.Position(2));
            roiPos(3) = round(ROI.Position(3));
            roiPos(4) = round(ROI.Position(4));
            assignin('base','roiPos',roiPos)
            assignin('base','mantrack',true)
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
            app.UIFigure.Name = 'Image Processing';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.SelectionChangedFcn = createCallbackFcn(app, @TabGroupSelectionChanged, true);
            app.TabGroup.Position = [1 1 1300 800];

            % Create ROIselectionTab
            app.ROIselectionTab = uitab(app.TabGroup);
            app.ROIselectionTab.Title = 'ROI selection';

            % Create UIAxesROI
            app.UIAxesROI = uiaxes(app.ROIselectionTab);
            title(app.UIAxesROI, 'Select a region of interest (ROI) rectangle')
            app.UIAxesROI.LabelFontSizeMultiplier = 1;
            app.UIAxesROI.XColor = 'none';
            app.UIAxesROI.XTick = [];
            app.UIAxesROI.YColor = 'none';
            app.UIAxesROI.YTick = [];
            app.UIAxesROI.ZColor = 'none';
            app.UIAxesROI.TitleHorizontalAlignment = 'left';
            app.UIAxesROI.FontSize = 18;
            app.UIAxesROI.TitleFontSizeMultiplier = 1;
            app.UIAxesROI.Position = [57 11 1223 714];

            % Create Label
            app.Label = uilabel(app.ROIselectionTab);
            app.Label.Position = [502 700 627 22];
            app.Label.Text = 'The rectangle should be tangent to the plume borders as much as possible. Use zoom in (to the right) if necessary.';

            % Create NextButton
            app.NextButton = uibutton(app.ROIselectionTab, 'state');
            app.NextButton.ValueChangedFcn = createCallbackFcn(app, @NextButtonValueChanged, true);
            app.NextButton.Text = 'Next';
            app.NextButton.Position = [1175 9 100 23];

            % Create ImageprocessingthresholdTab
            app.ImageprocessingthresholdTab = uitab(app.TabGroup);
            app.ImageprocessingthresholdTab.Title = 'Image processing threshold';

            % Create UIAxes1
            app.UIAxes1 = uiaxes(app.ImageprocessingthresholdTab);
            axtoolbar(app.UIAxes1,{});
            title(app.UIAxes1, 'First frame - Background')
            xlabel(app.UIAxes1, 'X')
            ylabel(app.UIAxes1, 'Y')
            zlabel(app.UIAxes1, 'Z')
            app.UIAxes1.XColor = 'none';
            app.UIAxes1.YColor = 'none';
            app.UIAxes1.ZColor = 'none';
            app.UIAxes1.GridColor = 'none';
            app.UIAxes1.Position = [1 285 430 266];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.ImageprocessingthresholdTab);
            axtoolbar(app.UIAxes2,{}); 
            title(app.UIAxes2, 'Frame')
            xlabel(app.UIAxes2, 'X')
            ylabel(app.UIAxes2, 'Y')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.XColor = 'none';
            app.UIAxes2.YColor = 'none';
            app.UIAxes2.ZColor = 'none';
            app.UIAxes2.Position = [425 285 430 266];

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.ImageprocessingthresholdTab);
            axtoolbar(app.UIAxes3,{});
            title(app.UIAxes3, 'Last frame')
            xlabel(app.UIAxes3, 'X')
            ylabel(app.UIAxes3, 'Y')
            zlabel(app.UIAxes3, 'Z')
            app.UIAxes3.XColor = 'none';
            app.UIAxes3.YColor = 'none';
            app.UIAxes3.ZColor = 'none';
            app.UIAxes3.Position = [850 285 430 266];

            % Create UIAxes4
            app.UIAxes4 = uiaxes(app.ImageprocessingthresholdTab);
            axtoolbar(app.UIAxes4,{});
            title(app.UIAxes4, 'Background Binarization')
            xlabel(app.UIAxes4, 'X')
            ylabel(app.UIAxes4, 'Y')
            zlabel(app.UIAxes4, 'Z')
            app.UIAxes4.XColor = 'none';
            app.UIAxes4.YColor = 'none';
            app.UIAxes4.ZColor = 'none';
            app.UIAxes4.Position = [1 48 430 266];

            % Create UIAxes5
            app.UIAxes5 = uiaxes(app.ImageprocessingthresholdTab);
            axtoolbar(app.UIAxes5,{});
            title(app.UIAxes5, 'Binarization')
            xlabel(app.UIAxes5, 'X')
            ylabel(app.UIAxes5, 'Y')
            zlabel(app.UIAxes5, 'Z')
            app.UIAxes5.XColor = 'none';
            app.UIAxes5.YColor = 'none';
            app.UIAxes5.ZColor = 'none';
            app.UIAxes5.Position = [425 48 430 266];

            % Create UIAxes6
            app.UIAxes6 = uiaxes(app.ImageprocessingthresholdTab);
            axtoolbar(app.UIAxes6,{});
            title(app.UIAxes6, 'Binarization')
            xlabel(app.UIAxes6, 'X')
            ylabel(app.UIAxes6, 'Y')
            zlabel(app.UIAxes6, 'Z')
            app.UIAxes6.XColor = 'none';
            app.UIAxes6.YColor = 'none';
            app.UIAxes6.ZColor = 'none';
            app.UIAxes6.Position = [850 48 430 266];

            % Create BackButton
            app.BackButton = uibutton(app.ImageprocessingthresholdTab, 'state');
            app.BackButton.ValueChangedFcn = createCallbackFcn(app, @BackButtonValueChanged, true);
            app.BackButton.Text = 'Back';
            app.BackButton.Position = [1068 9 100 23];

            % Create RunButton
            app.RunButton = uibutton(app.ImageprocessingthresholdTab, 'state');
            app.RunButton.ValueChangedFcn = createCallbackFcn(app, @RunButtonValueChanged, true);
            app.RunButton.Text = 'Run';
            app.RunButton.BackgroundColor = [0.9412 0.9804 1];
            app.RunButton.Position = [1175 9 100 23];

            % Create Thresholdluminancevalue100Label
            app.Thresholdluminancevalue100Label = uilabel(app.ImageprocessingthresholdTab);
            app.Thresholdluminancevalue100Label.HorizontalAlignment = 'center';
            app.Thresholdluminancevalue100Label.WordWrap = 'on';
            app.Thresholdluminancevalue100Label.Position = [23 666 148 43];
            app.Thresholdluminancevalue100Label.Text = 'Threshold luminance value [/100]';

            % Create ThAllSlider
            app.ThAllSlider = uislider(app.ImageprocessingthresholdTab);
            app.ThAllSlider.MajorTicks = [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100];
            app.ThAllSlider.ValueChangedFcn = createCallbackFcn(app, @ThAllSliderValueChanged, true);
            app.ThAllSlider.MinorTicks = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100];
            app.ThAllSlider.Position = [247 697 1021 3];
            app.ThAllSlider.Value = 10;

            % Create Thresholdluminancevaluebackgroundonly100Label
            app.Thresholdluminancevaluebackgroundonly100Label = uilabel(app.ImageprocessingthresholdTab);
            app.Thresholdluminancevaluebackgroundonly100Label.HorizontalAlignment = 'center';
            app.Thresholdluminancevaluebackgroundonly100Label.WordWrap = 'on';
            app.Thresholdluminancevaluebackgroundonly100Label.Position = [23 601 148 44];
            app.Thresholdluminancevaluebackgroundonly100Label.Text = 'Threshold luminance value (background only) [/100]';

            % Create ThBackSlider
            app.ThBackSlider = uislider(app.ImageprocessingthresholdTab);
            app.ThBackSlider.MajorTicks = [0 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100];
            app.ThBackSlider.ValueChangedFcn = createCallbackFcn(app, @ThBackSliderValueChanged, true);
            app.ThBackSlider.MinorTicks = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100];
            app.ThBackSlider.Position = [247 632 1021 3];
            app.ThBackSlider.Value = 10;

            % Create SelectthresholdsforimageprocessingLabel
            app.SelectthresholdsforimageprocessingLabel = uilabel(app.ImageprocessingthresholdTab);
            app.SelectthresholdsforimageprocessingLabel.FontSize = 18;
            app.SelectthresholdsforimageprocessingLabel.FontWeight = 'bold';
            app.SelectthresholdsforimageprocessingLabel.Position = [23 722 347 23];
            app.SelectthresholdsforimageprocessingLabel.Text = 'Select thresholds for image processing';

            % Create SwitchtomanualtrackingButton
            app.SwitchtomanualtrackingButton = uibutton(app.ImageprocessingthresholdTab, 'state');
            app.SwitchtomanualtrackingButton.ValueChangedFcn = createCallbackFcn(app, @SwitchtomanualtrackingButtonValueChanged, true);
            app.SwitchtomanualtrackingButton.Text = 'Switch to manual tracking';
            app.SwitchtomanualtrackingButton.BackgroundColor = [0.9608 0.9608 0.9608];
            app.SwitchtomanualtrackingButton.Position = [23 9 152 23];

            % Create DonotsubtractbackgroundCheckBox
            app.DonotsubtractbackgroundCheckBox = uicheckbox(app.ImageprocessingthresholdTab);
            app.DonotsubtractbackgroundCheckBox.ValueChangedFcn = createCallbackFcn(app, @DonotsubtractbackgroundCheckBoxValueChanged, true);
            app.DonotsubtractbackgroundCheckBox.Text = 'Do not subtract background';
            app.DonotsubtractbackgroundCheckBox.Position = [245 576 169 22];

            % Create rgbuseBkgSwitch
            app.rgbuseBkgSwitch = uiswitch(app.ImageprocessingthresholdTab, 'slider');
            app.rgbuseBkgSwitch.Items = {'[b]', '[b-r]'};
            app.rgbuseBkgSwitch.ItemsData = {'b', 'br'};
            app.rgbuseBkgSwitch.Orientation = 'vertical';
            app.rgbuseBkgSwitch.ValueChangedFcn = createCallbackFcn(app, @rgbuseBkgSwitchValueChanged, true);
            app.rgbuseBkgSwitch.FontSize = 1;
            app.rgbuseBkgSwitch.FontColor = [0.9412 0.9412 0.9412];
            app.rgbuseBkgSwitch.Position = [183 606 13 30];
            app.rgbuseBkgSwitch.Value = 'br';

            % Create bBkgLabel
            app.bBkgLabel = uilabel(app.ImageprocessingthresholdTab);
            app.bBkgLabel.Position = [202 599 21 26];
            app.bBkgLabel.Text = '[b]';

            % Create brBkgLabel
            app.brBkgLabel = uilabel(app.ImageprocessingthresholdTab);
            app.brBkgLabel.Position = [202 620 26 26];
            app.brBkgLabel.Text = '[b-r]';

            % Create rgbuseAllSwitch
            app.rgbuseAllSwitch = uiswitch(app.ImageprocessingthresholdTab, 'slider');
            app.rgbuseAllSwitch.Items = {'[b]', '[b-r]'};
            app.rgbuseAllSwitch.ItemsData = {'b', 'br'};
            app.rgbuseAllSwitch.Orientation = 'vertical';
            app.rgbuseAllSwitch.ValueChangedFcn = createCallbackFcn(app, @rgbuseAllSwitchValueChanged, true);
            app.rgbuseAllSwitch.FontSize = 1;
            app.rgbuseAllSwitch.FontColor = [0.9412 0.9412 0.9412];
            app.rgbuseAllSwitch.Position = [183 670 13 30];
            app.rgbuseAllSwitch.Value = 'br';

            % Create bAllLabel
            app.bAllLabel = uilabel(app.ImageprocessingthresholdTab);
            app.bAllLabel.Position = [202 663 21 26];
            app.bAllLabel.Text = '[b]';

            % Create brAllLabel
            app.brAllLabel = uilabel(app.ImageprocessingthresholdTab);
            app.brAllLabel.Position = [202 684 26 26];
            app.brAllLabel.Text = '[b-r]';

            % Create rgbuseLegendLabel
            app.rgbuseLegendLabel = uilabel(app.ImageprocessingthresholdTab);
            app.rgbuseLegendLabel.HorizontalAlignment = 'right';
            app.rgbuseLegendLabel.VerticalAlignment = 'bottom';
            app.rgbuseLegendLabel.FontSize = 10;
            app.rgbuseLegendLabel.Position = [1165 562 115 25];
            app.rgbuseLegendLabel.Text = {'[b-r]: channel subtraction'; '[b]: single channel'};

            % Create infoLabel1
            app.infoLabel1 = uilabel(app.ImageprocessingthresholdTab);
            app.infoLabel1.HorizontalAlignment = 'center';
            app.infoLabel1.FontSize = 10;
            app.infoLabel1.Position = [156 83 153 22];
            app.infoLabel1.Text = '(backgound pixels must be black)';

            % Create infoLabel2
            app.infoLabel2 = uilabel(app.ImageprocessingthresholdTab);
            app.infoLabel2.HorizontalAlignment = 'center';
            app.infoLabel2.FontSize = 10;
            app.infoLabel2.Position = [590 83 132 22];
            app.infoLabel2.Text = '(plume pixels must be white)';

            % Create infoLabel3
            app.infoLabel3 = uilabel(app.ImageprocessingthresholdTab);
            app.infoLabel3.HorizontalAlignment = 'center';
            app.infoLabel3.FontSize = 10;
            app.infoLabel3.Position = [1018 83 132 22];
            app.infoLabel3.Text = '(plume pixels must be white)';

            % Create frameSpinner
            app.frameSpinner = uispinner(app.ImageprocessingthresholdTab);
            app.frameSpinner.Limits = [1 Inf];
            app.frameSpinner.ValueChangedFcn = createCallbackFcn(app, @frameSpinnerValueChanged, true);
            app.frameSpinner.FontSize = 10;
            app.frameSpinner.Position = [690 538 61 14];
            app.frameSpinner.Value = 2;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app_FrameProcessing

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