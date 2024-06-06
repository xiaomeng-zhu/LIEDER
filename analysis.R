library(tidyverse)
library(bootstrap)
library(lme4)
source("schuster_linzen_2022/analysis/helpers.R")

fill_cols = c(
  
  "#f9e076", # llama2 7B
  "#ca6702", # llama2 13B
  "#ae2012", # llama2 70B
  "#a4fba6", # llama3 8B
  "#0f9200", # llama3 70B
  "#add8e6", # babbage
  "#2986cc", # davinci
  "#000000"
)
col_scale = scale_fill_manual(values=fill_cols)

s_comp <- c("p(sg|neg_pos)>p(sg|neg_neg)", 
            "p(sg|pos_neg)>p(sg|neg_neg)",
            "p(sg|pos_neg)>p(sg|pos_pos)", 
            "p(sg|neg_pos)>p(sg|pos_pos)" )

s_distance_comp <- c("p(sg|neg_pos)>p(sg|pos_neg)")

p_comp <- c("p(pl|pos_pos)>p(pl|pos_neg)",
            "p(pl|pos_pos)>p(pl|neg_pos)",
            "p(pl|pos_pos)>p(pl|neg_neg)")

sp_comp <- c("p(sg|pos_neg)>p(pl|pos_neg)",
             "p(sg|neg_pos)>p(pl|neg_pos)",
             "p(pl|pos_pos)>p(sg|pos_pos)")

sp_comp_all <- c("p(sg|pos_neg)>p(pl|pos_neg)",
                 "p(sg|pos_neg)>p(pl|neg_pos)",
                 "p(sg|pos_neg)>p(pl|neg_neg)",
                 "p(sg|neg_pos)>p(pl|neg_pos)",
                 "p(sg|neg_pos)>p(pl|pos_neg)",
                 "p(sg|neg_pos)>p(pl|neg_neg)",
                 "p(pl|pos_pos)>p(sg|pos_pos)",
                 "p(pl|pos_pos)>p(sg|neg_neg)")

model_levels_original <- c("llama2-7B", "llama2-13B", "llama2-70B", "llama3-8B", "llama3-70B", "babbage-002", "davinci-002", "human")
model_levels <- c("Llama 2 7B", "Llama 2 13B", "Llama 2 70B", "Llama 3 8B", "Llama 3 70B", "babbage-002", "davinci-002", "Human")

base_vs_diff_level <- c("Implicit", "Explicit Novelty")
base_vs_two_level <- c("Implicit", "Explicit Plurality")

base_vs_diff_type <- c("p(sg|pos_neg)>p(sg|pos_pos)", 
                       "p(sg|neg_pos)>p(sg|pos_pos)")
base_vs_two_type <- c("p(sg|pos_neg)>p(sg|pos_pos)", 
                      "p(sg|pos_neg)>p(sg|two_neg)", 
                      "p(sg|neg_pos)>p(sg|pos_pos)",
                      "p(sg|neg_pos)>p(sg|neg_two)")

########################### DEFINE FUNCTIONS ##########################
analyze_model_res_an_only <- function(result_path, model_name, version) {
  d <- read_csv(result_path)
  d$model <- model_name
  d$version <- version
  d <- subset(d, sent_type=="affirmative_negation") # only looking at A_N sentences
  d <- d %>% 
    select(id, sent_type, type, correct, model, version) %>%
    mutate(type = case_when(type=="neg_pos_s>pos_neg_s" ~ "p(sg|neg_pos)>p(sg|pos_neg)",
                            type=="pos_neg_s>pos_pos_s" ~ "p(sg|pos_neg)>p(sg|pos_pos)",
                            type=="neg_pos_s>pos_pos_s" ~ "p(sg|neg_pos)>p(sg|pos_pos)",
                            type=="neg_pos_s>neg_neg_s" ~ "p(sg|neg_pos)>p(sg|neg_neg)",
                            type=="pos_neg_s>neg_neg_s" ~ "p(sg|pos_neg)>p(sg|neg_neg)",
                            type=="pos_pos_p>pos_neg_p" ~ "p(pl|pos_pos)>p(pl|pos_neg)",
                            type=="pos_pos_p>neg_pos_p" ~ "p(pl|pos_pos)>p(pl|neg_pos)",
                            type=="pos_pos_p>neg_neg_p" ~ "p(pl|pos_pos)>p(pl|neg_neg)",
                            type=="pos_neg_s>pos_neg_p" ~ "p(sg|pos_neg)>p(pl|pos_neg)",
                            type=="pos_neg_s>neg_pos_p" ~ "p(sg|pos_neg)>p(pl|neg_pos)",
                            type=="pos_neg_s>neg_neg_p" ~ "p(sg|pos_neg)>p(pl|neg_neg)",
                            type=="neg_pos_s>neg_pos_p" ~ "p(sg|neg_pos)>p(pl|neg_pos)",
                            type=="neg_pos_s>pos_neg_p" ~ "p(sg|neg_pos)>p(pl|pos_neg)",
                            type=="neg_pos_s>neg_neg_p" ~ "p(sg|neg_pos)>p(pl|neg_neg)",
                            type=="pos_pos_p>pos_pos_s" ~ "p(pl|pos_pos)>p(sg|pos_pos)",
                            type=="pos_pos_p>neg_neg_s" ~ "p(pl|pos_pos)>p(sg|neg_neg)",
                            type=="neg_pos_s>pos_neg_s" ~ "p(sg|neg_pos)>p(sg|pos_neg)",
                            type=="neg_pos_p>pos_neg_p" ~ "p(pl|neg_pos)>p(pl|pos_neg)"
    ))
  d <- d %>% mutate(model = case_when(model=="davinci-002" ~ "davinci-002",
                                      model=="babbage-002" ~ "babbage-002",
                                      model=="llama2-7B" ~ "Llama 2 7B",
                                      model=="llama2-13B" ~ "Llama 2 13B",
                                      model=="llama2-70B" ~ "Llama 2 70B",
                                      model=="llama3-8B" ~ "Llama 3 8B",
                                      model=="llama3-70B" ~ "Llama 3 70B",
                                      model=="human" ~ "Human"))
  return(d)
}


analyze_model_res <- function(result_path, model_name, version) {
  d <- read_csv(result_path)
  d$model <- model_name
  d$version <- version
  d <- d %>% 
    select(id, sent_type, type, correct, model, version) %>%
    mutate(sent_type = case_when(sent_type == "affirmative_negation" ~ "A_N",
                                 sent_type == "know_doubt" ~ "K_D",
                                 sent_type == "managed_failed" ~ "M_F")) %>%
    mutate(type = case_when(type=="neg_pos_s>pos_neg_s" ~ "p(sg|neg_pos)>p(sg|pos_neg)",
                            type=="pos_neg_s>pos_pos_s" ~ "p(sg|pos_neg)>p(sg|pos_pos)",
                            type=="neg_pos_s>pos_pos_s" ~ "p(sg|neg_pos)>p(sg|pos_pos)",
                            type=="neg_pos_s>neg_neg_s" ~ "p(sg|neg_pos)>p(sg|neg_neg)",
                            type=="pos_neg_s>neg_neg_s" ~ "p(sg|pos_neg)>p(sg|neg_neg)",
                            type=="pos_pos_p>pos_neg_p" ~ "p(pl|pos_pos)>p(pl|pos_neg)",
                            type=="pos_pos_p>neg_pos_p" ~ "p(pl|pos_pos)>p(pl|neg_pos)",
                            type=="pos_pos_p>neg_neg_p" ~ "p(pl|pos_pos)>p(pl|neg_neg)",
                            type=="pos_neg_s>pos_neg_p" ~ "p(sg|pos_neg)>p(pl|pos_neg)",
                            type=="pos_neg_s>neg_pos_p" ~ "p(sg|pos_neg)>p(pl|neg_pos)",
                            type=="pos_neg_s>neg_neg_p" ~ "p(sg|pos_neg)>p(pl|neg_neg)",
                            type=="neg_pos_s>neg_pos_p" ~ "p(sg|neg_pos)>p(pl|neg_pos)",
                            type=="neg_pos_s>pos_neg_p" ~ "p(sg|neg_pos)>p(pl|pos_neg)",
                            type=="neg_pos_s>neg_neg_p" ~ "p(sg|neg_pos)>p(pl|neg_neg)",
                            type=="pos_pos_p>pos_pos_s" ~ "p(pl|pos_pos)>p(sg|pos_pos)",
                            type=="pos_pos_p>neg_neg_s" ~ "p(pl|pos_pos)>p(sg|neg_neg)",
                            type=="neg_pos_s>pos_neg_s" ~ "p(sg|neg_pos)>p(sg|pos_neg)",
                            type=="neg_pos_p>pos_neg_p" ~ "p(pl|neg_pos)>p(pl|pos_neg)",
                            type=="pos_neg_s>two_neg_s" ~ "p(sg|pos_neg)>p(sg|two_neg)",
                            type=="pos_neg_s>neg_two_s" ~ "p(sg|pos_neg)>p(sg|neg_two)",
                            type=="neg_pos_s>two_neg_s" ~ "p(sg|neg_pos)>p(sg|two_neg)",
                            type=="neg_pos_s>neg_two_s" ~ "p(sg|neg_pos)>p(sg|neg_two)",
                            type=="two_neg_p>pos_neg_p" ~ "p(pl|two_neg)>p(pl|pos_neg)",
                            type=="two_neg_p>neg_pos_p" ~ "p(pl|two_neg)>p(pl|neg_pos)",
                            type=="neg_two_p>pos_neg_p" ~ "p(pl|neg_two)>p(pl|pos_neg)",
                            type=="neg_two_p>neg_pos_p" ~ "p(pl|neg_two)>p(pl|neg_pos)",
                            type=="two_neg_p>two_neg_s" ~ "p(pl|two_neg)>p(sg|two_neg)",
                            type=="two_neg_p>neg_two_s" ~ "p(pl|two_neg)>p(sg|neg_two)",
                            type=="neg_two_p>two_neg_s" ~ "p(pl|neg_two)>p(sg|two_neg)",
                            type=="neg_two_p>neg_two_s" ~ "p(pl|neg_two)>p(sg|neg_two)",
                            type=="two_neg_p>pos_pos_s" ~ "p(pl|two_neg)>p(sg|pos_pos)",
                            type=="neg_two_p>pos_pos_s" ~ "p(pl|neg_two)>p(sg|pos_pos)",
                            type=="pos_pos_p>two_neg_s" ~ "p(pl|pos_pos)>p(sg|two_neg)",
                            type=="pos_pos_p>neg_two_s" ~ "p(pl|pos_pos)>p(sg|neg_two)"
    ))
  d <- d %>% mutate(model = case_when(model=="davinci-002" ~ "davinci-002",
                                      model=="babbage-002" ~ "babbage-002",
                                      model=="llama2-7B" ~ "Llama 2 7B",
                                      model=="llama2-13B" ~ "Llama 2 13B",
                                      model=="llama2-70B" ~ "Llama 2 70B",
                                      model=="llama3-8B" ~ "Llama 3 8B",
                                      model=="llama3-70B" ~ "Llama 3 70B",
                                      model=="human" ~ "Human"))
  return(d)
}


plot_comparisons_an <- function(df, comp_levels, model_levels, ncol, nrow_legend) {
  df <- df %>% subset(type %in% comp_levels) %>% 
    mutate(type=factor(type,
                       levels=comp_levels)) %>% 
    mutate(model = factor(model,
                          levels = model_levels))
  plot <- df %>% group_by(model, type) %>% 
    summarize(accuracy=mean(correct), ci_low = ci.low(correct), ci_high = ci.high(correct)) %>%
    ggplot(aes(x=model, fill=model, y=accuracy)) + 
    geom_bar(stat="identity", alpha=0.8, position=position_dodge()) + 
    ylim(0,1) + 
    xlab("Comparison Type") + 
    ylab("% expected") + 
    facet_wrap(~type, ncol=ncol) +
    geom_hline(yintercept = 0.5, color="#666666", lty=2) + 
    geom_errorbar(aes(ymin=accuracy - ci_low, ymax=accuracy + ci_high), 
                  width = 0.4, 
                  col="#666666", 
                  position=position_dodge(width=1)) +
    theme(legend.position="bottom", axis.title.x = element_blank(),
          axis.text.x = element_blank(),
          legend.text = element_text(size=10),
          axis.ticks.x = element_blank(),
          legend.key.size = unit(0.3, 'cm')) + guides(fill = guide_legend(nrow = nrow_legend, byrow=TRUE)) + col_scale
  
  return (plot)
  
}


plot_singular_comparisons_across_version_an <- function(df) {
  df_singular <- df %>% subset(type %in% c("p(sg|pos_neg)>p(sg|pos_pos)", 
                                           "p(sg|neg_pos)>p(sg|pos_pos)")) %>% 
    mutate(type = factor(type, 
                         levels = c("p(sg|pos_neg)>p(sg|pos_pos)", 
                                    "p(sg|neg_pos)>p(sg|pos_pos)"))) %>% 
    mutate(model = factor(model,
                          levels = model_levels)) %>%
    mutate(version = factor(version,
                            levels = base_vs_diff_level))
  plot <- df_singular %>% group_by(model, type, version) %>% 
    summarize(accuracy=mean(correct), ci_low = ci.low(correct), ci_high = ci.high(correct)) %>%
    ggplot(aes(x=model, fill=model, y=accuracy)) + 
    geom_bar(stat="identity", alpha=0.8, position=position_dodge()) + 
    ylim(0,1) + 
    xlab("Sentence Type") + 
    ylab("% expected") + 
    facet_wrap(~type+version, ncol = 4) + 
    geom_hline(yintercept = 0.5, color="#666666", lty=2) + 
    geom_errorbar(aes(ymin=accuracy - ci_low, ymax=accuracy + ci_high), 
                  width = 0.4, 
                  col="#666666", 
                  position=position_dodge(width=1)) +
    theme(legend.position="bottom", 
          axis.title.x = element_blank(),
          axis.text.x = element_blank(),
          axis.ticks.x = element_blank(),
          legend.text = element_text(size=10),
          legend.key.size = unit(0.3, 'cm')) + guides(fill = guide_legend(nrow = 2, byrow=TRUE)) + 
    col_scale 
    
  
  return (plot)
  
}

########################### LOAD DATA ##########################

base.davinci.an <- analyze_model_res_an_only("results/base/base_davinci-002_accuracy_ref.csv","davinci-002", "Implicit")
base.babbage.an <- analyze_model_res_an_only("results/base/base_babbage-002_accuracy_ref.csv","babbage-002", "Implicit")
base.llama2.7.an <- analyze_model_res_an_only("results/base/base_llama2_7B_accuracy_ref.csv", "llama2-7B", "Implicit")
base.llama2.13.an <- analyze_model_res_an_only("results/base/base_llama2_13B_accuracy_ref.csv", "llama2-13B", "Implicit")
base.llama2.70.an <- analyze_model_res_an_only("results/base/base_llama2_70B_accuracy_ref.csv", "llama2-70B", "Implicit")
base.llama3.8.an <- analyze_model_res_an_only("results/base/base_llama3_8B_accuracy_ref.csv", "llama3-8B", "Implicit")
base.llama3.70.an <- analyze_model_res_an_only("results/base/base_llama3_70B_accuracy_ref.csv", "llama3-70B", "Implicit")

human.an <- analyze_model_res_an_only("human/human_accuracy.csv", "human", "Implicit")

diff.davinci.an <- analyze_model_res_an_only("results/diff/diff_davinci-002_accuracy_ref.csv","davinci-002", "Explicit Novelty")
diff.babbage.an <- analyze_model_res_an_only("results/diff/diff_babbage-002_accuracy_ref.csv","babbage-002", "Explicit Novelty")
diff.llama2.7.an <- analyze_model_res_an_only("results/diff/diff_llama2_7B_accuracy_ref.csv", "llama2-7B", "Explicit Novelty")
diff.llama2.13.an <- analyze_model_res_an_only("results/diff/diff_llama2_13B_accuracy_ref.csv", "llama2-13B", "Explicit Novelty")
diff.llama2.70.an <- analyze_model_res_an_only("results/diff/diff_llama2_70B_accuracy_ref.csv", "llama2-70B", "Explicit Novelty")
diff.llama3.8.an <- analyze_model_res_an_only("results/diff/diff_llama3_8B_accuracy_ref.csv", "llama3-8B", "Explicit Novelty")
diff.llama3.70.an <- analyze_model_res_an_only("results/diff/diff_llama3_70B_accuracy_ref.csv", "llama3-70B", "Explicit Novelty")

model.bases.an <- rbind(
  base.davinci.an,
  base.babbage.an,
  base.llama2.7.an,
  base.llama2.13.an,
  base.llama2.70.an,
  base.llama3.8.an,
  base.llama3.70.an
)

model.diffs.an <- rbind(
  diff.davinci.an,
  diff.babbage.an,
  diff.llama2.7.an,
  diff.llama2.13.an,
  diff.llama2.70.an,
  diff.llama3.8.an,
  diff.llama3.70.an
)

model.an <- rbind(model.bases.an, model.diffs.an) # all model results for base and diff
baselines.an <- rbind(model.bases.an, human.an)

base.singular.an <- plot_comparisons_an(baselines.an, s_comp, model_levels, 4, 2)
base.plural.an <- plot_comparisons_an(baselines.an, p_comp, model_levels, 3, 2)
base.sp.an <- plot_comparisons_an(baselines.an, sp_comp, model_levels, 3, 2)
base.singular.distance.an <- plot_comparisons_an(baselines.an, s_distance_comp, model_levels, 1, 2)
base.vs.diff.singular.an <- plot_singular_comparisons_across_version_an(model.an)

# remove comment to save to dir
# ggsave("plots/exp1_singular.pdf", base.singular.an, width=8, height = 2, dpi=300)
# ggsave("plots/exp1_plural.pdf", base.plural.an, width=8, height = 2, dpi=300)
# ggsave("plots/exp1_sp.pdf", base.sp.an, width=8, height = 2, dpi=300)
# ggsave("plots/exp1_singular_distance.pdf", base.singular.distance.an, width=6, height = 3, dpi=300)
# ggsave("plots/exp2_singular_vs_exp1.pdf", base.vs.diff.singular.an, width=8, height = 2, dpi=300)

############################ SIGNIFICANCE TESTING ############################
model.an.subset <- subset(model.an, 
                                          type=="p(sg|pos_neg)>p(sg|pos_pos)"|type=="p(sg|neg_pos)>p(sg|pos_pos)") %>% 
  mutate(version=factor(version,
                        levels=base_vs_diff_level))

library(lme4)
glm.model<- glmer(correct ~ version+type + (1|id), data = model.an.subset, family = "binomial")
summary(glm.model)

################################## APPENDIX ##################################

#================ PLOTS FOR ALL THREE SENTTYPE ===============
plot_comparisons <- function(df, comp_levels, model_levels, ncol, nrow_legend) {
  df <- df %>% subset(type %in% comp_levels) %>% 
    mutate(type=factor(type,
                       levels=comp_levels)) %>% 
    mutate(model = factor(model,
                          levels = model_levels))
  plot <- df %>% 
    group_by(model, type, sent_type) %>% 
    summarize(accuracy=mean(correct), ci_low = ci.low(correct), ci_high = ci.high(correct)) %>%
    ggplot(aes(x=sent_type, fill=model, y=accuracy)) + 
    geom_bar(stat="identity", alpha=0.8, position=position_dodge()) + 
    ylim(0,1) + 
    xlab("Comparison Type") + 
    ylab("% expected") + 
    facet_wrap(~type, ncol=ncol) +
    geom_hline(yintercept = 0.5, color="#666666", lty=2) + 
    geom_errorbar(aes(ymin=accuracy - ci_low, ymax=accuracy + ci_high), 
                  width = 0.4, 
                  col="#666666", 
                  position=position_dodge(width=0.9)) +
    theme(legend.position="bottom", axis.title.x = element_blank(),
          # axis.text.x = element_blank(),
          legend.text = element_text(size=10),
          # axis.ticks.x = element_blank(),
          legend.key.size = unit(0.3, 'cm')) + guides(fill = guide_legend(nrow = nrow_legend, byrow=TRUE)) + col_scale
  
  return (plot)
  
}

plot_singular_comparisons_across_version <-  function(df, version_level, types_to_compare) {
  df_singular <- df %>% subset(type %in% types_to_compare) %>% 
    mutate(type = factor(type, 
                         levels = types_to_compare)) %>% 
    mutate(model = factor(model,
                          levels = model_levels)) %>%
    mutate(version = factor(version,
                            levels = version_level))
  plot <- df_singular %>% group_by(model, sent_type, type, version) %>% 
    summarize(accuracy=mean(correct), ci_low = ci.low(correct), ci_high = ci.high(correct)) %>%
    ggplot(aes(x=sent_type, fill=model, y=accuracy)) + 
    geom_bar(stat="identity", alpha=0.8, position=position_dodge()) + 
    ylim(0,1) + 
    xlab("Sentence Type") + 
    ylab("% expected") + 
    facet_wrap(~type+version, ncol = 4) + 
    geom_hline(yintercept = 0.5, color="#666666", lty=2) + 
    geom_errorbar(aes(ymin=accuracy - ci_low, ymax=accuracy + ci_high), 
                  width = 0.4, 
                  col="#666666", 
                  position=position_dodge(width=0.9)) +
    theme(legend.position="bottom", 
          axis.title.x = element_blank(),
          # axis.text.x = element_blank(),
          # axis.ticks.x = element_blank(),
          legend.text = element_text(size=10),
          legend.key.size = unit(0.3, 'cm')) + guides(fill = guide_legend(nrow = 2, byrow=TRUE)) + 
    col_scale 
  
  
  return (plot)
  
}

base.babbage <- analyze_model_res("results/base/base_babbage-002_accuracy_ref.csv", "babbage-002", "Implicit")
base.davinci <- analyze_model_res("results/base/base_davinci-002_accuracy_ref.csv","davinci-002", "Implicit")
base.llama2.7 <- analyze_model_res("results/base/base_llama2_7B_accuracy_ref.csv", "llama2-7B", "Implicit")
base.llama2.13 <- analyze_model_res("results/base/base_llama2_13B_accuracy_ref.csv", "llama2-13B", "Implicit")
base.llama2.70 <- analyze_model_res("results/base/base_llama2_70B_accuracy_ref.csv", "llama2-70B", "Implicit")
base.llama3.8 <- analyze_model_res("results/base/base_llama3_8B_accuracy_ref.csv", "llama3-8B", "Implicit")
base.llama3.70 <- analyze_model_res("results/base/base_llama3_70B_accuracy_ref.csv", "llama3-70B", "Implicit")

human <- analyze_model_res("human/human_accuracy.csv", "human", "Implicit")

diff.babbage <- analyze_model_res("results/diff/diff_babbage-002_accuracy_ref.csv", "babbage-002", "Explicit Novelty")
diff.davinci <- analyze_model_res("results/diff/diff_davinci-002_accuracy_ref.csv","davinci-002", "Explicit Novelty")
diff.llama2.7 <- analyze_model_res("results/diff/diff_llama2_7B_accuracy_ref.csv", "llama2-7B", "Explicit Novelty")
diff.llama2.13 <- analyze_model_res("results/diff/diff_llama2_13B_accuracy_ref.csv", "llama2-13B", "Explicit Novelty")
diff.llama2.70 <- analyze_model_res("results/diff/diff_llama2_70B_accuracy_ref.csv", "llama2-70B", "Explicit Novelty")
diff.llama3.8 <- analyze_model_res("results/diff/diff_llama3_8B_accuracy_ref.csv", "llama3-8B", "Explicit Novelty")
diff.llama3.70 <- analyze_model_res("results/diff/diff_llama3_70B_accuracy_ref.csv", "llama3-70B", "Explicit Novelty")

model.bases <- rbind(
  base.babbage,
  base.davinci,
  base.llama2.7,
  base.llama2.13,
  base.llama2.70,
  base.llama3.8,
  base.llama3.70
)

model.diffs <- rbind(
  diff.babbage,
  diff.davinci,
  diff.llama2.7,
  diff.llama2.13,
  diff.llama2.70,
  diff.llama3.8,
  diff.llama3.70
)

model.base.vs.diff <- rbind(model.bases, model.diffs)
baselines <- rbind(model.bases, human)

base.singular <- plot_comparisons(baselines, s_comp, model_levels, 4, 1)
base.plural <- plot_comparisons(baselines, p_comp, model_levels, 3, 1)
base.sp <- plot_comparisons(baselines, sp_comp_all, model_levels, 3, 1)
base.singular.distance <- plot_comparisons(baselines, s_distance_comp, model_levels, 1, 3)

diff.singular <- plot_comparisons(model.diffs, s_comp, model_levels, 4, 1)
diff.plural <- plot_comparisons(model.diffs, p_comp, model_levels, 3, 1)
diff.sp <- plot_comparisons(model.diffs, sp_comp, model_levels, 3, 1)
diff.singular.distance <- plot_comparisons(model.diffs, s_distance_comp, model_levels, 1, 3)
base.vs.diff.singular <- plot_singular_comparisons_across_version(model.base.vs.diff, base_vs_diff_level, base_vs_diff_type)

# # save plots
# ggsave("plots/exp1_singular_alltype.pdf", base.singular, width=10, height = 3, dpi=300)
# ggsave("plots/exp1_plural_alltype.pdf", base.plural, width=10, height = 3, dpi=300)
# ggsave("plots/exp1_sp_alltype.pdf", base.sp, width=10, height = 5, dpi=300)
# ggsave("plots/exp1_singular_distance_alltype.pdf", base.singular.distance, width=4.5, height = 3, dpi=300)
# # 
# ggsave("plots/exp2_singular_alltype.pdf", diff.singular, width=10, height = 3, dpi=300)
# ggsave("plots/exp2_plural_alltype.pdf", diff.plural, width=10, height = 3, dpi=300)
# ggsave("plots/exp2_sp_alltype.pdf", diff.sp, width=10, height = 3, dpi=300)
# ggsave("plots/exp2_singular_distance_alltype.pdf", diff.singular.distance, width=4.5, height = 3, dpi=300)
# 
# ggsave("plots/exp2_singular_vs_exp1_alltype.pdf", base.vs.diff.singular, width=10, height=3, dpi=300)

# significance testing
model.base.vs.diff.subset <- subset(model.base.vs.diff, 
                          type=="p(sg|pos_neg)>p(sg|pos_pos)"|type=="p(sg|neg_pos)>p(sg|pos_pos)") %>% 
  mutate(version=factor(version,
                        levels=base_vs_diff_level))

library(lme4)
glm.model.alltype.base.vs.diff <- glmer(correct ~ version+type + (1|id), data = model.base.vs.diff.subset, family = "binomial")
summary(glm.model.alltype.base.vs.diff)

#================ VERSION: TWO ================
two.babbage <- analyze_model_res("results/two/two_babbage-002_accuracy_ref.csv", "babbage-002", "Implicit")
two.davinci <- analyze_model_res("results/two/two_davinci-002_accuracy_ref.csv","davinci-002", "Implicit")
two.llama2.7 <- analyze_model_res("results/two/two_llama2_7B_accuracy_ref.csv", "llama2-7B", "Implicit")
two.llama2.13 <- analyze_model_res("results/two/two_llama2_13B_accuracy_ref.csv", "llama2-13B", "Implicit")
two.llama2.70 <- analyze_model_res("results/two/two_llama2_70B_accuracy_ref.csv", "llama2-70B", "Implicit")
two.llama3.8 <- analyze_model_res("results/two/two_llama3_8B_accuracy_ref.csv", "llama3-8B", "Implicit")
two.llama3.70 <- analyze_model_res("results/two/two_llama3_70B_accuracy_ref.csv", "llama3-70B", "Implicit")

model.twos <- rbind(
  two.babbage,
  two.davinci,
  two.llama2.7,
  two.llama2.13,
  two.llama2.70,
  two.llama3.8,
  two.llama3.70
  )

# fix model version
model.twos$version <- ifelse(grepl("two", model.twos$type), "Explicit Plurality", "Implicit")
base.vs.two.singular <- plot_singular_comparisons_across_version(model.twos, base_vs_two_level, base_vs_two_type)
# ggsave("plots/exp3_singular_vs_exp1_alltype.pdf", base.vs.two.singular, width=10, height=3, dpi=300)



#================ METRIC: NONREF ==============
nonref.base.babbage <- analyze_model_res("results/base/base_babbage-002_accuracy_nonref.csv", "babbage-002", "Implicit")
nonref.base.davinci <- analyze_model_res("results/base/base_davinci-002_accuracy_nonref.csv","davinci-002", "Implicit")
nonref.base.llama2.7 <- analyze_model_res("results/base/base_llama2_7B_accuracy_nonref.csv", "llama2-7B", "Implicit")
nonref.base.llama2.13 <- analyze_model_res("results/base/base_llama2_13B_accuracy_nonref.csv", "llama2-13B", "Implicit")
nonref.base.llama2.70 <- analyze_model_res("results/base/base_llama2_70B_accuracy_nonref.csv", "llama2-70B", "Implicit")
nonref.base.llama3.8 <- analyze_model_res("results/base/base_llama3_8B_accuracy_nonref.csv", "llama3-8B", "Implicit")
nonref.base.llama3.70 <- analyze_model_res("results/base/base_llama3_70B_accuracy_nonref.csv", "llama3-70B", "Implicit")

nonref.bases <- rbind(nonref.base.babbage,
                      nonref.base.davinci,
                      nonref.base.llama2.7,
                      nonref.base.llama2.13,
                      nonref.base.llama2.70,
                      nonref.base.llama3.8,
                      nonref.base.llama3.70)

nonref.base.singular <- plot_comparisons(nonref.bases, s_comp, model_levels, 4, 1)
nonref.base.plural <- plot_comparisons(nonref.bases, p_comp, model_levels, 3, 1)
nonref.base.sp <- plot_comparisons(nonref.bases, sp_comp, model_levels, 3, 1)

# ggsave("plots/nonref_exp1_singular_alltype.pdf", base.singular, width=10, height = 3, dpi=300)
# ggsave("plots/nonref_exp1_plural_alltype.pdf", base.plural, width=10, height = 3, dpi=300)
# ggsave("plots/nonref_exp1_sp_alltype.pdf", nonref.base.sp, width=10, height = 3, dpi=300)
