function [D,ImageE]=maxSimRegionMerging()

global figHandle;                 % the handle of the interface
global orgImage;                  % the original image
global bwSegmentResultImage
global bwMarkerImage;               % the binary image with object and background marker
global Label;                     % 

Label2=Label;
hdl=get(figHandle,'userData');    % 
set(figHandle,'currentAxes',hdl.figHandle_Axes2);               % set hdl.figHandle_Axes2 as the current axes
mergeLabel=Label;                                               % the label of region merging
mergingTimes=1;                                                 % the number of the region merging

regionNum=max(Label(:));                                        % the number of the region
redbins=16;greenbins=16;bluebins=16;                            % the quantization of image
indImage=quanimage(orgImage,redbins,greenbins,bluebins);       

[height,width]=size(Label);                                  
Region=InitRegion(Label,indImage,bwMarkerImage,height,width);     % initilize the region. Region is a struct variable
SimTable=CompSim(Label,height,width,Region);                    % SimTable is a table which saves the similarity between the regions

MergeTable=-1*ones(1,regionNum);                                % initilize the MergeTable

k=0;                       % k is the times of region merging. the initial value is 0.
while 1
    k=k+1;              
    flag=0;                % 0��no region merging  1:region merging
    k1=0;                  % k1 is the times of region merging in the first stage
    while 1                % region merging in the first stage        
        k1=k1+1;           % 
        flag1=0;           % 0��no region merging  1:region merging
        for i=1:regionNum  %         
            % markerType   0 non-marker region  1 background  2 foreground
            % background marker regions merge with non-marker regions as
            % possible in the first stage
            if Region(i).markerType==1                         % region i is background
                % 
                for j=1:regionNum                              % 
                    if i~=j & SimTable(i,j)>0 & Region(j).markerType~=2        % region i and region j is adjacent and region i belongs to non-marker region
                        index=MaxSimIndex(j,SimTable,regionNum);               % 
                        if i==index                                            % 
                            if i<j                          
                                MergeTable=MergeRecord(MergeTable,i,j,regionNum);                                
                                flag1=1;                                       % 
                                flag=1;                                        % 
                            elseif i>j
                                MergeTable=MergeRecord(MergeTable,j,i,regionNum);
                                flag=1;                                        % 
                                flag1=1;                                       % 
                            end
                        end
                    end
                end
            end
        end

        if flag1==0
            break;
        end
        [Label2,regionNum,Region]=MergePostProc2(Label2,MergeTable,regionNum,Region);
        SimTable=CompSim(Label2,height,width,Region);
        
        % 
        MergeTable=-1*ones(1,regionNum);
        ImageE=drawEdge(orgImage,Label2);
   
        set(hdl.segImage, 'XData',[1 width],'YData',[1 height],'Cdata',ImageE);drawnow;
       
        if k==1
            str2='st round';
        elseif k==2
            str2='nd round';        
        end
        title([num2str(k1),'th ','merging in 1th stage ','( ',num2str(k),str2,')']);drawnow;
        pause(1);
    end
    % -------------------------- region merging of the first stage merges ends  --------------------------

    if flag==0  
        break;
    end
    
    % -------------------------- region merging of the second stage merge starts --------------------------
    flag2=1;
    k1=0;
    while 1   %   non-marker regions are merged each other in the second stage
        k1=k1+1; 
        flag2=0;

        for i=1:regionNum
            if Region(i).markerType==0      % for non-marker regions
                % 
                for j=1:regionNum
                    % region i is not marked and region i and region is is adjacent
                    if i~=j & Region(j).markerType==0 & SimTable(i,j)>0
                        index=MaxSimIndex(j,SimTable,regionNum);
                        if i==index
                            if i<j
                                MergeTable=MergeRecord(MergeTable,i,j,regionNum);
                                flag=1;          
                                flag2=1;         
                            else
                                MergeTable=MergeRecord(MergeTable,j,i,regionNum);
                                flag=1;
                                flag2=1;
                            end
                        end
                    end
                end
            end
        end
        
        if flag2==0
            break;
        end
        
        %
        [Label2,regionNum,Region]=MergePostProc2(Label2,MergeTable,regionNum,Region);
        SimTable=CompSim(Label2,height,width,Region);

        MergeTable=-1*ones(1,regionNum);

        ImageE=drawEdge(orgImage,Label2);
        set(hdl.segImage, 'XData',[1 width],'YData',[1 height],'Cdata',ImageE);drawnow;
        
        if k==1
            str2='st round';
        elseif k==2
            str2='nd round';        
        end        
        title([num2str(k1),'th ','merging in 2th stage ','(',num2str(k),str2,')']);drawnow;
        pause(1);
    end
    if flag==0
        break;
    end
end

% extract the object
bwSegmentResultImage=0.*Label;
for i=1:regionNum
    if Region(i).markerType~=1
       bwSegmentResultImage(find(Label2==i))=1;
    end
end

ImageE=drawEdge(orgImage,bwSegmentResultImage);
set(hdl.segImage, 'XData',[1 width],'YData',[1 height],'Cdata',ImageE);drawnow;
title(['Segmentation by MSRM']);