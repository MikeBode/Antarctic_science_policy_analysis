clear all

% Choose the number of topics
Topics = 30;

if Topics == 30
    CC_topic = 25;
    % [TopicStrength,DocumentDetails] = xlsread('../Web of science/LDA_model_for_SP/30 topics/30_topics_distribution.xlsx');
%     save TEMP_30
    load TEMP_30
elseif Topics == 50
    CC_topic = 7;
%     [TopicStrength,DocumentDetails] = xlsread('../Web of science/LDA_model_for_SP/50 topics/50_topics_distribution.xlsx');
%     save TEMP_50
    load TEMP_50
elseif Topics == 70
end

% Remove null data points
F = [1; find(isnan(TopicStrength(:,6)))];
DocumentDetails(F,:) = [];
TopicStrength(F,:) = [];

% Remove data before a threshold date
FirstYear = 1991;
LastYear = 2020;
F = find(TopicStrength(:,6) <= FirstYear);
FirstYear = 1992;
DocumentDetails(F,:) = [];
TopicStrength(F,:) = [];

% Extract only the ATS documents
ATS_docs_ID = find(strcmp(DocumentDetails(:,2),'ATS'));
ATS_docs_years = TopicStrength(ATS_docs_ID,6);
ATS_docs_topics = TopicStrength(ATS_docs_ID,7:36);

% Extract only the scientific papers
SP_docs_ID = find(strcmp(DocumentDetails(:,2),'Scientific Paper'));
SP_docs_years = TopicStrength(SP_docs_ID,6);
SP_docs_topics = TopicStrength(SP_docs_ID,7:36);

YearVec = FirstYear:LastYear;
for y = 1:length(YearVec)
    % Which ATS documents were written this year
    F = find(ATS_docs_years == YearVec(y));
    ATS_climate_strength_by_Year(y) = sum(ATS_docs_topics(F,CC_topic));
    ATS_publications_by_Year(y)     = length(F);

    % Which scientific papers were written this year
    F = find(SP_docs_years == YearVec(y));
    SP_climate_strength_by_Year(y) = sum(SP_docs_topics(F,CC_topic));
    SP_publications_by_Year(y)     = length(F);
end

% Fill in missing ATS years (no ATCMs) with surrounding years
for y = 1:length(YearVec)
    if ATS_climate_strength_by_Year(y) == 0
        
        % First the strength of climate publications
        ATS_climate_strength_by_Year(y) = ATS_climate_strength_by_Year(y+1)/2;
        ATS_climate_strength_by_Year(y+1) = ATS_climate_strength_by_Year(y+1)/2;

        % Next all publications
        ATS_publications_by_Year(y) = ATS_publications_by_Year(y+1)/2;
        ATS_publications_by_Year(y+1) = ATS_publications_by_Year(y+1)/2;
    end
end

M_ATS_climate_strength_by_Year = max(0,smooth(ATS_climate_strength_by_Year,10,'loess'));
M_SP_climate_strength_by_Year = max(0,smooth(SP_climate_strength_by_Year,10,'loess'));

figure(1), clf
CL = get(gca,'colororder');
FS = 15; MS = 18;

subplot('position',[0.07 0.11 0.4 0.85]); hold on
bb = bar(YearVec,ATS_climate_strength_by_Year,0.7);
set(bb,'edgecolor',0.4.*ones(1,3),'facecolor',CL(6,:),'facealpha',0.5)
plot(YearVec,M_ATS_climate_strength_by_Year,'linewidth',2,'color',CL(6,:).^2);
xlabel('Year','fontsize',FS)
ylabel('ATCM document equivalents','fontsize',FS)
CornerLetterLabel('(A)',[-0.15 1],FS)

subplot('position',[0.57 0.11 0.4 0.85]); hold on
bb = bar(YearVec,SP_climate_strength_by_Year,0.7);
set(bb,'edgecolor',0.4.*ones(1,3),'facecolor',CL(5,:),'facealpha',0.5)
plot(YearVec,M_SP_climate_strength_by_Year,'linewidth',2,'color',CL(5,:).^2);
xlabel('Year','fontsize',FS)
ylabel('Journal article equivalents','fontsize',FS)
CornerLetterLabel('(B)',[-0.15 1],FS)
Make_TIFF('Figures/Equivalent_strength_of_CC_through_time.tiff',[0 0 30 16])


Rel_ATS_climate_strength_by_Year = ATS_climate_strength_by_Year./ATS_publications_by_Year;
Rel_SP_climate_strength_by_Year = SP_climate_strength_by_Year./SP_publications_by_Year;

M_rel_ATS_climate_strength_by_Year = max(0,smooth(Rel_ATS_climate_strength_by_Year,10,'loess'));
M_rel_SP_climate_strength_by_Year = max(0,smooth(Rel_SP_climate_strength_by_Year,10,'loess'));

figure(2), clf
subplot('position',[0.07 0.11 0.4 0.85]); hold on
bb = bar(YearVec,Rel_ATS_climate_strength_by_Year,0.7);
set(bb,'edgecolor',0.4.*ones(1,3),'facecolor',CL(6,:),'facealpha',0.5)
plot(YearVec,M_rel_ATS_climate_strength_by_Year,'linewidth',2,'color',CL(6,:).^2);
xlabel('Year','fontsize',FS)
ylabel('Strength of climate change topic in ATCM documents','fontsize',FS)
CornerLetterLabel('(A)',[0.05 0.95],FS)

subplot('position',[0.57 0.11 0.4 0.85]); hold on
bb = bar(YearVec,Rel_SP_climate_strength_by_Year,0.7);
set(bb,'edgecolor',0.4.*ones(1,3),'facecolor',CL(5,:),'facealpha',0.5)
plot(YearVec,M_rel_SP_climate_strength_by_Year,'linewidth',2,'color',CL(5,:).^2);
xlabel('Year','fontsize',FS)
ylabel('Strength of climate change topic in journal articles','fontsize',FS)
CornerLetterLabel('(B)',[0.05 0.95],FS)
Make_TIFF('Figures/Relative_strength_of_CC_through_time.tiff',[0 0 30 16])
















