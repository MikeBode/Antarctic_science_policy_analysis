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
    ATS_docs_topics = TopicStrength(ATS_docs_ID,7:36);
    ATS_docs_details = DocumentDetails(ATS_docs_ID,:);
    
    % Remove all the articles that don't have strong climate change elements
    ClimateChangeQuantile = 0.9;
    MinStrength = 0.05;
    
    Q_ATS = find(ATS_docs_topics(:,CC_topic) >= quantile(ATS_docs_topics(:,CC_topic),ClimateChangeQuantile));
    ATS_docs_topics = ATS_docs_topics(Q_ATS,:);
    ATS_docs_details = ATS_docs_details(Q_ATS,:);
    ATS_docs_topics(ATS_docs_topics < MinStrength) = 0;
    
    % Go through the documents one by one and find each country's contribution overall
    load UniqueCountries
    ATS_num_climate_contributions = zeros(length(Unique_country_list),1); % Strength of climate change in climate change related submissions
    ATS_strength_climate_contributions = zeros(length(Unique_country_list),1); % Strength of climate change in climate change related submissions
    
    for row = 1:length(ATS_docs_details)
        
        % Which country/countries wrote this
        CountryAuthors = ATS_docs_details{row,4};
        
        F = [0 find(CountryAuthors == ',') length(CountryAuthors)+1];
        Number_authors(row) = length(F)-1;
        
        for ff = 1:length(F)-1
            ThisCountry = CountryAuthors(F(ff)+1:F(ff+1)-1);
            if ThisCountry(1) == ' '
                ThisCountry = ThisCountry(2:end);
            end
            
            if strcmp(ThisCountry,'SCAR') == 1
                SCAR_Docs(row) = 1;
            end
            
            H = find(strcmp(ThisCountry,Unique_country_list));
            ATS_num_climate_contributions(H) = ATS_num_climate_contributions(H) + 1;
            ATS_strength_climate_contributions(H) = ATS_strength_climate_contributions(H) + ATS_docs_topics(row,CC_topic);
        end
    end
    save CC_submissions_per_country
end
load CC_submissions_per_country Unique_country_list ATS_strength_climate_contributions

% figure(1), clf
% subplot(2,1,1), hold on; FS = 16;
% [Sort_ATS_num_climate_contributions,I] = sort(ATS_num_climate_contributions,'descend');
% b = bar(ATS_num_climate_contributions(I),0.8);
% set(b,'edgecolor','none','facealpha',0.5)
% for i = 1:47
%     text(i,Sort_ATS_num_climate_contributions(i)+0.15,Unique_country_list(I(i)),'rotation',45,'fontsize',FS-8);
% end
% set(gca,'xtick',[])
% xlabel('ATCM Party','fontsize',FS)
% ylabel('Number of CC policy documents','fontsize',FS)


Unique_country_list = Unique_country_list([1 3:47]);
ATS_strength_climate_contributions = ATS_strength_climate_contributions([1 3:47]);

figure(2), clf, hold on; FS = 16;
ATS_strength_climate_contributions = 100*ATS_strength_climate_contributions./sum(ATS_strength_climate_contributions);

[Sort_ATS_strength_climate_contributions,I] = sort(ATS_strength_climate_contributions,'descend');
b = bar(ATS_strength_climate_contributions(I),0.8);
set(b,'edgecolor','none','facealpha',0.5)
for i = 1:46
    text(i,Sort_ATS_strength_climate_contributions(i)+0.5,Unique_country_list(I(i)),'rotation',45,'fontsize',FS-8);
end
set(gca,'xtick',[])
xlabel('ATCM Party','fontsize',FS)
ylabel('Contribution to ATCM documents (\%)','fontsize',FS)

Make_TIFF('Figures/CC_policy_contributions.tiff',[0 0 25 14]*1.1)

