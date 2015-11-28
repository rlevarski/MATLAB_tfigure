classdef tfigure < hgsetget
    %TFIGURE A figure for holding tabbed groups of plots
    %   Creates a tabbed plot figure.  This allows the user to setup tabs
    %    to group plots.  Each tab contains a list of plots that can be
    %    selected using buttons on the left of the figure.
    %    
    %   Example
    %    h = tfigure;
    %
    % tfigure Properties:
    %  fig - Handle to the figure that displays tfigure.
    %  tabs - Handles to each of the tfigure's tabs
    %  figureSize - Current size of the figure containing tfigure
    %
    % tfigure Methods:
    %  tfigure - Constructs a new tabbed figure
    %  addTab - Adds a new tab
    %  addPlot - Adds a new plot to the given tab
    %  addSummary - Adds a summary
    %
    % Examples:
    %  <matlab:tfigure_example> tfigure example
    %
    % TO DO:
    %  * Finish Summary Slide functionality
    %  * Add "save all plots" functionality to the summary slide
    %     * ppt, pictures, figures
    %  * Add support for using a ppt template
    %  * Fix the handling of resizing figures that contain plots with 
    %   legends outside of their axis 
    %  * Add tables as an option for displaying data
    %
    % Author: Curtis Mayberry
    % Curtisma3@gmail.com
    % Curtisma.org
    %
    % see also: tFigExample
    
    properties
        fig % Handle to the figure that displays tfigure.
        tabs % Handles to each of the tfigure's tabs
        menu % Tfigure menu
    end
    properties (Dependent)
        figureSize % Current size of the figure containing tfigure
    end
    properties (Access = private)
        tabGroup
    end
    methods
        function obj = tfigure(varargin)
        % TFIGURE([title_tab1]) Creates a new tabbed figure.
        %  Additional tabs can be added to the figure using the addTab
        %  function.  Plots can be added to each tab by using the addPlot
        %  function.
        	obj.fig = figure('Visible','off',...
                             'SizeChangedFcn',@obj.figResize); 
            obj.tabGroup = uitabgroup('Parent', obj.fig);
            obj.addTab;
            obj.menu = uimenu(obj.fig,'Label','Tfigure');
            uimenu(obj.menu,'Label','Export PPT','Callback',@obj.savePPT)
            obj.fig.Visible = 'on';
        end
        function out = get.figureSize(obj)
            out = get(obj.fig,'position');
        end
        function h = addSummary(obj)
            h = uitab('Parent', obj.tabGroup, 'Title', 'Summary');
            obj.tabs(2:end+1) = obj.tabs(1:end);
            obj.tabs(1) = h;
            obj.tabGroup.Children = obj.tabGroup.Children([end 1:end-1]);
        end
        function h = addTab(obj,varargin)
        % addTab([title]) Adds a new tab with the given title.
        %
        % USAGE:
        %  tfig.addTab(title);
        %
            p = inputParser;
            addOptional(p,'titleIn',...
                        ['dataset ' num2str(length(obj.tabs) +1)],@isstr);
            parse(p,varargin{:});
            h = uitab('Parent', obj.tabGroup,...
                      'Title', p.Results.titleIn);
            obj.tabs(end+1) = h;
            figSize = obj.figureSize;
            plotList = uibuttongroup('parent',h,'Title','Plots',...
                                     'Units','pixels',...
                                     'Position',[10 10  150 figSize(4)-45],...
                                     'tag','plotList',...
                                     'SelectionChangedFcn',@obj.selectPlot);
%             axes('position',[0.35 0.1  0.6 0.88],'Parent',h);
            axes('Parent',h,'Units','pixels',...
                'position',[210 50  figSize(3)-240 figSize(4)-110],'ActivePositionProperty','OuterPosition');
        end
        function h = addPlot(obj,tab,fun_handle,varargin)
        % addPlot(tab, fun_handle,[title]) Adds a plot button to the given tab.  
        %  When the button is selected the plotting routine given by
        %  fun_handle is ran.
        %  
            p=inputParser;
            p.addRequired('tab',@(x) (isa(x,'double') || isa(x,'matlab.ui.container.Tab') || ischar(x)))
            p.addRequired('fun_handle',@(x) isa(x,'function_handle'));
            p.addOptional('title','plot',@ischar)
            p.parse(tab,fun_handle,varargin{:})
            if(ischar(tab))
                tab_obj = findobj(tab,'Type','tab');
                if(isempty(tab_obj))
                    obj.addTab(tab)
                else
                    tab = tab_obj;
                end
            end
            figSize = obj.figureSize;
            plotList = findobj(tab,'tag','plotList','-and',...
                                'Type','uibuttongroup');
            numPlots = length(findobj(plotList,'tag','plot','-and',...
                                      'Style','togglebutton'));
%             obj.tabs.UserData.plotlist = cell([]);
            h = uicontrol('parent',plotList,...
                            'Style', 'togglebutton',...
                            'String', p.Results.title,'Units','pixels',...
                            'Position', [10 figSize(4)-85-30*numPlots 120 20],...
                            'tag','plot');
            h.UserData = fun_handle;
            plotList.SelectedObject = h;
            obj.selectPlot(plotList,[]);
        end
        function h = addTable(obj,tab,fun_handle,fig,varargin)
        % addTable Adds a table to hte given tab.
        %
        % TODO
        %
           
        end
        function savePPT(obj,varargin)
        % savePPT Saves all the plots in tfigure to a powerpoint 
        %  presentation.  
        % 
            if(~(exist('exportToPPTX','file')))
               error('tfigure:NeedExportToPPTX',...
                     ['exportToPPTX must be added to the path. ',...
                     'It can be downloaded from the MATLAB file exchange']);
            end
            if(~isempty(obj.fig.Name))
                figTitle = obj.fig.Name;
            else
                figTitle = ['Figure ' num2str(obj.fig.Number) ' Data'];
            end
            p = inputParser;
            p.addOptional('fileName','',@ischar);
            p.addParameter('title',figTitle);
            p.addParameter('author','');
            p.addParameter('subject','');
            p.addParameter('comments','');
            p.parse(varargin{:});
            if(isempty(p.Results.fileName))
                [fileName,pathname] = uiputfile('.pptx','Export PPTX: select a file name');
                fileName = fullfile(pathname,fileName);
            else
                fileName = p.Results.fileName;
            end
            isOpen  = exportToPPTX();
            if ~isempty(isOpen),
                % If PowerPoint already started, then close first and then open a new one
                exportToPPTX('close');
            end
            exportToPPTX('new',... %'Dimensions',[12 6], ...
                         'Title',p.Results.title, ...
                         'Author',p.Results.author, ...
                         'Subject',p.Results.subject, ...
                         'Comments',p.Results.comments);
            exportToPPTX('addslide');
            exportToPPTX('addtext',p.Results.title,...
                         'HorizontalAlignment','center',...
                         'VerticalAlignment','middle','FontSize',48);
            numTabs = length(obj.tabs);
            summary = findobj(obj.tabs,'Title','Summary');
            if(~isempty(summary))
                startTab = 2;
            end
            for tabNum = startTab:numTabs
                ht = get(obj.tabs(tabNum));
                hp = findobj(ht.Children,'tag','plot');
                exportToPPTX('addslide');
                exportToPPTX('addtext',ht.Title,...
                             'HorizontalAlignment','center',...
                             'VerticalAlignment','middle','FontSize',48);
                for plotNum = 1:length(hp)
                    h = figure('Position',obj.fig.Position,...
                               'Color',[1 1 1],'Visible','off');
                    hp(plotNum).UserData();
                    exportToPPTX('addslide');
                    exportToPPTX('addpicture',h,'Scaled','maxfixed');
                    close(h);
                end
            end
            exportToPPTX('save',fileName);
            exportToPPTX('close');
        end
    end
    methods (Access = private)
        function figResize(obj,src,~) % callbackdata is unused 3rd arg.
        % figResize Resizes the gui elements in each tab whenever the 
        %  figure is resized. 
            figSize = obj.figureSize;
            % Resize each list of plots
            plotLists = findobj(src,'tag','plotList','-and',...
                                'Type','uibuttongroup');
            set(plotLists,'Units','pixels','Position',[10 10  150 figSize(4)-45])
            % Resize each axis
            axesList = findobj(src,'Type','axes');
            set(axesList,'Units','pixels','Position',[210 50  figSize(3)-240 figSize(4)-110],'ActivePositionProperty','OuterPosition')
            % Reposition plot buttons
            for i_tab = 1:length(obj.tabs)
                plots = findobj(obj.tabs(i_tab),'tag','plot','-and',...
                                'Style','togglebutton');
                for n = 1:length(plots)
                    set(plots(n),'Position',[10 figSize(4)-85-30*(n-1) 120 20]);
                end
            end
        end
        function selectPlot(~,src,~) % ~ is obj and callbackdata
            if isa(src.SelectedObject.UserData, 'function_handle')
                axes(findobj(src.Parent,'Type','Axes'));
                src.SelectedObject.UserData(); % contains the plot function handle
            end
        end
    end
end

