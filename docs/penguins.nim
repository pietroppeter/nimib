import nimib, nimoji

nbInit
nbText: """
> This nimib example document shows how to insert images in nimib documents.
"""
nbText: """# :penguin: Exploring penguins with ggplotnim

We will explore the [palmer penguins dataset](https://github.com/allisonhorst/palmerpenguins)
with [ggplotnim](https://github.com/Vindaar/ggplotnim) and [datamancer](https://github.com/SciNim/Datamancer).
""".emojize

nbCode:
  import datamancer
nbText: "we read the penguins csv into a Datamancer `DataFrame`"
nbCode:
  let df = readCsv("data/penguins.csv")
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



nbText: """Let's see how many penguins by species we have (and how do they relate to islands)
by plotting the species count per island using ggplotnim:"""
nbCode:
  import ggplotnim
  ggplot(df, aes("species", fill = "island")) + geom_bar() + ggsave("images/penguins_count_species.png")
nbImage(url="images/penguins_count_species.png", caption="Count of penguins by species")
nbText: """We see that 3 species of penguins (Adelie, Chinstrap, Gentoo)
are reported living on 3 islands (Biscoe, Dream, Torgersen).
The majority of penguins are Adelie and they are distributed over the 3 islands.
Gentoo penguins (second most common) almost all live on Biscoe,
and Chinstrap penguins almost all live on Dream.

We can confirm this with the following image taken from the
[article](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0090081)
from where this dataset comes from:
"""

nbImage(url="images/penguins_map.png",
        caption="Penguins by Location")

nbText: """We do expect weight being correlated to some of the length measures
(e.g. flipper length) with males being bigger than females.

To plot this we need to remove all `NA` and then classify the points both by the penguins sex as
well as their species:
"""
# manage runtime error here!
#nbCode:
#  ggplot(df, aes(x="body_mass_g", y="flipper_length_mm", color = "sex", shape="species")) + geom_point() + ggsave("images/penguins_mass_vs_length_with_sex_and_species2.png")
#nbImage(url="images/penguins_mass_vs_length_with_sex_and_species2.png", caption="Penguins' mass vs flipper length")
nbCode:
  let df1 = df.filter(f{`body_mass_g` != "NA"}) # c"foo" == `foo` == idx("foo") (accent quoted not usable for columns w/ spaces)
  ggplot(df1, aes(x="body_mass_g", y="flipper_length_mm", color = "sex", shape="species")) + geom_point() + ggsave("images/penguins_mass_vs_length_with_sex.png")
nbImage(url="images/penguins_mass_vs_length_with_sex.png", caption="Penguins' mass vs flipper length (colored by sex)")
nbText: """A few things to remark:

- as expected body mass and flipper length are linearly correlated
- males are in general bigger than females but there appear 2 groups, possibly related to species
- we have some more NAs (and one '.') in sex column (even after filtering for NAs in numeric columns
- we can see that sizes of Adelie and Chinstrap overlap, while Gentoo penguins are in general bigger


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