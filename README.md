# LIEDER: Linguistically-Informed Evaluation Suite for Discourse Entity Recognition
## Abstract
Discourse Entity (DE) recognition is the task of identifying novel and known entities introduced within a text. While previous work has found that large language models have basic, if imperfect, DE recognition abilities (Schuster and Linzen, 2022), it remains largely unassessed which of the fundamental semantic properties that govern the introduction and subsequent reference to DEs they have knowledge of. We propose the Linguistically-Informed Evaluation for Discourse Entity Recognition (LIEDER) dataset that allows for a detailed examination of language models’ knowledge of four crucial semantic properties: EXISTENCE, UNIQUENESS, PLURALITY, and NOVELTY. We find evidence that state-of-the-art large language models exhibit sensitivity to all of these properties except NOVELTY, which demonstrates that they have yet to reach human-level language understanding abilities.

## Design of LIEDER
We outline four crucial semantic properties that language models ought to know for successful DE recognition:
- **EXISTENCE**: A language model with human-level understanding abilities should only use definite descriptions to refer to entities that have been introduced into the discourse.
- **UNIQUENESS**: A language model should use a singular definite description to refer to a previously introduced entity only when the referent is unique relative to the discourse.
- **PLURALITY**: A language model should use a plural definite description only if the set of DEs contains more than one individual of the relevant sort.
- **NOVELTY**: A language model should recognize that an occurrence of an indefinite noun phrase is associated with the introduction of a new entity into the discourse.

Each example in LIEDER consists of two sentences: a context sentence followed by a continuation. There are four context types: `pos_neg`, `neg_pos`, `pos_pos`, `neg_neg` and two continuation types: singular and plural, which result in 8 different combinations (summarized below).
| Context type  | Context                                           | Singular Continuation     | Plural Continuation       |
|---------------|---------------------------------------------------|---------------------------|---------------------------|
| `pos_neg`     | John owns a dog but Mark doesn't own a dog.       | The dog is very cute.     | \#The dogs are very cute. |
| `neg_pos`     | John doesn't own a dog but Mark owns a dog.       | The dog is very cute.     | \#The dogs are very cute. |
| `pos_pos`     | John owns a dog and Mark owns a dog too.          | \#The dog is very cute.   | The dogs are very cute.   |
| `neg_neg`     | John doesn't own a dog and Mark doesn't own a dog either. | \#The dog is very cute.   | \#The dogs are very cute. |

Because metalinguistic judgments elicited from language models may not reflect the full extent of the model's knowledge (Hu & Levy, 2023), we instead compare felicity using the probabilities the model assigns to the continuation given the context.  We assume that the probability a model assigns to a felicitous case should be greater than the probability it assigns to an infelicitous one. 
With 3 felicitous pairs and 5 infelicitous ones, this means we have 15 informative probability comparisons in total.

| Comparison Type                        | Requirement                               |
|----------------------------------------|-------------------------------------------|
| `p(sg\|pos_neg)>p(sg\|pos_pos)`          | uniqueness, novelty                       |
| `p(sg\|neg_pos)>p(sg\|pos_pos)`          | uniqueness, novelty                       |
| `p(sg\|neg_pos)>p(sg\|neg_neg)`          | existence                                 |
| `p(sg\|pos_neg)>p(sg\|neg_neg)`          | existence                                 |
| `p(pl\|pos_pos)>p(pl\|pos_neg)`          | plurality                                 |
| `p(pl\|pos_pos)>p(pl\|neg_pos)`          | plurality                                 |
| `p(pl\|pos_pos)>p(pl\|neg_neg)`          | existence, plurality                      |
| `p(sg\|pos_neg)>p(pl\|pos_neg)`          | plurality                                 |
| `p(sg\|pos_neg)>p(pl\|neg_pos)`          | plurality                                 |
| `p(sg\|pos_neg)>p(pl\|neg_neg)`          | existence, plurality                      |
| `p(sg\|neg_pos)>p(pl\|neg_pos)`          | plurality                                 |
| `p(sg\|neg_pos)>p(pl\|pos_neg)`          | plurality                                 |
| `p(sg\|neg_pos)>p(pl\|neg_neg)`          | existence, plurality                      |
| `p(pl\|pos_pos)>p(sg\|pos_pos)`          | uniqueness, novelty                       |
| `p(pl\|pos_pos)>p(sg\|neg_neg)`          | existence                                 |


## Experiment 1
### EXISTENCE & UNIQUENESS
High accuracy on the first two panels suggests that models know EXISTENCE (i.e. singular definites cannot be used to refer to non-existing DEs).
![exp1_singular](https://github.com/xiaomeng-zhu/LIEDER/assets/106610647/c0f51186-2de9-41fe-a4be-862e668dbcc7)

Lower accuracy on the last two panels suggests two possibilities:
- **Hypothesis 1**: During training, the models have successfully learned the EXISTENCE requirement, but they failed to learn UNIQUENESS.
- **Hypothesis 2**: During training, the models have successfully learned both the EXISTENCE and UNIQUENESS requirements but fail to recognize that two distinct DEs have been introduced in `pos_pos` contexts, resulting in difficulties in distinguishing the infelicitous `pos_pos` from felicitous `pos_neg` and `neg_pos`. To put it in another way, they fail at the NOVELTY requirement.

Experiments 2 and 3 will focus on teasing these two hypotheses apart.

### PLURALITY
High accuracy in all three panels below suggests that models know PLURALITY.
![exp1_plural](https://github.com/xiaomeng-zhu/LIEDER/assets/106610647/d93a2e47-b112-4af8-b20b-868effe9fd76)


## Experiment 2
One way to test if LLMs fail to recognize two different DEs in `pos_pos` contexts is to use lexical cues that make explicit the distinctness of the first and second entities.  
If performance relative to `pos_pos` contexts increases when the distinction is explicit, then there is evidence that the LLMs fail to recognize the distinction in the implicit case, where the presence of multiple DEs results from the NOVELTY condition on indefinites alone. 

Accordingly, we make the following modification to our dataset which we call *Explicit Novelty* (corresponding to `diff` in the repo): for each context of the type `pos_pos`, we add the adjective *different* to the second indefinite description. 
![exp2_singular_vs_exp1](https://github.com/xiaomeng-zhu/LIEDER/assets/106610647/c086cbc1-7eb9-4142-9ff1-5e9e64c78925)
There is a significant increase (p<0.001) in accuracy from *Implicit* to *Explicit Novelty*, suggesting models' difficulty with the NOVELTY requirement.

# Replication
To replicate our results, start by `cd` into the repository and follow the instructions below:

## Naming Conventions
All experimental configurations in the `config` directory and results in the `results` directory obey the following naming conventions:
- `<exp_version> = {base, diff, two}` that corresponds to Experiment 1, 2, and 3 (Appendix) respectively.
- `<model> = {llama2, llama3, babbage-002, davinci-002}`[^1]
- `<size>` can be 7B, 13B, and 70B for Llama 2 or 8B and 70B for Llama 3.

## Running Inference
```
python scripts/experiments_<spec>.py --config <config_f>
```
Specifically, 
- `scripts/experiments_openai.py` for `babbage-002` and `davinci-002`
- `scripts/experiments_llama_family.py` for loading Llama models on a CPU
- `scripts/experiments_llama_family_gpu.py` for loading Llama models on a GPU [^2]
  
For example, if you would like to run Llama2-7B on the base version of LIEDER (corresponding to Experiment 1), run the following command
```
python scripts/experiments_llama_family.py --config config/base_llama2_7B.json
```
**Note**: Please double check that the script that you are using and the config file match in terms of the model series. For example, running `scripts/experiments_openai.py` using a Llama config file will result in errors.

## Analyzing Results
To analyze the results in Experiment 1 and 2, running the following command with the appropriate config file
```
python scripts/analyze_experiments.py --config <config_f> --metric <ref_or_nonref> --model_series <llama_or_not>
```
To analyze the results for Experiment 3, simply replace `scripts/analyze_experiments.py` with `scripts/analyze_experiments_two.py`.

If you would like to compute accuracy under the direct metric that is used throughout the main body of the paper, the second argument `--metric` should be `ref`. Otherwise, if you would like to use the relative metric discussed in the appendix, specify the metric as `nonref`.

For example, running the following command 
```
python scripts/analyze_experiments_two.py --config config/two_llama2_7B.json --metric ref --model_series llama
```
produces two files: `results/two/two_llama2_7B_summed.csv` and `results/two/two_llama2_7B_accuracy_ref.csv`. The former contains the summed conditional probability of the continuation given the context, and the latter contains the accuracy per comparisons.

## Generating Plots
Follow `analysis.R` for plots and significance analysis.


[^1]: The repository also contains results from GPT-2 and CodeLlama that are not included in the camera-ready version of the paper.
[^2]: Note that some of the models might be too large to fit on a single GPU. In such cases, follow comments in the script for details.
