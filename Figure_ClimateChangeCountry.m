clear all

REANALYSE = 0;
if REANALYSE == 1
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
    
    MinStrength = 0.025;
    SP_docs_topics(SP_docs_topics < MinStrength) = 0;
    ATS_docs_topics(ATS_docs_topics < MinStrength) = 0;
    
    % Go through the documents one by one and find each country's contribution overall
    load UniqueCountries
    ATS_climate_contribution = zeros(length(Unique_country_list),1);
    ATS_all_contributions = zeros(length(Unique_country_list),1);
    for row = 1:length(ATS_docs_details)
        
        % Which country/countries wrote this
        CountryAuthors = ATS_docs_details{row,4};
        
        F = [0 find(CountryAuthors == ',') length(CountryAuthors)+1];
        for ff = 1:length(F)-1
            ThisCountry = CountryAuthors(F(ff)+1:F(ff+1)-1);
            if ThisCountry(1) == ' '
                ThisCountry = ThisCountry(2:end);
            end
            H = find(strcmp(ThisCountry,Unique_country_list));
            ATS_climate_contribution(H) = ATS_climate_contribution(H) + ATS_docs_topics(row,CC_topic);
            ATS_all_contributions(H) = ATS_all_contributions(H) + 1;
        end
    end
    
    % Go through the data rows
    SP_climate_contribution = zeros(length(Unique_country_list),1);
    SP_all_contributions = zeros(length(Unique_country_list),1);
    for row = 1:length(SP_docs_details)
        
        % Which countries are in this row?
        CountryAuthors = SP_docs_details{row,4};
        CountryAuthors(find(CountryAuthors=='''')) = [];
        CountryAuthors(find(CountryAuthors==']')) = [];
        CountryAuthors(find(CountryAuthors=='[')) = [];
        
        F = [0 find(CountryAuthors == ',') length(CountryAuthors)+1];
        for ff = 1:length(F)-1
            ThisCountry = CountryAuthors(F(ff)+1:F(ff+1)-1);
            if ThisCountry(1)   == ' '; ThisCountry = ThisCountry(2:end); end
            while ThisCountry(end) == ' '; ThisCountry = ThisCountry(1:end-1); end
            
            % Replace the names that are wrong
            if strcmp(ThisCountry,'United States of America') == 1; ThisCountry = 'United States'; end
            if strcmp(ThisCountry,'England') == 1; ThisCountry = 'United Kingdom'; end
            if strcmp(ThisCountry,'English') == 1; ThisCountry = 'United Kingdom'; end
            if strcmp(ThisCountry,'Great Britain') == 1; ThisCountry = 'United Kingdom'; end
            if strcmp(ThisCountry,'Scotland') == 1; ThisCountry = 'United Kingdom'; end
            if strcmp(ThisCountry,'Wales') == 1; ThisCountry = 'United Kingdom'; end
            if strcmp(ThisCountry,'Russia') == 1; ThisCountry = 'Russian Federation'; end
            if strcmp(ThisCountry,'South Korea') == 1; ThisCountry = 'Korea (ROK)'; end
            if strcmp(ThisCountry,'Czech Republic') == 1; ThisCountry = 'Czechia'; end
            
            % Which country is this in the unique list?
            H = find(strcmp(ThisCountry,Unique_country_list));
            
            if isempty(H) == 0
                % This country exists in the ATS
                SP_climate_contribution(H) = SP_climate_contribution(H) + SP_docs_topics(row,CC_topic);
                SP_all_contributions(H) = SP_all_contributions(H) + 1;
            end
        end
    end
    
    SP_climate_focus = SP_climate_contribution./SP_all_contributions;
    ATS_climate_focus = ATS_climate_contribution./ATS_all_contributions;
    
    SP_climate_contribution = SP_climate_contribution./sum(SP_climate_contribution);
    ATS_climate_contribution = ATS_climate_contribution./sum(ATS_climate_contribution);
    
    save TEMP_country_contribution
    
end

load TEMP_country_contribution *contribution* Unique* *focus

Unique_country_list(strcmp(Unique_country_list,'Russian Federation')) = {'Russ Fed'};
Unique_country_list(strcmp(Unique_country_list,'United Kingdom')) = {'UK'};
Unique_country_list(strcmp(Unique_country_list,'United States')) = {'USA'};
Unique_country_list(strcmp(Unique_country_list,'Korea (DPRK)')) = {'N Korea'};
Unique_country_list(strcmp(Unique_country_list,'Korea (ROK)')) = {'S Korea'};
Unique_country_list(strcmp(Unique_country_list,'South Africa')) = {'S Africa'};
Unique_country_list(strcmp(Unique_country_list,'New Zealand')) = {'New Z'};

% figure(2), clf
CL = get(gca,'colororder'); FS = 18; MS = 10; FA = 0.2; TFS = 10;
% 
% [~,I] = sort(ATS_climate_contribution,'descend');
% B = bar(ATS_climate_contribution(I),0.7);
% set(B,'edgecolor','none','facecolor',CL(1,:),'facealpha',0.7)
% 
% for u = 1:length(Unique_country_list)
%     tt = text(u,ATS_climate_contribution(I(u))+0.005,Unique_country_list{I(u)},'fontsize',TFS,'rotation',45);
% end
% xlim([0.5 49.5])
% set(gca,'fontsize',FS-4,'xtick',[])
% ylabel('Contribution to ATCM documents','fontsize',FS)
% 
% Make_TIFF('Figures/ATCM_Party_Bars.tiff',[0 0 40 20])

figure(1), clf

subplot(1,2,1), hold on, box on

BNDS = [0.5e-4 0.2];
xmed = median(SP_climate_contribution);
ymed = median(ATS_climate_contribution);
plot([1e-6 1e6 nan xmed xmed],[ymed ymed nan 1e-6 1e6],'--','color',0.7.*ones(1,3))

plot(SP_climate_contribution,ATS_climate_contribution,'.','color','k','markersize',MS)
for u = 1:length(Unique_country_list)
    if rand < 0.5
        text(SP_climate_contribution(u)*1.05,ATS_climate_contribution(u)*0.95,Unique_country_list{u},'fontsize',TFS)
    else
        text(SP_climate_contribution(u)*0.95,ATS_climate_contribution(u)*1.05,Unique_country_list{u},'fontsize',TFS,'horizontalalignment','right')
    end
end

set(gca,'xscale','log','yscale','log','fontsize',FS-4)
title('(A) Cumulative contributions on climate change','fontsize',FS)
xlabel('Contribution to journal articles','fontsize',FS)
ylabel('Contribution to ATCM documents','fontsize',FS)
xlim(BNDS); ylim(BNDS)
axis square



% SP_climate_focus
% ATS_climate_focus

subplot(1,2,2), hold on, box on
CL = get(gca,'colororder'); FS = 18; MS = 10; FA = 0.2; TFS = 10;

xmed = nanmedian(SP_climate_focus);
ymed = nanmedian(ATS_climate_focus);
plot([1e-6 1e6 nan xmed xmed],[ymed ymed nan 1e-6 1e6],'--','color',0.7.*ones(1,3))

plot(SP_climate_focus,ATS_climate_focus,'.','color','k','markersize',MS)
for u = 1:length(Unique_country_list)
    if rand < 0.5
        text(SP_climate_focus(u)*1.05,ATS_climate_focus(u)*0.95,Unique_country_list{u},'fontsize',TFS)
    else
        text(SP_climate_focus(u)*0.95,ATS_climate_focus(u)*1.05,Unique_country_list{u},'fontsize',TFS,'horizontalalignment','right')
    end
end

set(gca,'xscale','log','yscale','log','fontsize',FS-4)
title('(B) Relative focus on climate change','fontsize',FS)
xlabel('Focus in journal articles','fontsize',FS)
ylabel('Focus in ATCM documents','fontsize',FS)
xlim([0.007 0.125])
ylim([0.0006 0.07])
axis square

Make_TIFF('Figures/CountryScatter.tiff',[0 0 40 20])











