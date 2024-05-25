library(tidyverse)
theme_set(theme_bw())

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

source("helpers.R")


fill_cols = c("#003f5c",
              "#58508d",
              "#bc5090",
              "#ff6361",
              "#ffa600",
              "#666666")

col_scale = scale_fill_manual(values=fill_cols)
text_colors = scale_color_manual(values=c("white", "white", "white", "white", "black"))




analyze_model_experiment = function(result_path, model_name) {
  d = read.csv(result_path)
  d = d %>% 
    select(id, type, continuation_log_prob, expected, order) %>% 
    pivot_wider(names_from=expected, values_from=continuation_log_prob) %>% 
    mutate(as_expected = `1` > `0`) %>%
    mutate(type = case_when(
      type == "negation_affirmative" ~ "affirmative_negation",
      type == "modal_affirmative" ~ "affirmative_modal",
      type == "doubt_know" ~ "know_doubt",
      type == "failed_managed" ~ "managed_failed",
      TRUE ~ type)) %>% mutate(noun_id = gsub("_[a-z]+_[a-z]+_[a-z]+$", "", id))
  
  d$model =  model_name
  return(d)
  
}

# GPT 2 small
d.gpt2 = analyze_model_experiment("../results/2nouns_full_sentence_hand_written_stimuli.gpt2.processed.csv", "GPT-2")
# GPT-2 medium
d.gpt2med = analyze_model_experiment("../results/2nouns_full_sentence_hand_written_stimuli.gpt2-medium.processed.csv", "GPT-2 M")
# GPT-2 large
d.gpt2lg = analyze_model_experiment("../results/2nouns_full_sentence_hand_written_stimuli.gpt2-large.processed.csv", "GPT-2 L")
# GPT-2 XL
d.gpt2xl = analyze_model_experiment("../results/2nouns_full_sentence_hand_written_stimuli.gpt2-xl.processed.csv", "GPT-2 XL")
# GPT-3
d.gpt3 = analyze_model_experiment("../results/2nouns_full_sentence_hand_written_stimuli.gpt3.processed.csv", "GPT-3")

# Load data from human experiments

d.human = read.csv("../human_data/02_preferential_judgments/02_preferential_judgments-2_noun-summarized.csv")
d.human = d.human %>% rename(accuracy = "accuracy_m") %>% mutate(model = "Human")  %>% 
  mutate(type = gsub("negated", "negation", type)) %>% 
  mutate(ci_low  = accuracy - ci_low, ci_high = ci_high-accuracy ) %>%
  select(-X)

d.human.ref = d.human %>% filter(ref == T)
d.human.nonref = d.human %>% filter(ref == F)


d.all = rbind(d.gpt2, d.gpt2med, d.gpt2lg, d.gpt2xl, d.gpt3)
d.all$ref = grepl("_ref$", d.all$id)


# main experiment figure

plt = d.all %>% 
  group_by(type, model, ref) %>% 
  summarise(accuracy=mean(as_expected), ci_low = ci.low(as_expected), ci_high = ci.high(as_expected)) %>% 
  rbind(d.human) %>% 
  mutate(
    type = factor(type, levels = c("affirmative_negation", "affirmative_modal", "know_doubt", "managed_failed"), 
                  labels = c("affirmative - negation", "affirmative - modal", "know - doubt", "managed - failed")),
    model = factor(model, levels=c("GPT-2", "GPT-2 M", "GPT-2 L", "GPT-2 XL", "GPT-3", "Human"), ordered = T)
  ) %>%
  mutate(ref = factor(ref, levels = c(T, F), labels = c("coreferential", "non-coreferential"))) %>%
  ggplot(aes(x=model, fill=model, y=accuracy)) + 
    geom_bar(stat="identity", alpha=0.8) + 
    ylim(0,1) + 
    ylab("% expected") + 
    facet_grid(ref~type) + 
    geom_errorbar(aes(ymin=accuracy - ci_low, ymax=accuracy + ci_high), width = 0.4, col="#666666") +
    theme(legend.position = "none", 
          axis.text.x = element_text(angle=90, hjust=1, vjust=0.4), 
          strip.text = element_text(size=12) ,
          axis.title.x = element_blank(), axis.ticks.x = element_blank()) + 
    col_scale + 
    geom_hline(yintercept = 0.5, color="#666666", lty=2) # +

ggsave(filename = "./results-experiment-2.pdf", plot = plt, width=10, height = 5, device=cairo_pdf)

# systematicity  figure

plt.sys = d.all %>% 
  group_by(type, noun_id, model, ref) %>%
  summarise(as_expected=min(as_expected)) %>%
  group_by(type, model) %>% 
  summarise(accuracy=mean(as_expected), ci_low = ci.low(as_expected), ci_high = ci.high(as_expected)) %>% 
  mutate(
    type = factor(type, levels = c("affirmative_negation", "affirmative_modal", "know_doubt", "managed_failed"), 
                  labels = c("affirmative - negation", "affirmative - modal", "know - doubt", "managed - failed")),
    model = factor(model, levels=c("GPT-2", "GPT-2 M", "GPT-2 L", "GPT-2 XL", "GPT-3", "Human"), ordered = T)
  ) %>%
  ggplot(aes(x=model, fill=model, y=accuracy)) + 
    geom_bar(stat="identity", alpha=0.8) +
    ylim(0,1) + 
    ylab("% expected") + 
    facet_grid(~type) + 
    geom_errorbar(aes(ymin=accuracy - ci_low, ymax=accuracy + ci_high), width = 0.4, col="#666666") +
    theme(legend.position = "none", 
          axis.text.x = element_text(angle=90, hjust=1, vjust=0.4), 
          strip.text = element_text(size=12),
          axis.title.x = element_blank(), 
          axis.ticks.x = element_blank()) + 
    col_scale +  
    geom_hline(yintercept = 0.0625, color="#666666", lty=2)

ggsave(filename = "./results-experiment-2-systematicity.pdf", plot = plt.sys, width=10, height = 5, device=cairo_pdf)


# compute percentage of times for which the model always preferred the same noun irrespective of 
# context (as dicussed in Section 4.2)

d.same_noun = d.all %>% 
  mutate(modal_order = case_when(grepl("negation_affirmative", id) ~ 2,
                                 grepl("failed_managed", id) ~ 2,
                                 grepl("doubt_know", id) ~ 2,
                                 grepl("modal_affirmative", id) ~ 2,
                                 TRUE ~ 1)) %>%
  mutate(chosen_noun = case_when(order == 1 & ref == TRUE & as_expected == FALSE ~ modal_order %% 2 + 1, 
                                 order == 1 & ref == FALSE & as_expected == TRUE ~  modal_order %% 2 + 1, 
                                 order == 2 & ref == TRUE & as_expected == TRUE ~  modal_order %% 2 + 1, 
                                 order == 2 & ref == FALSE & as_expected == FALSE ~  modal_order %% 2 + 1, 
                                 TRUE ~  (modal_order + 1) %% 2 + 1)) %>%
  mutate(frame = gsub("_(non)?ref", "", id))


d.same_noun %>% 
  group_by(model, type, noun_id, ref) %>% 
  dplyr::summarize(chosen_noun_total = sum(chosen_noun)) %>%
  mutate(all_same_noun = (chosen_noun_total %% 4 == 0)) %>%
  group_by(model) %>%
  dplyr::summarize(all_same_noun_prop = mean(all_same_noun))





