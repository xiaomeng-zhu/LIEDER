import argparse
from helper import read_csv, output_dictlist_to_csv

COMP_TO_PROPERTY = {
   "pos_pos_p>neg_neg_s": "existence",
"pos_neg_s>neg_neg_s": "existence",
"pos_pos_p>neg_neg_p": "existence, plurality",
"neg_pos_s>pos_neg_p": "plurality",
"neg_pos_p>pos_neg_p": "distance effect",
"neg_pos_s>neg_pos_p": "plurality",
"neg_pos_s>neg_neg_p": "existence, plurality",
"pos_neg_s>neg_pos_p": "plurality",
"pos_neg_s>pos_neg_p": "plurality",
"neg_pos_s>pos_neg_s": "distance effect",
"pos_pos_p>pos_pos_s": "uniqueness, novelty",
"pos_neg_s>neg_neg_p": "existence, plurality",
"pos_neg_s>pos_pos_s": "uniqueness, novelty",
"neg_pos_s>pos_pos_s": "uniqueness, novelty",
"pos_pos_p>neg_pos_p": "plurality",
"neg_pos_s>neg_neg_s": "existence",
"pos_pos_p>pos_neg_p": "plurality",
}

parser = argparse.ArgumentParser(description="Generating accuracy annotated with semantic properties...")
parser.add_argument("--accuracy_file", help="Path to accuracy file e.g. results/base/base_llama2_7B_accuracy_ref.csv")
args = parser.parse_args()

def augment_with_property(fn):
    output_f = fn.split(".")[0]+"_with_property.csv"

    rows = read_csv(fn)
    for row in rows:
        row["property"] = COMP_TO_PROPERTY[row["type"]]

    output_dictlist_to_csv(rows, output_f)

if __name__ == "__main__":
    augment_with_property(args.accuracy_file)