library(gutenbergr)
library(stringr)
library(ggplot2)
install.packages("gutenbergr")

data(stop_words)

gutenberg_metadata %>%
  filter(str_detect(author, "Jókai, Mór"))
tidy_books <- gutenberg_download(14048) %>%
  unnest_tokens(word, text)

tidy_books <- tidy_books %>%
  anti_join(stop_words)

tidy_books %>%
  count(word, sort = TRUE)

tidy_books %>%
  count(word, sort = TRUE) %>%
  filter(n > 100) %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n)) +
  geom_col() +
  xlab(NULL) +
  coord_flip()
