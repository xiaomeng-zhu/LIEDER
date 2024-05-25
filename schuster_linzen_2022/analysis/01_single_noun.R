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
    select(id, type, continuation_log_prob, pronoun) %>% 
    pivot_wider(names_from=pronoun, values_from=continuation_log_prob) %>% 
    mutate(ratio = 1/(1 + exp(subj-it))) 
  
  
  
  d.a_n = d %>% 
    filter(type %in% c("affirmative", "negated")) %>%
    mutate(basic_id = sub("[_a-z]+", "", id)) %>% 
    group_by(basic_id) %>% filter(ratio == max(ratio)) %>% 
    group_by() %>%
    dplyr::summarize(accuracy = mean(type == "affirmative"), ci_low = ci.low(type=="affirmative"), ci_high = ci.high(type=="affirmative")) %>%
    mutate(type = "affirmative_negation")
  
  d.a_m = d %>% 
    filter(type %in% c("affirmative", "modal")) %>%
    mutate(basic_id = sub("[_a-z]+", "", id)) %>% 
    group_by(basic_id) %>% filter(ratio == max(ratio)) %>% 
    group_by() %>%
    dplyr::summarize(accuracy = mean(type == "affirmative"), ci_low = ci.low(type=="affirmative"), ci_high = ci.high(type=="affirmative")) %>%
    mutate(type = "affirmative_modal")
  
  d.m_f = d %>% 
    filter(type %in% c("managed", "failed")) %>%
    mutate(basic_id = sub("[_a-z]+", "", id)) %>% 
    group_by(basic_id) %>% filter(ratio == max(ratio))%>% 
    group_by() %>%
    dplyr::summarize(accuracy = mean(type == "managed"), ci_low = ci.low(type=="managed"), ci_high = ci.high(type=="managed")) %>%
    mutate(type = "managed_failed")
  
  
  d.k_d = d %>% 
    filter(type %in% c("know", "doubt")) %>%
    mutate(basic_id = sub("[_a-z]+", "", id)) %>% 
    group_by(basic_id) %>% filter(ratio == max(ratio)) %>% group_by() %>%
    dplyr::summarize(accuracy = mean(type == "know"), ci_low = ci.low(type=="know"), ci_high = ci.high(type=="know")) %>%
    mutate(type = "know_doubt")
  
  
  d = rbind(d.a_n, d.a_m, d.m_f, d.k_d)
  
  d = d %>% mutate(model = model_name)
  
  return(d)
}


# GPT 2 small
d.gpt2 = analyze_model_experiment("../results/full_sentence_hand_written_stimuli.gpt2.processed.csv", "GPT-2")
# GPT-2 medium
d.gpt2med = analyze_model_experiment("../results/full_sentence_hand_written_stimuli.gpt2-medium.processed.csv", "GPT-2 M")
# GPT-2 large
d.gpt2lg = analyze_model_experiment("../results/full_sentence_hand_written_stimuli.gpt2-large.processed.csv", "GPT-2 L")
# GPT-2 XL
d.gpt2xl = analyze_model_experiment("../results/full_sentence_hand_written_stimuli.gpt2-xl.processed.csv", "GPT-2 XL")
# GPT-3
d.gpt3 = analyze_model_experiment("../results/full_sentence_hand_written_stimuli.gpt3.processed.csv", "GPT-3")

# Load human data
d.human = read.csv("../human_data/02_preferential_judgments/02_preferential_judgments-summarized.csv")
d.human = d.human %>% rename(accuracy = "exp_prop", type = "pair") %>% mutate(model = "Human")  %>% 
  mutate(type = gsub("-", "_", type)) %>%  
  mutate(type = gsub("negated", "negation", type)) %>% 
  mutate(ci_low  = accuracy - ci_low, ci_high = ci_high-accuracy ) %>%
  select(-X)


d.all = rbind(d.gpt2, d.gpt2med, d.gpt2lg, d.gpt2xl, d.gpt3, d.human)

d.all$model = factor(d.all$model, levels=c("GPT-2", "GPT-2 M", "GPT-2 L", "GPT-2 XL", "GPT-3", "Human"))
d.all$type = factor(d.all$type, levels = c("affirmative_negation", "affirmative_modal", "know_doubt", "managed_failed"), labels = c("affirmative - negation", "affirmative - modal", "know - doubt", "managed - failed"))

plt = d.all %>% 
  ggplot(aes(x=model, fill=model, y=accuracy)) +
    geom_bar(stat="identity", alpha=0.8) +
    ylim(0,1) +
    ylab("% expected") +
    facet_wrap(~type, ncol=4) +
    geom_errorbar(aes(ymin=accuracy - ci_low, ymax=accuracy + ci_high), width = 0.4, col="#666666") +
    theme(legend.position = "none", 
          axis.text.x = element_text(angle=90, hjust=1, vjust=0.4),
          strip.text = element_text(size=12) , 
          axis.title.x = element_blank(), 
          axis.ticks.x = element_blank()) + 
    col_scale +
    geom_hline(yintercept = 0.5, color="#666666", lty=2) 

ggsave(filename = "./results-experiment-1.pdf", plot = plt, widt=10, height = 3, device=cairo_pdf)


