# -*- coding: utf-8 -*-

import os, sys 
import numpy as np
import pandas as pd
import re
from scipy.stats import ttest_rel

import matplotlib
matplotlib.use('TKAgg')
import matplotlib.pyplot as plt

import seaborn as sns
sns.set_style("whitegrid")


# パス操作
file_name = os.path.basename(__file__)
file_name_wo_ext, ext = os.path.splitext(file_name) # ext = ".py"

# ファイルオープン
df = pd.read_csv("20210615_Raman79_DisruptionAssay_statistics.txt", sep="\t")

# サンプル名処理
for valid_dir_name in df["valid dir name"].unique():
    matched = df.query(f"`valid dir name`.str.match('{valid_dir_name}-[0-9]+$')")
    if len(matched) > 0:
        df = df.query(f"not `valid dir name`.str.match('{valid_dir_name}$')")
df["pre_post"] = df["valid dir name"].apply(lambda x: "pre" if "_pre" in x else "post")
df["pair"] = df["valid dir name"].apply(lambda x: re.match(".+_([0-9]+)_.+", x)[1])

###
pd.set_option('display.max_colwidth', 3000)	# 列の幅
pd.set_option('display.min_rows', 3000)
pd.set_option('display.max_rows', 3000)
print(df)
###

# グラフ描画
figsize = (2.5, 3.5)
fig = plt.figure(figsize=figsize)
x = "name"
y = "value"
hue = "pre_post"
hue_order = ["pre", "post"]
palette = sns.color_palette()#"RdBu", n_colors=2)
statistic_type = "average"  # "average", "area"

df = df.query(f"`statistic type` == '{statistic_type}'")
ax = sns.stripplot(x=x, y=y, data=df, palette=["C0", "C1"], jitter=False, hue=hue, hue_order=hue_order, dodge=True, s=7, linewidth=1)

# ペアで結ぶ
N_hue = len(hue_order)
w1 = 0.4 * 2 / N_hue * (N_hue - 1)
w2 = 1 / N_hue / 4
for (name, pair), extracted_df in df.groupby(["name", "pair"]):
    for xtick, ticklabel in zip(ax.get_xticks(), ax.get_xticklabels()):
        if ticklabel.get_text() == name:
            tick = xtick
            x1 = tick - w1 / 2
            x2 = tick + w1 / 2
            break
    else:
        raise Exception("error")
    y1 = extracted_df.loc[df[hue] == hue_order[0], y].values
    y2 = extracted_df.loc[df[hue] == hue_order[1], y].values
    plt.plot([x1, x2], [y1, y2], color='k', linewidth=1, linestyle='-')#, zorder=-1)
    # plt.text(x2, y2, pair)#, zorder=-1)

# 検定
for name in df.name.unique():
    for xtick, ticklabel in zip(ax.get_xticks(), ax.get_xticklabels()):
        if ticklabel.get_text() == name:
            break
    else:
        raise Exception("error")
    df4ttest = df.query(f"name == '{name}'").pivot_table(values="value", index="pair", columns="pre_post")
    r = ttest_rel(df4ttest.pre.values, df4ttest.post.values)
    plt.text(xtick, 6, f"p={r.pvalue:.2e}", ha='center')

if statistic_type == "average":
    ax.set_ylim(-0.2, 6.5)
else:
    ax.set_ylim(0, None)

ax.get_legend().remove()
plt.tight_layout()
plt.savefig(f"{file_name_wo_ext}_{statistic_type}.svg", bbox_inches='tight', pad_inches=0)
plt.show()

quit()











