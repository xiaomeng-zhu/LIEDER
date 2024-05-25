setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

source("../helpers.R")

d = read.csv("../../human_data//02_preferential_judgments/02_preferential_judgments-merged.csv")

theme_set(theme_bw())

d = d %>% mutate(response = case_when(grepl("^15_.*ref$", id) & response == "exp" ~ "unexp",
                                      grepl("^15_.*ref$", id) & response == "unexp" ~ "exp",
                                      TRUE ~ response))


d %>% ggplot(aes(x=response)) + geom_histogram(stat="count") + facet_wrap(~type, scales = "free_y")


# affirmative
d %>% filter(type=="affirmative") %>% ggplot(aes(x=response)) + geom_histogram(stat="count") + facet_wrap(~id)

# managed
d %>% filter(type=="managed") %>% ggplot(aes(x=response)) + geom_histogram(stat="count") + facet_wrap(~id)

# know
d %>% filter(type=="know") %>% ggplot(aes(x=response)) + geom_histogram(stat="count") + facet_wrap(~id)

# negation
d %>% filter(type=="negated") %>% ggplot(aes(x=response)) + geom_histogram(stat="count") + facet_wrap(~id)

# modal
d %>% filter(type=="modal") %>% ggplot(aes(x=response)) + geom_histogram(stat="count") + facet_wrap(~id)

# failed
d %>% filter(type=="failed") %>% ggplot(aes(x=response)) + geom_histogram(stat="count") + facet_wrap(~id)

# doubt
d %>% filter(type=="doubt") %>% ggplot(aes(x=response)) + geom_histogram(stat="count") + facet_wrap(~id)



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# affirmative_negated

d2 = d %>% mutate(type = case_when(type == "negation_affirmative" ~ "affirmative_negation",
                                   type == "modal_affirmative" ~ "affirmative_modal",
                                   type == "failed_managed" ~ "managed_failed",
                                   type == "doubt_know" ~ "know_doubt",
                                   TRUE ~ type)) %>%
           mutate("ref" = case_when(grepl(pattern = "_nonref", id) ~ FALSE,
                                    TRUE ~ TRUE)) %>%
          mutate("item" = gsub("_.*$", "", id))


d2 %>% filter(type=="affirmative_negation") %>% filter(ref == TRUE) %>% ggplot(aes(x=response)) + geom_histogram(stat="count") + facet_wrap(~item) + ggtitle("Affirmative-negated -- REF")
d2 %>% filter(type=="affirmative_negation") %>% filter(ref == FALSE) %>% ggplot(aes(x=response)) + geom_histogram(stat="count") + facet_wrap(~item) + ggtitle("Affirmative-negated -- non-REF")

d2 %>% filter(type=="affirmative_modal") %>% filter(ref == TRUE) %>% ggplot(aes(x=response)) + geom_histogram(stat="count") + facet_wrap(~item) + ggtitle("Affirmative-modal -- REF")
d2 %>% filter(type=="affirmative_modal") %>% filter(ref == FALSE) %>% ggplot(aes(x=response)) + geom_histogram(stat="count") + facet_wrap(~item) + ggtitle("Affirmative-modal -- non-REF")

d2 %>% filter(type=="managed_failed") %>% filter(ref == TRUE) %>% ggplot(aes(x=response)) + geom_histogram(stat="count") + facet_wrap(~item) + ggtitle("managed-failed -- REF")
d2 %>% filter(type=="managed_failed") %>% filter(ref == FALSE) %>% ggplot(aes(x=response)) + geom_histogram(stat="count") + facet_wrap(~item) + ggtitle("managed-failed -- non-REF")

d2 %>% filter(type=="know_doubt") %>% filter(ref == TRUE) %>% ggplot(aes(x=response)) + geom_histogram(stat="count") + facet_wrap(~item) + ggtitle("know-doubt -- REF")
d2 %>% filter(type=="know_doubt") %>% filter(ref == FALSE) %>% ggplot(aes(x=response)) + geom_histogram(stat="count") + facet_wrap(~item) + ggtitle("know-doubt -- non-REF")

d2 %>% filter(item != "filler") %>% filter(item != "practice")  %>% ggplot(aes(x=response)) + geom_histogram(stat="count") + facet_wrap(~type)

d2 %>% filter(ref==FALSE) %>% ggplot(aes(x=response)) + geom_bar(stat="count") + facet_wrap(~type) + ggtitle("Non-referential")

d2 %>% filter(ref==TRUE & type %in% c("affirmative_negation", "affirmative_modal", "managed_failed", "know_doubt")) %>% ggplot(aes(x=response)) + geom_bar(stat="count") + facet_wrap(~type) + ggtitle("Referential")




d %>% 
  filter(type %in% c("affirmative", "negated", "managed", "failed", "know", "doubt", "modal")) %>% 
  group_by(id, type) %>% 
  summarise(exp_count = sum(response == "exp"), unexp_count = sum(response == "unexp")) %>%
  mutate(exp_proportion = exp_count / (exp_count + unexp_count)) %>%
  group_by(type) %>%
  summarise(expected_proportion = sum(exp_proportion > 0.5))



d3 = d %>% 
  filter(type %in% c("affirmative", "negated", "managed", "failed", "know", "doubt", "modal")) %>% 
  mutate(referential_response = case_when((type %in% c("negated", "failed", "doubt", "modal")) & response == "exp" ~ "non-ref",
                                          (type %in% c("negated", "failed", "doubt", "modal")) & response == "unexp" ~ "ref",
                                          response == "exp" ~ "ref",
                                          response == "unexp" ~ "non-ref"
                                          )) %>%
  group_by(type) %>%
  summarise(ref_proportion = mean(referential_response == "ref"))

d3 %>% ggplot(aes(y=ref_proportion,  x = type)) + geom_histogram(stat="identity")

d3 %>% filter(type %in% c("affirmative", "negated")) %>% ggplot(aes(y=ref_proportion,  x = type)) + geom_histogram(stat="identity") + ggtitle("Affirmative-negated")
 
d3 %>% filter(type %in% c("affirmative", "modal")) %>% ggplot(aes(y=ref_proportion,  x = type)) + geom_histogram(stat="identity") + ggtitle("Affirmative-modal")

d3 %>% filter(type %in% c("managed", "failed")) %>% mutate(type = factor(type, levels=c("managed", "failed"))) %>% ggplot(aes(y=ref_proportion,  x = type)) + geom_histogram(stat="identity") + ggtitle("managed-failed")

d3 %>% filter(type %in% c("know", "doubt")) %>% mutate(type = factor(type, levels=c("know", "doubt"))) %>% ggplot(aes(y=ref_proportion,  x = type)) + geom_histogram(stat="identity") + ggtitle("know-doubt")


d4 = d %>% 
  filter(type %in% c("affirmative", "negated", "managed", "failed", "know", "doubt", "modal")) %>% 
  mutate(referential_response = case_when((type %in% c("negated", "failed", "doubt", "modal")) & response == "exp" ~ "non-ref",
                                          (type %in% c("negated", "failed", "doubt", "modal")) & response == "unexp" ~ "ref",
                                          response == "exp" ~ "ref",
                                          response == "unexp" ~ "non-ref"
  )) %>% 
  group_by(id, type) %>%
  summarise(ref_proportion = mean(referential_response == "ref"))  %>%
  mutate("item" = gsub("_.*$", "", id))

compute_expected_prop = function(df, type_pos, type_neg) {
  ret_val = df %>% filter(type == type_pos) %>% merge(df %>% filter(type == type_neg), by=c("item")) %>% 
    mutate(expected = ref_proportion.x > ref_proportion.y, pair = paste(type_pos, type_neg, sep="-")) %>% group_by(pair) %>%
    summarise(expected_prop = mean(expected))
  return(ret_val)
}


d.exp_prop = data.frame()

for (i in 1:10000) {
   dx = d %>% 
     filter(type %in% c("affirmative", "negated", "managed", "failed", "know", "doubt", "modal")) %>% 
     mutate(referential_response = case_when((type %in% c("negated", "failed", "doubt", "modal")) & response == "exp" ~ "non-ref",
                                             (type %in% c("negated", "failed", "doubt", "modal")) & response == "unexp" ~ "ref",
                                             response == "exp" ~ "ref",
                                             response == "unexp" ~ "non-ref"
     )) %>% 
     group_by(id, type) %>%
     summarise(ref_proportion = mean(sample(referential_response, length(referential_response), replace = T) == "ref"))  %>%
     mutate("item" = gsub("_.*$", "", id))
   
   d.an = compute_expected_prop(dx, "affirmative", "negated")
   
   d.am = compute_expected_prop(dx, "affirmative", "modal")
   
   d.mf = compute_expected_prop(dx, "managed", "failed")
   
   d.kd = compute_expected_prop(dx, "know", "doubt")
   
   
   d.exp_prop2 = rbind(d.an, d.am, d.mf, d.kd)
   d.exp_prop2$run = i
   d.exp_prop = rbind(d.exp_prop, d.exp_prop2)
   
  

}

d.exp_prop %>% 
  group_by(pair) %>% 
  dplyr::summarize(ci_low = quantile(expected_prop, 0.025), ci_high = quantile(expected_prop, 0.975), exp_prop  = median(expected_prop)) %>%
  write.csv(file="../human_data/02_preferential_judgments/02_preferential_judgments-summarized.csv")

d.exp_prop %>% ggplot(aes(x=pair, y=expected_prop)) + geom_bar(stat="identity")


d5 = d %>% 
  filter(type %in% c("affirmative", "negated", "managed", "failed", "know", "doubt", "modal")) %>% 
  mutate(referential_response = case_when((type %in% c("negated", "failed", "doubt", "modal")) & response == "exp" ~ "non-ref",
                                          (type %in% c("negated", "failed", "doubt", "modal")) & response == "unexp" ~ "ref",
                                          response == "exp" ~ "ref",
                                          response == "unexp" ~ "non-ref"
  )) %>%
  group_by(type,id ) %>%
  summarise(ref_proportion = mean(referential_response == "ref")) %>%
  group_by(type) %>%
  summarise(majority_ref_proportion = mean(ref_proportion > .5))


d5 %>% filter(type %in% c("affirmative", "negated")) %>% ggplot(aes(y=majority_ref_proportion,  x = type)) + geom_histogram(stat="identity") + ggtitle("Affirmative-negated")

d5 %>% filter(type %in% c("affirmative", "modal")) %>% ggplot(aes(y=majority_ref_proportion,  x = type)) + geom_histogram(stat="identity") + ggtitle("Affirmative-modal")

d5 %>% filter(type %in% c("managed", "failed")) %>% mutate(type = factor(type, levels=c("managed", "failed"))) %>% ggplot(aes(y=majority_ref_proportion,  x = type)) + geom_histogram(stat="identity") + ggtitle("managed-failed")

d5 %>% filter(type %in% c("know", "doubt")) %>% mutate(type = factor(type, levels=c("know", "doubt"))) %>% ggplot(aes(y=majority_ref_proportion,  x = type)) + geom_histogram(stat="identity") + ggtitle("know-doubt")





# 2 noun item results


d.2_noun_means = d2 %>% 
  filter(type %in% c("affirmative_negation", "affirmative_modal", "managed_failed", "know_doubt"))  %>% 
  group_by(item, type, ref) %>%
  summarise(exp_proportion = mean(response == "exp"))  %>%
  group_by(type, ref) %>%
  summarise(accuracy_m = mean(exp_proportion > 0.5))


# bootstrap

d.2_noun_boot = data.frame()
for (i in 1:10000) {
  if (i %% 100 == 0) {
    print(i)
  }
  dx = d2 %>% 
    filter(type %in% c("affirmative_negation", "affirmative_modal", "managed_failed", "know_doubt"))  %>% 
    group_by(item, type, ref) %>%
    summarise(exp_proportion = mean(sample(response, length(response), replace = T) == "exp"))  %>%
    group_by(type, ref) %>%
    summarise(accuracy_m = mean(exp_proportion > 0.5))
  
  dx$run = i
  d.2_noun_boot = rbind(d.2_noun_boot, dx)
}


d.2_noun_boot %>% 
  group_by(type, ref) %>% 
  dplyr::summarize(ci_low = quantile(accuracy_m, 0.025), ci_high = quantile(accuracy_m, 0.975)) %>% 
  merge(d.2_noun_means, by=c("type", "ref")) %>%
  write.csv(file="../human_data/02_preferential_judgments/02_preferential_judgments-2_noun-summarized.csv")


