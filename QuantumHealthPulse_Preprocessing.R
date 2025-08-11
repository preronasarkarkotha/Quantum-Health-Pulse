# Load library
library(dplyr)


# Dataset Import
dataset <- read.csv("D:/University/Semester 8/Data Science/MID/Project/HeartHealth-DataPreprocessing-R/Dataset/HeartDisease_QuantumData.csv", header = TRUE, sep = ",")


# Number of rows and column dataset
dim(dataset)


# Columns name
names(dataset)


# View the first few rows
head(dataset)


# View the structure of the dataset
str(dataset)


# Summary of dataset
summary(dataset)


# Total Missing Value
sum(is.na(dataset))


check_datatypes <- function(df) {
  sapply(df, class)
}

check_datatypes(dataset)


# Check if any numeric columns are actually character or factor:
numeric_issues <- sapply(dataset, function(col) {
  (is.character(col) || is.factor(col)) && all(suppressWarnings(!is.na(as.numeric(as.character(col)))))
})

which(numeric_issues)


potential_numeric <- sapply(dataset, function(x) {
  is.character(x) && all(!is.na(suppressWarnings(as.numeric(x))))
})
names(dataset)[potential_numeric]



invalid_bp <- !suppressWarnings(!is.na(as.numeric(as.character(dataset$BloodPressure))))
invalid_entries <- dataset$BloodPressure[invalid_bp]

unique(invalid_entries)

sum(invalid_bp)



dataset$BloodPressure <- as.numeric(dataset$BloodPressure)
dataset$Heart_Rate[dataset$Heart_Rate == "Low"] <- 0
dataset$Heart_Rate[dataset$Heart_Rate == "High"] <- 1
dataset$Heart_Rate[dataset$Heart_Rate == ""] <- NA



# Missing values per column
colSums(is.na(dataset))


missing_barplot <- function() {
  missing_counts <- colSums(is.na(dataset))
  barplot(missing_counts,
          main = "Missing Values per Column",
          ylab = "Number of Missing Values",
          xlab = "Columns",
          col = "skyblue",
          las = 2)
}

missing_barplot()


head(dataset)



# Outliers
detect_outliers <- function(column_name) {
  col_data <- dataset[[column_name]]
  
  Q1 <- quantile(col_data, 0.25, na.rm = TRUE)
  Q3 <- quantile(col_data, 0.75, na.rm = TRUE)
  IQR <- Q3 - Q1
  lower_bound <- Q1 - 1.5 * IQR
  upper_bound <- Q3 + 1.5 * IQR
  
  outliers <- col_data[col_data < lower_bound | col_data > upper_bound]
  return(outliers)
}


outlier_values <- detect_outliers("Age")
print(outlier_values)

outlier_values <- detect_outliers("Gender")
print(outlier_values)

outlier_values <- detect_outliers("BloodPressure")
print(outlier_values)



# Most Frequency 
impute_mode <- function(column_name) {
  mode_value <- names(sort(table(dataset[[column_name]]), decreasing = TRUE))[1]
  dataset[[column_name]][is.na(dataset[[column_name]])] <- mode_value
  return(dataset)
}


# Instant discard 
discard_na <- function(column_name) {
  dataset <- dataset[!is.na(dataset[[column_name]]), ]
  return(dataset)
}

# Median
impute_median <- function(column_name) {
  median_value <- median(dataset[[column_name]], na.rm = TRUE)
  dataset[[column_name]][is.na(dataset[[column_name]])] <- median_value
  return(dataset)
}

# Mean  
impute_mean <- function(column_name) {
  dataset[[column_name]] <- as.numeric(dataset[[column_name]])  # ensure numeric
  mean_value <- mean(dataset[[column_name]], na.rm = TRUE)
  dataset[[column_name]][is.na(dataset[[column_name]])] <- mean_value
  return(dataset)
}

dataset <- impute_mode("Gender")
dataset <- impute_median("Age")
dataset <- impute_mean("BloodPressure")
dataset <- discard_na("Heart_Rate")


dim(dataset)

sum(is.na(dataset))



unique_values <- unique(dataset$HeartDisease)
print(unique_values)

value_counts <- table(dataset$HeartDisease)
print(value_counts)


dataset %>% filter(!is.na(HeartDisease))



# Duplicate
sum(duplicated(dataset))  # Number of duplicate rows
dataset <- dataset %>% distinct()
dim(dataset)



# Filter: Age should be between 0 and 120
dataset <- dataset %>% filter(Age >= 0 & Age <= 120)
dim(dataset)




# Balance dataset (simple undersampling)
# Find the minority class count
min_count <- dataset %>%
  count(HeartDisease) %>%
  summarise(min_n = min(n)) %>%
  pull(min_n)

# Apply undersampling properly
balanced_dataset <- dataset %>%
  group_by(HeartDisease) %>%
  slice_sample(n = min_count) %>%
  ungroup()

# Confirm balance
table(balanced_dataset$HeartDisease)




#  Normalize a Continuous Attribute
# AGE
balanced_dataset <- balanced_dataset %>%
  mutate(Normalized_Age = (Age - min(Age)) / (max(Age) - min(Age)))

head(balanced_dataset)

# BloodPressure 
balanced_dataset <- balanced_dataset %>%
  mutate(Normalize_BloodPressure = (BloodPressure - min(BloodPressure))/(max(BloodPressure) - min(BloodPressure)))

head(balanced_dataset)

# Cholesterol
balanced_dataset <- balanced_dataset %>%
  mutate(Normalized_Cholesterol = (Cholesterol - min(Cholesterol))/(max(Cholesterol) - min(Cholesterol)))

head(balanced_dataset)



# Split Dataset
set.seed(123)
n <- nrow(balanced_dataset)
train_data <- sample(1:n, 0.7 * n)

train <- balanced_dataset[train_data, ]
test <- balanced_dataset[-train_data, ]


dim(train)
dim(test)





#  Central Tendencies of Age by Gender
balanced_dataset %>%
  group_by(Gender) %>%
  summarise(
    Mean_Age = mean(Age),
    Median_Age = median(Age),
    Mode_Age = as.numeric(names(sort(table(Age), decreasing = TRUE)[1]))
  )


# Central Tendencies of Age by Heart_Rate
balanced_dataset %>%
  group_by(Heart_Rate) %>%
  summarise(
    Mean_Age = mean(Age),
    Median_Age = median(Age),
    Mode_Age = as.numeric(names(sort(table(Age), decreasing = TRUE)[1]))
  )


# Spread of Age by Gender
balanced_dataset %>%
  group_by(Gender) %>%
  summarise(
    Range = max(Age) - min(Age),
    IQR = IQR(Age),
    Variance = var(Age),
    Std_Dev = sd(Age)
  )
