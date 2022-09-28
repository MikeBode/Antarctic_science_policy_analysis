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
    ATS_docs_topics = TopicStrength(ATS_docs_ID,7:36);
    ATS_docs_details = DocumentDetails(ATS_docs_ID,:);
    
    % Extract only the scientific papers
    SP_docs_ID = find(strcmp(DocumentDetails(:,2),'Scientific Paper') & strcmp(DocumentDetails(:,4),'NaN') == 0 & strcmp(DocumentDetails(:,4),'[]') == 0);
    SP_docs_topics = TopicStrength(SP_docs_ID,7:36);
    SP_docs_details = DocumentDetails(SP_docs_ID,:);
    
    % Remove all the articles that don't have strong climate change elements
    ClimateChangeQuantile = 0.5;
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
    
    save TEMP_Secondary
    
else
    load TEMP_Secondary *details *opic*
end

[~,TopicNames] = xlsread('../Web of science/LDA_model_for_SP/30 topics/30_topics_ATS_and_SP.xlsx');
TopicNames = TopicNames(24,2:end);
ORDR = [2 28 24 20 1 29 3 6 7 9 12 13 16 11 5 18 8 19 14 10 21 15 22 23 30 25 26 4 17 27];
CC_topic = find(ORDR == CC_topic);
ATS_docs_topics = ATS_docs_topics(:,ORDR);
SP_docs_topics = SP_docs_topics(:,ORDR);
TopicNames = TopicNames(ORDR);

% Go through the ATS documents one by one and find each country's contribution overall
load UniqueCountries
ATS_climate_contribution = zeros(length(Unique_country_list),30);
NumberPolicyContributions = zeros(length(Unique_country_list),1);
for row = 1:length(ATS_docs_details)
    
    % Which country/countries wrote this
    CountryAuthors = ATS_docs_details{row,4};
    
    F = [0 find(CountryAuthors == ',') length(CountryAuthors)+1];
    for ff = 1:length(F)-1
        ThisCountry = CountryAuthors(F(ff)+1:F(ff+1)-1);
        if ThisCountry(1) == ' '
            ThisCountry = ThisCountry(2:end);
        end
        
        % 'H' is the identity of the country that wrote this document
        H = find(strcmp(ThisCountry,Unique_country_list));
        
        ATS_climate_contribution(H,:) = ATS_climate_contribution(H,:) + ATS_docs_topics(row,:);
        NumberPolicyContributions(H) = NumberPolicyContributions(H) + 1;
    end
end

% Go through the scientific articles and find each country's contribution
SP_climate_contribution = zeros(length(Unique_country_list),Topics);
NumberScienceContributions = zeros(length(Unique_country_list),1);
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
            SP_climate_contribution(H,:) = SP_climate_contribution(H,:) + SP_docs_topics(row,:);
            NumberScienceContributions(H) = NumberScienceContributions(H) + 1;
        end
    end
end

% How many additional topics do you want to see?
Layers = 2;

% Go through the countries one-by-one
for h = 1:length(Unique_country_list)

    % Order the secondary topics
    [~,ThisCountryOrder] = sort(ATS_climate_contribution(h,:),'descend');
    
    % Ditch the higher order associations
    if sum(ATS_climate_contribution(h,:)) == 0
        ThisCountryOrder = nan.*ThisCountryOrder;
    end
    ThisCountryOrder(ThisCountryOrder > Layers) = nan;
    
    Order_ATS_climate_contribution(h,:) = ThisCountryOrder;
end

Unique_country_list(strcmp(Unique_country_list,'Russian Federation')) = {'Russ Fed'};
Unique_country_list(strcmp(Unique_country_list,'United Kingdom')) = {'UK'};
Unique_country_list(strcmp(Unique_country_list,'United States')) = {'USA'};
Unique_country_list(strcmp(Unique_country_list,'Korea (DPRK)')) = {'N Korea'};
Unique_country_list(strcmp(Unique_country_list,'Korea (ROK)')) = {'S Korea'};
Unique_country_list(strcmp(Unique_country_list,'South Africa')) = {'S Africa'};
Unique_country_list(strcmp(Unique_country_list,'New Zealand')) = {'New Z'};

% Reorder data
Unique_country_list = Unique_country_list(end:-1:1);
Order_ATS_climate_contribution = Order_ATS_climate_contribution(end:-1:1,:);

figure(1), clf, FS = 12;
subplot('position',[0.5703 0.125 0.4 0.82]); hold on
imagesc(Order_ATS_climate_contribution)
CM = [[1 1 1]; jet(50)];
colormap(CM) 
caxis( [-0.001 Layers] )
title('ATCM documents','fontsize',FS+2)
set(gca,'ytick',[1:47],'yticklabel',Unique_country_list,'fontsize',FS)
set(gca,'xtick',[1:30],'xticklabel',TopicNames,'fontsize',FS)
xtickangle(90)
for x = 0:30
    plot([x x]+0.5,[0 48],'color',0.7.*ones(1,3))
end
for y = 0:47
    plot([0 31],[y y]+0.5,'color',0.7.*ones(1,3))
    if y > 0 & (sum(Order_ATS_climate_contribution(y,:)==1) == 0)
        pp = patch([0 31 31 0],y+[-0.5 -0.5 0.5 0.5],0.9.*ones(1,3));
        set(pp,'edgecolor','none')
    end
end

box on
xlim([0.5 30.5])
ylim([0.5 47.5])

SP_climate_contribution = SP_climate_contribution./repmat(NumberScienceContributions,1,Topics);
SP_climate_contribution(isnan(SP_climate_contribution)) = 0;
SP_climate_contribution(:,CC_topic) = SP_climate_contribution(:,CC_topic).*0;

% Go through the countries one-by-one
for h = 1:length(Unique_country_list)

    % Order the secondary topics
    [~,ThisYearOrder] = sort(SP_climate_contribution(h,:),'descend');
    
    % Ditch the higher order associations
    if sum(SP_climate_contribution(h,:)) == 0
        ThisYearOrder = nan.*ThisYearOrder;
    end
    ThisYearOrder(ThisYearOrder > Layers) = nan;
    
    Order_SP_climate_contribution(h,:) = ThisYearOrder;
end


% Reorder data
Order_SP_climate_contribution = Order_SP_climate_contribution(end:-1:1,:);

subplot('position',[0.08 0.125 0.4 0.82]); hold on, 
imagesc(Order_SP_climate_contribution)
CM = [[1 1 1]; parula(5)];
CLL = get(gca,'colororder');
CLL = CLL([7 5 6 5 1 7],:);
CM = [[1 1 1]; CLL.^0.75];
colormap(CM)
caxis( [-0.001 Layers] )
title('Journal articles','fontsize',FS+2)
set(gca,'ytick',[1:47],'yticklabel',Unique_country_list,'fontsize',FS)
set(gca,'xtick',[1:30],'xticklabel',TopicNames,'fontsize',FS)
xtickangle(90)
for x = 0:30
    plot([x x]+0.5,[0 48],'color',0.7.*ones(1,3))
end
for y = 0:47
    plot([0 31],[y y]+0.5,'color',0.7.*ones(1,3))
    if y > 0 & (sum(Order_SP_climate_contribution(y,:)==1) == 0)
        pp = patch([0 31 31 0],y+[-0.5 -0.5 0.5 0.5],0.9.*ones(1,3));
        set(pp,'edgecolor','none')
    end
end

box on
xlim([0.5 30.5])
ylim([0.5 47.5])

Make_TIFF('Figures/SecondaryTertiaryTopics.tiff',[0 0 35 30])



