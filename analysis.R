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

model_levels_original <- c("llama2-7B", "llama2-13B", "llama2-70B", "llama3-8B", "llama3-70B", "davinci-002", "human")
model_levels <- c("Llama 2 7B", "Llama 2 13B", "Llama 2 70B", "Llama 3 8B", "Llama 3 70B", "davinci-002", "Human")

########################### DEFINE FUNCTIONS ##########################
analyze_model_res_an_only <- function(result_path, model_name, version) {
  d <- read_csv(result_path)
  d$model <- model_name
  d$version <- version
  d <- subset(d, sent_type=="affirmative_negation")
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
                            type=="neg_pos_p>pos_neg_p" ~ "p(pl|neg_pos)>p(pl|pos_neg)"
    ))
  d <- d %>% mutate(model = case_when(model=="davinci-002" ~ "davinci-002",
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
                            levels = c("Implicit", "Explicit")))
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
          legend.key.size = unit(0.3, 'cm')) + guides(fill = guide_legend(nrow = 1)) + 
    col_scale 
    
  
  return (plot)
  
}

########################### LOAD DATA ##########################

base.davinci.an <- analyze_model_res_an_only("results/base/base_davinci-002_accuracy_ref.csv","davinci-002", "Implicit")
base.llama2.7.an <- analyze_model_res_an_only("results/base/base_llama2_7B_accuracy_ref.csv", "llama2-7B", "Implicit")
base.llama2.13.an <- analyze_model_res_an_only("results/base/base_llama2_13B_accuracy_ref.csv", "llama2-13B", "Implicit")
base.llama2.70.an <- analyze_model_res_an_only("results/base/base_llama2_70B_accuracy_ref.csv", "llama2-70B", "Implicit")
base.llama3.8.an <- analyze_model_res_an_only("results/base/base_llama3_8B_accuracy_ref.csv", "llama3-8B", "Implicit")
base.llama3.70.an <- analyze_model_res_an_only("results/base/base_llama3_70B_accuracy_ref.csv", "llama3-70B", "Implicit")

human.an <- analyze_model_res_an_only("human/human_accuracy.csv", "human", "Implicit")

diff.davinci.an <- analyze_model_res_an_only("results/diff/diff_davinci-002_accuracy_ref.csv","davinci-002", "Explicit")
diff.llama2.7.an <- analyze_model_res_an_only("results/diff/diff_llama2_7B_accuracy_ref.csv", "llama2-7B", "Explicit")
diff.llama2.13.an <- analyze_model_res_an_only("results/diff/diff_llama2_13B_accuracy_ref.csv", "llama2-13B", "Explicit")
diff.llama2.70.an <- analyze_model_res_an_only("results/diff/diff_llama2_70B_accuracy_ref.csv", "llama2-70B", "Explicit")
diff.llama3.8.an <- analyze_model_res_an_only("results/diff/diff_llama3_8B_accuracy_ref.csv", "llama3-8B", "Explicit")
diff.llama3.70.an <- analyze_model_res_an_only("results/diff/diff_llama3_70B_accuracy_ref.csv", "llama3-70B", "Explicit")

model.bases.an <- rbind(
  base.davinci.an,
  base.llama2.7.an,
  base.llama2.13.an,
  base.llama2.70.an,
  base.llama3.8.an,
  base.llama3.70.an
)

model.diffs.an <- rbind(
  diff.davinci.an,
  diff.llama2.7.an,
  diff.llama2.13.an,
  diff.llama2.70.an,
  diff.llama3.8.an,
  diff.llama3.70.an
)

model.an <- rbind(model.bases.an, model.diffs.an)
baselines.an <- rbind(model.bases.an, human.an)

base.singular.an <- plot_comparisons_an(baselines.an, s_comp, model_levels, 4, 1)
base.plural.an <- plot_comparisons_an(baselines.an, p_comp, model_levels, 3, 1)
base.sp.an <- plot_comparisons_an(baselines.an, sp_comp, model_levels, 3, 1)
base.singular.distance.an <- plot_comparisons_an(baselines.an, s_distance_comp, model_levels, 1, 3)
base.vs.diff.singular.an <- plot_singular_comparisons_across_version_an(model.an)

# save plots
# ggsave("plots/exp1_singular.pdf", base.singular.an, width=8, height = 2, dpi=300)
# ggsave("plots/exp1_plural.pdf", base.plural.an, width=8, height = 2, dpi=300)
# ggsave("plots/exp1_sp.pdf", base.sp.an, width=8, height = 2, dpi=300)
# ggsave("plots/exp1_singular_distance.pdf", base.singular.distance.an, width=4.5, height = 3, dpi=300)
# ggsave("plots/exp2_singular.pdf", base.vs.diff.singular.an, width=8, height = 2, dpi=300)

############################ SIGNIFICANCE TESTING ##########################
model.an.subset <- subset(model.an, 
                                          type=="p(sg|pos_neg)>p(sg|pos_pos)"|type=="p(sg|neg_pos)>p(sg|pos_pos)") %>% 
  mutate(version=factor(version,
                        levels=c("Implicit", "Explicit")))

library(lme4)
glm.model<- glmer(correct ~ version+type + (1|id), data = model.an.subset, family = "binomial")
summary(glm.model)

############################ APPENDIX ###########################

#================ ALL SENTTYPE ===============
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
                  position=position_dodge(width=1)) +
    theme(legend.position="bottom", axis.title.x = element_blank(),
          # axis.text.x = element_blank(),
          legend.text = element_text(size=10),
          # axis.ticks.x = element_blank(),
          legend.key.size = unit(0.3, 'cm')) + guides(fill = guide_legend(nrow = nrow_legend, byrow=TRUE)) + col_scale
  
  return (plot)
  
}

base.davinci <- analyze_model_res("results/base/base_davinci-002_accuracy_ref.csv","davinci-002", "Implicit")
base.llama2.7 <- analyze_model_res("results/base/base_llama2_7B_accuracy_ref.csv", "llama2-7B", "Implicit")
base.llama2.13 <- analyze_model_res("results/base/base_llama2_13B_accuracy_ref.csv", "llama2-13B", "Implicit")
base.llama2.70 <- analyze_model_res("results/base/base_llama2_70B_accuracy_ref.csv", "llama2-70B", "Implicit")
base.llama3.8 <- analyze_model_res("results/base/base_llama3_8B_accuracy_ref.csv", "llama3-8B", "Implicit")
base.llama3.70 <- analyze_model_res("results/base/base_llama3_70B_accuracy_ref.csv", "llama3-70B", "Implicit")

human <- analyze_model_res("human/human_accuracy.csv", "human", "Implicit")

diff.davinci <- analyze_model_res("results/diff/diff_davinci-002_accuracy_ref.csv","davinci-002", "Explicit")
diff.llama2.7 <- analyze_model_res("results/diff/diff_llama2_7B_accuracy_ref.csv", "llama2-7B", "Explicit")
diff.llama2.13 <- analyze_model_res("results/diff/diff_llama2_13B_accuracy_ref.csv", "llama2-13B", "Explicit")
diff.llama2.70 <- analyze_model_res("results/diff/diff_llama2_70B_accuracy_ref.csv", "llama2-70B", "Explicit")
diff.llama3.8 <- analyze_model_res("results/diff/diff_llama3_8B_accuracy_ref.csv", "llama3-8B", "Explicit")
diff.llama3.70 <- analyze_model_res("results/diff/diff_llama3_70B_accuracy_ref.csv", "llama3-70B", "Explicit")

model.bases <- rbind(
  base.davinci,
  base.llama2.7,
  base.llama2.13,
  base.llama2.70,
  base.llama3.8,
  base.llama3.70
)

model.diffs <- rbind(
  diff.davinci,
  diff.llama2.7,
  diff.llama2.13,
  diff.llama2.70,
  diff.llama3.8,
  diff.llama3.70
)

model <- rbind(model.bases, model.diffs)
baselines <- rbind(model.bases, human)

base.singular <- plot_comparisons(baselines, s_comp, model_levels, 4, 1)
base.plural <- plot_comparisons(baselines, p_comp, model_levels, 3, 1)
base.sp <- plot_comparisons(baselines, sp_comp, model_levels, 3, 1)
base.singular.distance <- plot_comparisons(baselines, s_distance_comp, model_levels, 1, 3)

diff.singular <- plot_comparisons(model.diffs, s_comp, model_levels, 4, 1)
diff.plural <- plot_comparisons(model.diffs, p_comp, model_levels, 3, 1)
diff.sp <- plot_comparisons(model.diffs, sp_comp, model_levels, 3, 1)
diff.singular.distance <- plot_comparisons(baselines, s_distance_comp, model_levels, 1, 3)

# # save plots
# ggsave("plots/exp1_singular_alltype.pdf", base.singular, width=8, height = 2, dpi=300)
# ggsave("plots/exp1_plural_alltype.pdf", base.plural, width=8, height = 2, dpi=300)
# ggsave("plots/exp1_sp_alltype.pdf", base.sp, width=8, height = 2, dpi=300)
# ggsave("plots/exp1_singular_distance_alltype.pdf", base.singular.distance, width=4.5, height = 3, dpi=300)
# 
# ggsave("plots/exp2_singular_alltype.pdf", diff.singular, width=8, height = 2, dpi=300)
# ggsave("plots/exp2_plural_alltype.pdf", diff.plural, width=8, height = 2, dpi=300)
# ggsave("plots/exp2_sp_alltype.pdf", diff.sp, width=8, height = 2, dpi=300)
# ggsave("plots/exp2_singular_distance_alltype.pdf", diff.singular.distance, width=4.5, height = 3, dpi=300)

#================ VERSION: TWO ================


#================ METRIC: NONREF ==============