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
    
    % Remove data with null results
    F = find(var(TopicStrength(:,7:Topics+6),[],2)<1e-4);
    DocumentDetails(F,:) = [];
    TopicStrength(F,:) = [];
    
    % Extract only the ATS documents
    ATS_docs_ID = find(strcmp(DocumentDetails(:,2),'ATS'));
    ATS_docs_years = TopicStrength(ATS_docs_ID,6);
    ATS_docs_topics = TopicStrength(ATS_docs_ID,7:Topics+6);
    
    % Extract only the scientific papers
    SP_docs_ID = find(strcmp(DocumentDetails(:,2),'Scientific Paper'));
    SP_docs_years = TopicStrength(SP_docs_ID,6);
    SP_docs_topics = TopicStrength(SP_docs_ID,7:Topics+6);
    
    AllMat = [ATS_docs_topics;SP_docs_topics];
    CC = corr(AllMat(randsample(1:length(AllMat),1e3),:)');
    CC = CC(:); CC(CC==1) = []; Similar_Dissimilar = quantile(CC,[0.01 0.99]);
    
    % Now remove all the articles that don't have strong climate change elements
    ClimateChangeQuantile = 0.9;
	MinStrength = 0.025;

    Q_SP = find(SP_docs_topics(:,CC_topic) >= quantile(SP_docs_topics(:,CC_topic),ClimateChangeQuantile));
    SP_docs_topics = SP_docs_topics(Q_SP,:);
    SP_docs_years = SP_docs_years(Q_SP);
    [~,I] = sort(SP_docs_years,'ascend');
    SP_docs_years = SP_docs_years(I);
    SP_docs_topics = SP_docs_topics(I,:);
    SP_docs_topics(SP_docs_topics < MinStrength) = 0;
    SP_num = size(SP_docs_topics,1);
    
    Q_ATS = find(ATS_docs_topics(:,CC_topic) >= quantile(ATS_docs_topics(:,CC_topic),ClimateChangeQuantile));
    ATS_docs_topics = ATS_docs_topics(Q_ATS,:);
    ATS_docs_years = ATS_docs_years(Q_ATS);
    [~,I] = sort(ATS_docs_years,'ascend');
    ATS_docs_years = ATS_docs_years(I);
    ATS_docs_topics = ATS_docs_topics(I,:);
    ATS_docs_topics(ATS_docs_topics < MinStrength) = 0;
    ATS_num = size(ATS_docs_topics,1);
    
    AllMat = [ATS_docs_topics;SP_docs_topics];
    save TEMP
else
    load TEMP AllMat CC_topic ATS_num Topics ATS_docs_topics SP_docs_topics
end

% We want to remove the climate change topic, because we already know it'll be similar
% AllMat(:,CC_topic) = [];

% We might want to log transform the data because it looks lognormal.
% We might also want to remove the weak signals from the data
% Neither make
% AllMat = log(AllMat);
% AllMat(AllMat<1e-2) = 0;

% % Calculate similarity using Pearson's correlation
% CC = corrcoef(AllMat');

% Investigate what secondary topic is responsible for the most similarity and the least similarity
CL = get(gca,'colororder'); FS = 16; FA = 0.5;
% figure(2), clf, hold on; 
% for T = 1:Topics
%     plot(mean(ATS_docs_topics(:,T)), mean(SP_docs_topics(:,T)),'o','markersize',10)
%     plot(quantile(ATS_docs_topics(:,T),[0.16 0.84]),...
%          mean(SP_docs_topics(:,T))+[0 0],...
%          '-','linewidth',1,'color',0.8.*ones(1,3))
%     plot(mean(ATS_docs_topics(:,T))+[0 0],...
%          quantile(SP_docs_topics(:,T),[0.16 0.84]),...
%          '-','linewidth',1,'color',0.8.*ones(1,3))
%     text(mean(ATS_docs_topics(:,T))+0.004, mean(SP_docs_topics(:,T)), num2str(T))
% end
% plot([1e-2 0.2],[1e-2 0.2],'k--')
% title('Average topic strength','fontsize',FS)
% xlabel('Policy contribution','fontsize',FS)
% ylabel('Scientific contribution','fontsize',FS)
% xlim([0 0.25]); ylim([0 0.25])
% 
% for T = 1:Topics
%     plot(mean(ATS_docs_topics(:,T)), mean(SP_docs_topics(:,T)),'.','markersize',10)
%     text(mean(ATS_docs_topics(:,T))+0.004, mean(SP_docs_topics(:,T)), num2str(T))
% end

% Calculate similarity using Manhattan distance
CC = 1-pdist((AllMat),'correlation');
Similar_Dissimilar = quantile(CC,[0.01 0.99]);
CC = squareform(CC);

% Extract the inter and intra corpus comparisons
CC_ATS_ATS = CC(1:ATS_num,1:ATS_num);
CC_ATS_SP = CC(1:ATS_num,ATS_num+1:end);
CC_SP_SP = CC(ATS_num+1:end,ATS_num+1:end);

cr = linspace(Similar_Dissimilar(1)-0.15,Similar_Dissimilar(2)+0.15,70);
[~,mcr] = min(abs(cr));
re = nan*ones(size(cr))'; re(mcr) = 1;

% Plot all the comparisons
figure(1), clf

Similar_Dissimilar = [-0.2 0 1];
tickLabels = {'$\rho = -0.2$';'0';'$\rho = 1$'};

H_ATS   = histc(CC_ATS_ATS(:),cr); H_ATS = H_ATS./sum(H_ATS);
H_SP    = histc(CC_SP_SP(:),cr); H_SP = H_SP./sum(H_SP);
H_cross = histc(CC_ATS_SP(:),cr); H_cross = H_cross./sum(H_cross);
subplot(3,1,1), hold on
b = bar(cr,H_ATS,0.7); set(b,'facecolor',CL(1,:),'edgecolor','none','facealpha',FA)
b2 = bar(cr,H_ATS.*re,0.7); set(b2,'facecolor',CL(1,:),'edgecolor','none','facealpha',1)
set(gca,'xtick',Similar_Dissimilar,'xticklabel',tickLabels,'fontsize',FS-2,'ytick',[])
xlim([Similar_Dissimilar(1) Similar_Dissimilar(3)]+[-0.15 0.15]);
TT = CornerLetterLabel('Within ATCM documents',[0.05,1.05],15);
set(TT,'fontsize',FS,'horizontalalignment','left','color',CL(1,:));
CornerLetterLabel('(A)',[-0.05 1],FS);

subplot(3,1,2), hold on
b = bar(cr,H_SP,0.7); set(b,'facecolor',CL(5,:),'edgecolor','none','facealpha',FA)
b = bar(cr,H_SP.*re,0.7); set(b,'facecolor',CL(5,:),'edgecolor','none','facealpha',1)
YL = ylim; XL = xlim; 
set(gca,'xtick',Similar_Dissimilar,'xticklabel',tickLabels,'fontsize',FS-2,'ytick',[])
xlim([Similar_Dissimilar(1) Similar_Dissimilar(3)]+[-0.15 0.15]);
TT = CornerLetterLabel('Within journal articles',[0.05,1.05],15);
set(TT,'fontsize',FS,'horizontalalignment','left','color',CL(5,:));
CornerLetterLabel('(B)',[-0.05 1],FS);

subplot(3,1,3), hold on
b = bar(cr,H_cross,0.7); set(b,'facecolor',CL(7,:),'edgecolor','none','facealpha',FA)
b = bar(cr,H_cross.*re,0.7); set(b,'facecolor',CL(7,:),'edgecolor','none','facealpha',1)
xlabel('Pearson''s $\rho$','fontsize',FS)
set(gca,'xtick',[Similar_Dissimilar(1) Similar_Dissimilar(2)],'xticklabel',tickLabels,'fontsize',FS-2,'ytick',[])
set(gca,'xtick',Similar_Dissimilar,'xticklabel',tickLabels,'fontsize',FS-2,'ytick',[]);
TT = CornerLetterLabel('Between journal articles and ATCM documents',[0.05,1.05],15);
set(TT,'fontsize',FS,'horizontalalignment','left','color',CL(7,:));
CornerLetterLabel('(C)',[-0.05 1],FS);

Make_TIFF('Figures/Similarity_among_documents.tiff',[0 0 25 30])




