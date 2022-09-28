clear all

RECALCULATE = 0;

if RECALCULATE == 1;
    
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
    
    % Extract only the ATS documents
    ATS_docs_ID = find(strcmp(DocumentDetails(:,2),'ATS'));
    ATS_docs_years = TopicStrength(ATS_docs_ID,6);
    ATS_docs_topics = TopicStrength(ATS_docs_ID,7:36);
    ATS_docs_details = DocumentDetails(ATS_docs_ID,:);
    
    % Extract only the scientific papers
    SP_docs_ID = find(strcmp(DocumentDetails(:,2),'Scientific Paper') & strcmp(DocumentDetails(:,4),'NaN') == 0 & strcmp(DocumentDetails(:,4),'[]') == 0);
    SP_docs_years = TopicStrength(SP_docs_ID,6);
    SP_docs_topics = TopicStrength(SP_docs_ID,7:36);
    SP_docs_details = DocumentDetails(SP_docs_ID,:);
    
    % Remove all the articles that don't have strong climate change elements
    ClimateChangeQuantile = 0.9;
    MinStrength = 0.025;
    
    Q_SP = find(SP_docs_topics(:,CC_topic) >= quantile(SP_docs_topics(:,CC_topic),ClimateChangeQuantile));
    SP_docs_topics = SP_docs_topics(Q_SP,:);
    SP_docs_details = SP_docs_details(Q_SP,:);
    SP_num = size(SP_docs_topics,1);
    SP_docs_topics(SP_docs_topics < MinStrength) = 0;
    SP_topics = sum(SP_docs_topics);
    
    Q_ATS = find(ATS_docs_topics(:,CC_topic) >= quantile(ATS_docs_topics(:,CC_topic),ClimateChangeQuantile));
    ATS_docs_topics = ATS_docs_topics(Q_ATS,:);
    ATS_docs_details = ATS_docs_details(Q_ATS,:);
    ATS_docs_topics(ATS_docs_topics < MinStrength) = 0;
    ATS_num = size(ATS_docs_topics,1);
    save TEMP_cross
    
else
    load TEMP_cross *_docs_topics CC_topic ATS_docs_details Topics
end

% What are these topics called?
[~,TopicNames] = xlsread('../Web of science/LDA_model_for_SP/30 topics/30_topics_ATS_and_SP.xlsx');
ScienceOrPolicy = TopicNames(23,2:end);
TopicNames = TopicNames(22,2:end);

% Who's bringing the science into policy?
load UniqueCountries
NoCC = ones(1,Topics); NoCC(CC_topic) = 0;
for c = 1:length(Unique_country_list)
    Country_docs = contains(ATS_docs_details(:,4),Unique_country_list{c});
    Country_contribution_science(c) = sum(sum(ATS_docs_topics(Country_docs,:)).*strcmp(ScienceOrPolicy,'Science').*NoCC);
    Country_contribution_policy(c)  = sum(sum(ATS_docs_topics(Country_docs,:)).*strcmp(ScienceOrPolicy,'Policy' ).*NoCC);
end
%
% figure(3), clf
% subplot(2,1,1); hold on; CL = get(gca,'colororder');
% bb1 = bar(Country_contribution_policy+Country_contribution_science);
% bb2 = bar(Country_contribution_policy);
% set(bb1,'facecolor',CL(1,:),'edgecolor','none')
% set(bb2,'facecolor',CL(5,:),'edgecolor','none')
% set(gca,'xtick',[1:length(Unique_country_list)],'xticklabel',Unique_country_list,'fontsize',12)
%
% subplot(2,1,2), hold on; CL = get(gca,'colororder');
% for i = 1:10
%     plot([0 50],[1 1]*i/10,'-','color',0.5.*ones(1,3))
% end
% bb1 = bar(Country_contribution_policy.*0+1);
% bb2 = bar(Country_contribution_policy./(Country_contribution_policy+Country_contribution_science));
% set(bb1,'facecolor',CL(1,:),'edgecolor','none')
% set(bb2,'facecolor',CL(5,:),'edgecolor','none')
% set(gca,'xtick',[1:length(Unique_country_list)],'xticklabel',Unique_country_list,'fontsize',12)
% xlim([0.25 47.75])
%
% SCAR_docs = contains(ATS_docs_details(:,4),'SCAR');
%
% figure(2), clf, hold on; CL = get(gca,'colororder'); CL = min(1,CL+0.1);
% bb = bar(sum(ATS_docs_topics(SCAR_docs,:)).*strcmp(ScienceOrPolicy,'Science').*NoCC);
% set(bb,'facecolor',CL(1,:),'edgecolor','none')
% bb = bar(sum(ATS_docs_topics(SCAR_docs,:)).*strcmp(ScienceOrPolicy,'Policy').*NoCC);
% set(bb,'facecolor',CL(5,:),'edgecolor','none')

ORDR = [2 28 24 20 1 29 3 6 7 9 12 13 16 25 11 5 18 8 19 14 10 21 15 27 23 26 22 4 17 30];
CC_topic = find(ORDR == CC_topic);
ScienceOrPolicy = ScienceOrPolicy(ORDR);
ATS_docs_topics = ATS_docs_topics(:,ORDR);
SP_docs_topics = SP_docs_topics(:,ORDR);
TopicNames = TopicNames(ORDR);

% Plot the flow of topics
figure(4), clf
subplot('position',[0.08 0.05 0.9 0.9]); hold on, axis equal; CL = get(gca,'colororder'); CL = min(1,CL+0.1);
th = linspace(0,2*pi,100); FS = 18;
X1 = 0; X2 = 10;
YAT = 24; YSP = 6;
xS = linspace(X1,X2,100);
SH = 1.25;
TCL = 0.6.*ones(1,3);
FA = 1;

for i = 1:Topics
    if sum(ATS_docs_topics(:,i)) > 7
        yS = i+(YAT-i)./(1+exp(-SH*(xS-X2/2)));
        pp = plot(xS,yS,'color',CL(5,:),'linewidth',1);
        
        if sum(ATS_docs_topics(:,i)) > 13
            set(pp,'linewidth',2)
        elseif sum(ATS_docs_topics(:,i)) > 35
            set(pp,'linewidth',3)
        end
    end
    
    if sum(SP_docs_topics(:,i)) > 50
        yS = i+(YSP-i)./(1+exp(-SH*(xS-X2/2)));
        pp = plot(xS,yS,'color',CL(1,:),'linewidth',1);
        if sum(SP_docs_topics(:,i)) > 130
            set(pp,'linewidth',2)
        elseif sum(SP_docs_topics(:,i)) > 220
            set(pp,'linewidth',3)
        end
    end
end

for i = 1:Topics
    % Label the topic
    T = text(-1,i,[TopicNames{i}],'rotation',0,'horizontalalignment','right','fontsize',FS-3);
    if strcmp(ScienceOrPolicy{i},'Science') == 1
        set(T,'color','k');
    else
        set(T,'color','k');
    end
    
    % Visualise its magnitude
    r = 0.1+1.5*(mean(ATS_docs_topics(:,i)) + mean(SP_docs_topics(:,i)));
    x = r.*cos(th);
    y = r.*sin(th);
    pp = patch(x,y+i,TCL);
    set(pp,'edgecolor','none','facealpha',FA)
end

% Plot the ATS corpus on climate change
R = 15;
r = sqrt(sum(sum(ATS_docs_topics)))/R;
x = r.*cos(th);
y = r.*sin(th);
pp = patch(x+X2,y+YAT,CL(5,:));
set(pp,'edgecolor','none','facealpha',FA)
text(11.5,YAT,'ATCM documents','rotation',0,'horizontalalignment','left','fontsize',FS,'color',CL(5,:)*0.75)

% Plot the scientific corpus on climate change
r = sqrt(sum(sum(SP_docs_topics)))/R;
x = r.*cos(th);
y = r.*sin(th);
pp = patch(x+X2,y+YSP,CL(1,:));
set(pp,'edgecolor','none','facealpha',FA)
text(13.8,YSP,'Journal articles','rotation',0,'horizontalalignment','left','fontsize',FS,'color',CL(1,:)*0.75)

axis off
Make_TIFF('Figures/TopicFlow.tiff',[0 0 25 30])


















