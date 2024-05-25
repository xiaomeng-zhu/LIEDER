library(tidyverse)

base_babbage_summed <- read_csv('results/base/base_babbage-002_summed.csv') %>%
  group_by(type) %>%
  summarize(mean = mean(continuation_prob))
