# LIEDER: Linguistically-Informed Evaluation Suite for Discourse Entity Recognition
## Abstract
Discourse Entity (DE) recognition is the task of identifying novel and known entities introduced within a text. While previous work has found that large language models have basic, if imperfect, DE recognition abilities (Schuster and Linzen, 2022), it remains largely unassessed which of the fundamental semantic properties that govern the introduction and subsequent reference to DEs they have knowledge of. We propose the Linguistically-Informed Evaluation for Discourse Entity Recognition (LIEDER) dataset that allows for a detailed examination of language models’ knowledge of four crucial semantic properties: EXISTENCE, UNIQUENESS, PLURALITY, and NOVELTY. We find evidence that state-of-the-art large language models exhibit sensitivity to all of these properties except NOVELTY, which demonstrates that they have yet to reach human-level language understanding abilities.

## Design of LIEDER
- **EXISTENCE**: A language model with human-level understanding abilities should only use definite descriptions to refer to entities that have been introduced into the discourse.
- **UNIQUENESS**: A language model should use a singular definite description to refer to a previously introduced entity only when the referent is unique relative to the discourse.
- **PLURALITY**: A language model should use a plural definite description only if the set of DEs contains more than one individual of the relevant sort.
- **NOVELTY**: A language model should recognize that an occurrence of an indefinite noun phrase is associated with the introduction of a new entity into the discourse.

## Main Results
### EXISTENCE
High accuracy on the first two panels suggests that models know EXISTENCE (i.e. singular definites cannot be used to refer to non-existing DEs).
![Figure1](plots/exp1_singular.pdf)

### UNIQUENESS
Two possible hypotheses: 

### PLURALITY
High accuracy on Figure 2 suggests that models know PLURALITY






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
