from datetime import date
import Financial_Data
import Sentiment_Analysis
import matplotlib.pyplot as plt
from Mongo_Server_Setup import client
from statsmodels.tsa.stattools import grangercausalitytests

# create dataframe with all relevant date
def get_df(hashtag, company_abbrev, start, end):
    financial_df = Financial_Data.retrieve_data(company_abbrev, start, end)
    sa_df = Sentiment_Analysis.collect_mean_tweets(hashtag)
    df = financial_df.merge(sa_df[['Date', 'SA']], on='Date')
    return df

# insert data into mongo database
def insert_data(data, name):
    df = client['Project']
    collection = df[name]
    collection.insert_many(data)

# save a plot of the sentiment analysis vs stock prices
def plot_correlation(data, name, dir):
    plt.plot(data['Date'], data['Adj Close'] / max(data['Adj Close']), label='Stock Price Noramlized')
    plt.plot(data['Date'], data['SA'], label = 'Average Sentiment')
    plt.legend(loc="lower left")
    plt.title('{} Stock Price vs Sentiment'.format(name))
    plt.savefig(dir)

# perform a granger causality test on sentiment analysis and stock prices
def test_correlation(df, col1='Adj Close', col2='SA'):
    test = grangercausalitytests(df[[col1, col2]], maxlag=1)
    return test

