# ---- Clear environment ----
rm(list = ls())

# ---- Libraries ----
library(tidyverse)
library(infer)

# ---- Paths ----
data_path <- "/Users/caliboi/Desktop/Resumes/Github/Project 1/transactions_sample.csv"
base_dir  <- dirname(data_path)                       # same folder as the CSV
out_dir   <- file.path(base_dir, "dashboards")        # dashboards subfolder
dir.create(out_dir, showWarnings = FALSE)             # create if missing

# ---- Load data ----
data <- read_csv(data_path)
cat("✅ Data loaded. Rows:", nrow(data), "Columns:", ncol(data), "\n")

# ---- Summary ----
summary <- data %>%
  group_by(variant) %>%
  summarise(conversion_rate = mean(converted), n = n())

print(summary)

# ---- Inference test ----
data <- data %>%
  dplyr::mutate(converted = factor(converted))

ab_test <- data %>%
  specify(converted ~ variant, success = "1") %>%
  hypothesize(null = "independence") %>%
  generate(reps = 1000, type = "permute") %>%
  calculate(stat = "diff in props", order = c("variant", "control"))

# Observed stat
obs_stat <- data %>%
  specify(converted ~ variant, success = "1") %>%
  calculate(stat = "diff in props", order = c("variant", "control"))

# p-value
p_val <- ab_test %>%
  get_p_value(obs_stat = obs_stat, direction = "two-sided")

cat("✅ P-value for test:", round(p_val$p_value, 4), "\n")

# ---- Bootstrap CI for difference ----
bootstrap_ci <- data %>%
  specify(converted ~ variant, success = "1") %>%
  generate(reps = 1000, type = "bootstrap") %>%
  calculate(stat = "diff in props", order = c("variant", "control")) %>%
  get_confidence_interval(level = 0.95, type = "percentile")

cat("✅ Bootstrap 95% CI:", round(bootstrap_ci$lower_ci, 4), "to", round(bootstrap_ci$upper_ci, 4), "\n")

# ---- 📊 Visual 1: Conversion Rates ----
p1 <- summary %>%
  ggplot(aes(x = variant, y = conversion_rate, fill = variant)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = scales::percent(conversion_rate, accuracy = 0.1)),
            vjust = -0.5, size = 5) +
  scale_y_continuous(labels = scales::percent) +
  labs(title = "Conversion Rate by Variant",
       y = "Conversion Rate", x = "Variant") +
  theme_minimal()

ggsave(file.path(out_dir, "conversion_rate_comparison.png"), p1,
       width = 7, height = 5, dpi = 300, bg = "white")

print(p1)

# ---- 📊 Visual 2: A/B Test Distribution + CI ----
p2 <- ab_test %>%
  visualize() +
  shade_p_value(obs_stat = obs_stat, direction = "two-sided") +
  # Add bootstrap CI shading
  geom_vline(xintercept = bootstrap_ci$lower_ci, color = "darkgreen", linetype = "dashed", linewidth = 1) +
  geom_vline(xintercept = bootstrap_ci$upper_ci, color = "darkgreen", linetype = "dashed", linewidth = 1) +
  annotate("text", x = bootstrap_ci$lower_ci, y = Inf, label = "95% CI lower",
           vjust = -0.5, hjust = 0, color = "darkgreen", size = 3) +
  annotate("text", x = bootstrap_ci$upper_ci, y = Inf, label = "95% CI upper",
           vjust = -0.5, hjust = 1, color = "darkgreen", size = 3) +
  labs(title = "A/B Test Conversion Difference (Permutation Distribution)",
       x = "Difference in Conversion Rates",
       y = "Frequency") +
  theme_minimal()

ggsave(file.path(out_dir, "ab_test_distribution.png"), p2,
       width = 7, height = 5, dpi = 300, bg = "white")
print(p2)

# ---- 📊 Visual 3: Sample Size by Variant ----
p3 <- summary %>%
  ggplot(aes(x = variant, y = n, fill = variant)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = n), vjust = -0.5, size = 5) +
  labs(title = "Sample Size per Variant",
       y = "Number of Transactions", x = "Variant") +
  theme_minimal()

ggsave(file.path(out_dir, "sample_size_comparison.png"), p3,
       width = 7, height = 5, dpi = 300, bg = "white")
print(p3)

# ---- 📊 Visual 4: Density of Permutation Differences ----
p4 <- ggplot(as.data.frame(ab_test), aes(x = stat)) +
  geom_histogram(aes(y = ..density..), bins = 30, fill = "steelblue", alpha = 0.7) +
  geom_density(color = "darkred", size = 1) +
  geom_vline(xintercept = obs_stat$stat, color = "black", linetype = "dashed") +
  geom_vline(xintercept = c(bootstrap_ci$lower_ci, bootstrap_ci$upper_ci),
             color = "darkgreen", linetype = "dashed") +
  labs(title = "Distribution of Simulated Differences (Permutation Test)",
       x = "Difference in Conversion Rates", y = "Density") +
  theme_minimal()

ggsave(file.path(out_dir, "ab_test_density.png"), p4,
       width = 7, height = 5, dpi = 300, bg = "white")
print(p4)

# ---- 📄 Save structured summary report ----
report_path <- file.path(out_dir, "ab_test_summary.txt")

summary_txt <- paste0(
  "🔎 A/B Test Analysis Summary\n",
  "------------------------------------\n",
  "Sample Size: ", nrow(data), " transactions\n\n",
  "Conversion Rates by Variant:\n",
  paste0(summary$variant, ": ", round(summary$conversion_rate*100, 2), "% (n=", summary$n, ")\n", collapse=""),
  "\n",
  "Observed Difference in Conversion Rates: ", round(obs_stat$stat, 4), "\n",
  "P-Value (two-sided): ", round(p_val$p_value, 4), "\n",
  "95% Bootstrap CI for Difference: [", round(bootstrap_ci$lower_ci, 4),
  ", ", round(bootstrap_ci$upper_ci, 4), "]\n"
)

writeLines(summary_txt, report_path)
cat("📄 Saved summary report →", report_path, "\n")

cat("✅ All A/B testing dashboard outputs saved in:", out_dir, "\n")
