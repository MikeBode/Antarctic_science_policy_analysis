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
FirstYear = 1992;
LastYear = 2020;
F = find(TopicStrength(:,6) <= FirstYear);
DocumentDetails(F,:) = [];
TopicStrength(F,:) = [];

% Remove data with null results
F = find(var(TopicStrength(:,7:36),[],2)<1e-4);
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

% Go through the years
for YR = 1992:2020
    
    % Find the documents from this year
    F_ATS = find(ATS_docs_years == YR);
    F_SP = find(SP_docs_years == YR);
    
    SP_topic_by_year(YR-1991,:)  = sum(SP_docs_topics(F_SP,:));
    ATS_topic_by_year(YR-1991,:) = sum(ATS_docs_topics(F_ATS,:));
end

SP_topic_by_year =  SP_topic_by_year./repmat(sum(SP_topic_by_year,2),1,30);
ATS_topic_by_year = ATS_topic_by_year./repmat(sum(ATS_topic_by_year,2),1,30);

for fig = 1:30
    figure(fig), clf, hold on
    plot(SP_topic_by_year(:,fig),'linewidth',2)
    plot(ATS_topic_by_year(:,fig),'linewidth',2)
    
end





































