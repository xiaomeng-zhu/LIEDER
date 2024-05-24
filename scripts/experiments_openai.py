import csv, sys, json, openai, os
import numpy
from tqdm import tqdm


openai.api_key = "<API_KEY>"

config_f = sys.argv[1]
with open(config_f) as f:
    config_dict = json.load(f)
model_name = config_dict["model"]
exp_version = config_dict["exp"]
stimuli_path = f"stimuli/{exp_version}/{exp_version}_stimuli.jsonl"
result_path = f"results/{exp_version}/{exp_version}_{model_name}.csv"

# ======= load in data ======
print(f"Loading stimuli from {stimuli_path}...")
examples = []

with open(stimuli_path, "r") as jsonl_f:
    for line in jsonl_f:
        ex = json.loads(line)
        examples.append(ex)
print("Finished loading stimuli")

sentences = [example["sent"] for example in examples]

for i in range(len(sentences)):
    response = openai.Completion.create(engine=model_name,
            prompt=[sentences[i]],
            max_tokens=0,
            temperature=0.0,
            logprobs=0,
            echo=True,
            # echo=False
        )
    examples[i]["tokens"] = "|".join(response["choices"][0]["logprobs"]["tokens"])
    examples[i]["logprobs"] = response["choices"][0]["logprobs"]["token_logprobs"][1:]

print(f"Storing results to {result_path}...")
with open(result_path, "w") as csv_f:
    writer = csv.DictWriter(csv_f, fieldnames=examples[0].keys())
    writer.writeheader()
    writer.writerows(examples)
print("Finished storing results")
