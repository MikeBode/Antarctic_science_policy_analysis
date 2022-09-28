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
    ATS_country_year = zeros(length(Unique_country_list),2025);
    ATS_country_year_all = zeros(length(Unique_country_list),2025);
    ATS_climate_contribution = zeros(length(Unique_country_list),1);
    ATS_all_contributions = zeros(length(Unique_country_list),1);
    for row = 1:length(ATS_docs_details)
        
        % Which country/countries wrote this
        CountryAuthors = ATS_docs_details{row,4}
        
        F = [0 find(CountryAuthors == ',') length(CountryAuthors)+1];
        for ff = 1:length(F)-1
            ThisCountry = CountryAuthors(F(ff)+1:F(ff+1)-1);
            if ThisCountry(1) == ' '
                ThisCountry = ThisCountry(2:end);
            end
            H = find(strcmp(ThisCountry,Unique_country_list));
            ATS_climate_contribution(H) = ATS_climate_contribution(H) + ATS_docs_topics(row,CC_topic);
            ATS_all_contributions(H) = ATS_all_contributions(H) + 1;
            ATS_country_year(H,ATS_docs_years(row)) = ATS_country_year(H,ATS_docs_years(row)) + ATS_docs_topics(row,CC_topic);
            ATS_country_year_all(H,ATS_docs_years(row)) = ATS_country_year_all(H,ATS_docs_years(row)) + 1;
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
    
    save TEMP_country_contribution_years
    
end

load TEMP_country_contribution_years ATS_country_year* Unique_country_list
load Country_or_not UC

% Normalise the data to the relative contribution (compared to all others)
ATS_country_year = ATS_country_year./repmat(sum(ATS_country_year_all),47,1);
ATS_country_year(isnan(ATS_country_year)) = 0;

% Look at the last decade. What's the linear trend?
count = 1; FS = 12;
for c = 1:47
    if sum(ATS_country_year(c,2009:2019)==0) < 7
        if UC(c) == 1
            
            subplot(4,3,count), cla, hold on
            
            Y = ATS_country_year(c,:);
            Y = Y./max(Y);
            YY = Y(2009:2019);
            
            mdl = fitlm(2009:2019,YY);
            pv = mdl.Coefficients.pValue(2);
            
            xx = linspace(2009,2020,2);
            if pv < 0.75
    
                p = polyfit(2009:2019,YY,1);
                yy = max(0,polyval(p,xx));
                
            else
                yy = xx.*0 + mean(YY);
            end
            
            
            bar(Y)
            plot(xx,yy,'r-','linewidth',2)
            
            Unique_country_list{c}
            if pv < 0.75
                title([Unique_country_list{c} ' *'],'fontsize',FS)
            else
                title(Unique_country_list{c},'fontsize',FS)
            end
            ylabel('CC contributions','fontsize',FS)
            
            xlim([1992 2021])

%             set(gca,'
            count = count + 1
        end
    end
end
Make_TIFF('Separate_country_trends.tiff',[0 0 30 25])





