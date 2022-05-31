import tweepy
from datetime import datetime, date, timedelta
import nltk
from nltk.sentiment import SentimentIntensityAnalyzer
import pandas as pd
import numpy as np

API_key = 'mnNTrV9H1bmL0XJhUvZhmUMcR'

API_secret = 'iCcqBK5UuNnS5cujZeo818fSVFodskJQKuszNU2uIGpeYN9vIC'

Bearer_token = 'AAAAAAAAAAAAAAAAAAAAAOksTgEAAAAAoXP1NSXvoAIb0rLVxcH%2Bf8u51SM%3DMyh9DmDqfJMzI6lAlgIR2KRCe2YN7gJEEqsbcpL4QNlIAyRBDH'

Access_token = '1117997013763801088-7vFgM81TtaE78GJ0ZcTrZspN6mJK46'

Access_token_secret = '1117997013763801088-7vFgM81TtaE78GJ0ZcTrZspN6mJK46'

auth = tweepy.AppAuthHandler(API_key, API_secret)

api = tweepy.API(auth)

sia = SentimentIntensityAnalyzer()

# pull the tweets using tweepy
def get_tweets(hashtag, n=1000):
    pulled_tweets = tweepy.Cursor(api.search,
                                  q="{}".format(hashtag),
                                  lang="es",
                                  tweet_mode='extended',
                                  # until=datetime.today() - timedelta(6)
                                  # format YYYY-MM-DD in datetime. Not string. Twitter only extract tweets before that date
                                  ).items(n)
    return pulled_tweets

#get sentiment analysis of tweets using nltk
def get_sa_of_tweet(tweet, sentIntensityAnalyser):
    return sentIntensityAnalyser.polarity_scores(tweet.full_text)['compound']

# create a dataframe of all tweets
def collect_individual_tweets(hashtag, n=1000):
    pulled_tweets = get_tweets(hashtag, n)
    sia = SentimentIntensityAnalyzer()
    data = [(datetime(*t.created_at.timetuple()[:3]), get_sa_of_tweet(t, sia)) for t in pulled_tweets]
    dates = [x[0] for x in data if x[1] != 0.0]
    sa = [x[1] for x in data if x[1] != 0.0]
    return pd.DataFrame({'Date': np.array(dates),
                         'SA': np.array(sa)})

# create a dataframe of mean sentiment analysis per dat
def collect_mean_tweets(hashtag, n = 1000):
    individual_tweets = collect_individual_tweets(hashtag, n)
    tweets = individual_tweets.groupby('Date', as_index=False)['SA'].mean()
    return tweets

