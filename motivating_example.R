install.packages("tidytext")

library(twitteR)
## copied from: https://gist.github.com/earino/65faaa4388193204e1c93b8eb9773c1c

library(tidyverse)
library(tidytext)
# library(broom)

#authenticate to distant service
setup_twitter_oauth(
  consumer_key = Sys.getenv("TWITTER_CONSUMER_KEY"),
  consumer_secret = Sys.getenv("TWITTER_CONSUMER_SECRET"),
  access_token = Sys.getenv("TWITTER_ACCESS_TOKEN"),
  access_secret = Sys.getenv("TWITTER_ACCESS_SECRET")
)

trump <- userTimeline('realDonaldTrump', n = 3200)
obama <- userTimeline('BarackObama', n = 3200)

raw_tweets <- bind_rows(twListToDF(trump), twListToDF(obama))

words <- raw_tweets %>%
  unnest_tokens(word, text) #global, should work for hungarian as well
data("stop_words")

words <- words %>%
  anti_join(stop_words, by = "word") %>%
  filter(! str_detect(word, "\\d"))

words_to_ignore <- data_frame(word = c("https", "amp", "t.co"))

words <- words %>%
  anti_join(words_to_ignore, by = "word")

tweets <- words %>%
  group_by(screenName, id, word) %>%
  summarise(contains = 1) %>%
  ungroup() %>%
  spread(key = word, value = contains, fill = 0) %>%
  mutate(tweet_by_trump = as.integer(screenName == "realDonaldTrump")) %>%
  select(-screenName, -id)

library(glmnet)

fit <- cv.glmnet(
  x = tweets %>% select(-tweet_by_trump) %>% as.matrix(),
  y = tweets$tweet_by_trump,
  family = "binomial"
)

temp <- coef(fit, s = exp(-3)) %>% as.matrix()
coefficients <- data.frame(word = row.names(temp), beta = temp[, 1])
data <- coefficients %>%
  filter(beta != 0) %>%
  filter(word != "(Intercept)") %>%
  arrange(desc(beta)) %>%
  mutate(i = row_number())

ggplot(data, aes(x = i, y = beta, fill = ifelse(beta > 0, "Trump", "Obama"))) +
  geom_bar(stat = "identity", alpha = 0.75) +
  scale_x_continuous(breaks = data$i, labels = data$word, minor_breaks = NULL) +
  xlab("") +
  ylab("Coefficient Estimate") +
  coord_flip() +
  scale_fill_manual(
    guide = guide_legend(title = "Word typically used by:"),
    values = c("#446093", "#bc3939")
  ) +
  theme_bw() +
  theme(legend.position = "top")

library(wordcloud)

words %>%
  filter(screenName == "realDonaldTrump") %>%
  count(word) %>%
  with(wordcloud(word, n, max.words = 20))

words %>%
  filter(screenName == "BarackObama") %>%
  count(word) %>%
  with(wordcloud(word, n, max.words = 20))

ggplot(raw_tweets, aes(x = created, y = screenName)) +
  geom_jitter(width = 0) +
  theme_bw() +
  ylab("") +
  xlab("")