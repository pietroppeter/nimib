# set PATH=%PATH%;C:\Users\ppeterlongo\scoop\apps\emacs\27.1\bin
import nimib, nimoji

nbInit
nbText: """# :penguin: Exploring penguins with ggplotnim

We will explore the [palmer penguins dataset](https://github.com/allisonhorst/palmerpenguins)
with [ggplotnim](https://github.com/Vindaar/ggplotnim)
""".emojize

nbCode:
  import ggplotnim
nbText: "we read penguins csv in ggplotnim `DataFrame`"
nbCode:
  let df = toDf(readCsv("data/penguins.csv"))
nbText: "let us see how it looks"
nbCode:
  echo df # why so wide the first column?
nbText: """Note that among the 7 columns of the dataframe, the first 2 and the last one have datatype string.
The remaining 4 are numeric but they have datatype object. Why?

Because that there are null values in those columns (interpreted as strings):"""
nbCode:
  echo df["culmen_depth_mm", 1].kind
  echo df["culmen_depth_mm", 2].kind
  echo df["culmen_depth_mm", 3].kind
  echo df["flipper_length_mm", 2].kind
  echo df["flipper_length_mm", 3].kind
  


nbText: "Let's see how many penguins by species we have (and how do they relate to islands)."
nbCode:
  ggplot(df, aes("species", fill = "island")) + geom_bar() + ggsave("images/penguins_count_species.png")
nbImage(url="images/penguins_count_species.png", caption="Count of penguins by species")
nbText: """We see that 3 species of penguins (Adelie, Chinstrap, Gentoo)
are reported living on 3 islands (Biscoe, Dream, Torgersen).
The majority of penguins are Adelie and they are distributed over the 3 islands.
Gentoo penguins (second most common) almost all live on Biscoe,
and Chinstrap penguins almost all live on Dream.

We can confirm this with the following  image taken from the
[article](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0090081)
from where this dataset comes from:
"""

nbImage(url="https://storage.googleapis.com/plos-corpus-prod/10.1371/journal.pone.0090081/1/pone.0090081.g001.PNG_L?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Credential=wombat-sa%40plos-prod.iam.gserviceaccount.com%2F20210215%2Fauto%2Fstorage%2Fgoog4_request&X-Goog-Date=20210215T135054Z&X-Goog-Expires=3600&X-Goog-SignedHeaders=host&X-Goog-Signature=6855d7a3169bd8f37b9775e8ccad98064e1d0a3291de04d4938b1d317c20db9e5e0a067decf25a9e975d431ac6a2dae35ac3ead1f59de90f7b1c1773f26647d55e214ec41a62bd1669c286958154188ca06dd9f60010b58283036df06aa26943891f302c38f13347d0f0f41a3ac97b1ac0a5c92263dedc3b1fb105fa94f5a1ccc5ae1cf12877cb518d8c42cd5d1e24b9e18e8df746256d0f96113387dddbf845752c5b5cc74c371b18f29109c98796bee01bffcda200d50c717bd497734c9ce4e5355255a0dc448e0ec3b2214095881db82529419c185bb8280174edf6e418193ee529cc470c5f099256d42d9225c3475ea96ee217b1b5e8fec02716b341c436",
        caption="Penguins by Location")

nbText: """We do expect weight being correlated to some of the length measures
(e.g. flipper length) with males being bigger than females.

To plot this we need to remove all `NA`s:
"""
# manage runtime error here!
#nbCode:
#  ggplot(df, aes(x="body_mass_g", y="flipper_length_mm", color = "sex", shape="species")) + geom_point() + ggsave("images/penguins_mass_vs_length_with_sex_and_species.png")
#nbImage(url="images/penguins_mass_vs_length_with_sex_and_species.png", caption="Penguins' mass vs flipper length")
nbCode:
  let df1 = df.filter(f{c"body_mass_g" != "NA"}) # why c""?
  ggplot(df1, aes(x="body_mass_g", y="flipper_length_mm", color = "sex")) + geom_point() + ggsave("images/penguins_mass_vs_length_with_sex.png")
nbImage(url="images/penguins_mass_vs_length_with_sex.png", caption="Penguins' mass vs flipper length (colored by sex)")
nbText: """A few things to remark:

- as expected body mass and flipper length are linearly correlated
- males are in general bigger than females but there appear 2 groups, possibly related to species
- we have some more NAs (and one '.') in sex column (even after filtering for NAs in numeric columns)

Let's now look at the same chart coloring by species instead of by sex (shape is not yet supported in ggplotnim):
"""
nbCode:
  ggplot(df1, aes(x="body_mass_g", y="flipper_length_mm", color = "species")) + geom_point() + ggsave("images/penguins_mass_vs_length_with_species.png")
nbImage(url="images/penguins_mass_vs_length_with_species.png", caption="Penguins' mass vs flipper length (colored by species)")
nbText: """We can see that sizes of Adelie and Chinstrap overlap, while Gentoo penguins are in general bigger.

As a final plot, I would like to (partly) reproduce a plot that "shows" the presence of [Simpson's paradox](https://en.wikipedia.org/wiki/Simpson%27s_paradox) in this dataset,
as reported by [this tweet](https://twitter.com/andrewheiss/status/1301166792627421186):
"""
nbCode:
  ggplot(df1, aes(x="culmen_depth_mm", y="body_mass_g", color = "species")) + geom_point() + ggsave("images/penguins_simpson.png")
nbImage(url="images/penguins_simpson.png", caption="""
Simpson's paradox in Penguins' dataset: for every species bigger mass is correlated with thicker bill,
but looking at all species taken together bigger mass is correlated with thinner bill""")
nbText: """
We can see that Gentoo penguins, although in general bigger, have a "thinner" bill (see image below for meaning of bill and culmen)!
"""
nbImage(url="https://pbs.twimg.com/media/Eg6sRJ1XcAAkxiu?format=jpg&name=4096x4096", caption="""
Penguin's bill and culmen explained (Artwork by @allison_horst)""")
nbSave