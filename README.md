# NHANES-2021-2023-BMI-SQL-Analysis

Overview:

This project uses MySQL to analyze BMI patterns among adults aged 20 and older using data from the 2021–2023 National Health and Nutrition Examination Survey (NHANES).
The analysis focuses on data cleaning, data-quality checks, and descriptive analysis of BMI across age and sex groups.

Objectives:

- Assess the completeness and quality of BMI data
- Combine demographic and body-measurement data
- Analyze average BMI across age groups and sex
- Examine BMI-category distributions across demographic groups
- Produce a reproducible SQL-based analytical workflow

Tools:

- NHANES 2021–2023 data
- Python
- MySQL
- Microsoft Excel

SQL Techniques:

- SELECT, WHERE, and ORDER BY
- INNER JOIN
- GROUP BY
- Aggregate functions such as COUNT() and AVG()
- CASE expressions
- Conditional aggregation
- Data type conversion
- Regular expressions
- Data-quality checks
- Analysis

The project includes:

- Converting SAS files into CSV files using python
- Initial data exploration and profiling
- BMI data-quality and completeness checks
- Conversion of text-formatted BMI values to numeric values
- Validation of demographic codes
- BMI categorization
- Analysis of BMI by age group
- Analysis of BMI by sex
- Analysis of BMI by age group and sex
- Creation of a clustered column chart using a pivot table in Excel

Key Findings:

- BMI data completeness was assessed among participants aged 20 and older to be 99.83%.
- Average BMI varied across age and sex groups.
- BMI-category distributions differed across demographic groups.
- In every age group, females had a higher average BMI than males.
- The highest average BMI observed in this analysis was 31.06 among females aged 40–59.
- The lowest average BMI was 28.56 among males ages 20-39.
- Obesity was the largest BMI category in every combined age/sex group analyzed except males aged between 20-39 and aged 60+. In these cases the largest BMI category was overweight.

Visualization:

- Chart: Average BMI by Age Group and Sex
An Excel chart was created from a pivot table to visualize average BMI across age groups and sex.
The visualization makes it easier to compare average BMI between males and females within each age group.

Limitations:

This analysis is descriptive and does not apply NHANES survey weights. Therefore, the results should not be interpreted as nationally representative estimates of the U.S. population.

The project is intended to demonstrate SQL-based data cleaning, validation, and descriptive analysis rather than produce official population estimates.

Data Source

National Health and Nutrition Examination Survey (NHANES), 2021–2023.
